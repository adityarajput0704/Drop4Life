import 'package:flutter/material.dart';

import 'dio_client.dart';
import '../models/blood_request.dart';
import '../config/app_config.dart';
import '../mock/mock_data.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class RequestResponse {
  final List<BloodRequest> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  RequestResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory RequestResponse.fromJson(Map<String, dynamic> json) {
    return RequestResponse(
      items:
          (json['items'] as List).map((i) => BloodRequest.fromJson(i)).toList(),
      total: json['total'],
      page: json['page'],
      pageSize: json['page_size'],
      totalPages: json['total_pages'],
      hasNext: json['has_next'],
      hasPrevious: json['has_previous'],
    );
  }
}

class RequestService {
  Future<RequestResponse> getBloodRequests(
    int page,
    Map<String, dynamic> filters,
  ) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      List<BloodRequest> filtered = MockData.activeRequests;
      if (filters.containsKey('urgency') && filters['urgency'] != 'ALL') {
        filtered =
            filtered.where((r) => r.urgency == filters['urgency']).toList();
      }
      return RequestResponse(
        items: filtered,
        total: filtered.length,
        page: page,
        pageSize: 10,
        totalPages: 1,
        hasNext: false,
        hasPrevious: false,
      );
    }

    final queryParams = <String, dynamic>{'page': page};
    queryParams['status'] = 'open';

    if (filters.containsKey('urgency') && filters['urgency'] != 'ALL') {
      queryParams['urgency'] = (filters['urgency'] as String).toLowerCase();
    }

    // Search by city
    if (filters.containsKey('city') && (filters['city'] as String).isNotEmpty) {
      queryParams['city'] = filters['city'];
    }

    final response = await DioClient.instance.get(
      '/blood-requests/',
      queryParameters: queryParams,
    );
    return RequestResponse.fromJson(response.data);
  }

  Future<List<BloodRequest>> getMatchingRequests() async {
  if (AppConfig.useMockData) {
    await Future.delayed(const Duration(seconds: 1));
    return MockData.activeRequests.take(4).toList();
  }

  try {
    // Get current position for location-based filtering
    Map<String, dynamic> queryParams = {};

    try {
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,   // low accuracy = faster
          timeLimit: Duration(seconds: 5),
        ),
      );
      queryParams['radius_km'] = 50;
      // Backend uses donor's stored lat/lng — no need to send coordinates
      // radius_km param activates the location filter on backend
    } catch (e) {
        debugPrint('Location unavailable for matching — showing all compatible');
      // No radius_km = backend returns all compatible regardless of distance
    }

    final response = await DioClient.instance.get(
      '/blood-requests/matching',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return (response.data['items'] as List)
        .map((i) => BloodRequest.fromJson(i))
        .toList();
  } on DioException catch (e) {
    if (e.response?.statusCode == 403) return [];
    rethrow;
  }
}

  Future<void> acceptRequest(String requestId) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    await DioClient.instance.post('/blood-requests/$requestId/accept');
  }

  Future<void> cancelAcceptance(String requestId) async {
    await DioClient.instance
        .post('/blood-requests/$requestId/cancel-acceptance');
  }

  Future<RequestResponse> getMyHistory(int page) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return RequestResponse(
        items: MockData.requestHistory,
        total: MockData.requestHistory.length,
        page: page,
        pageSize: 10,
        totalPages: 1,
        hasNext: false,
        hasPrevious: false,
      );
    }
    // Fetches requests where the current donor is the assigned donor
    final response = await DioClient.instance.get(
      '/blood-requests/my-donations', // ← we confirm this after your grep
      queryParameters: {'page': page},
    );
    return RequestResponse.fromJson(response.data);
  }
}
