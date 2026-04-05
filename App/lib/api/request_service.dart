import 'dio_client.dart';
import '../models/blood_request.dart';
import '../config/app_config.dart';
import '../mock/mock_data.dart';

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
      items: (json['items'] as List).map((i) => BloodRequest.fromJson(i)).toList(),
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
  Future<RequestResponse> getBloodRequests(int page, Map<String, dynamic> filters) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      
      List<BloodRequest> filtered = MockData.activeRequests;
      if (filters.containsKey('urgency') && filters['urgency'] != 'ALL') {
             filtered = filtered.where((r) => r.urgency == filters['urgency']).toList();
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
    
    final response = await DioClient.instance.get('/blood-requests/', queryParameters: {
      'page': page,
      ...filters,
    });
    return RequestResponse.fromJson(response.data);
  }

  Future<List<BloodRequest>> getMatchingRequests() async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return MockData.activeRequests.take(4).toList(); // Return a few mock active requests
    }

    final response = await DioClient.instance.get('/blood-requests/matching');
    return (response.data['items'] as List).map((i) => BloodRequest.fromJson(i)).toList();
  }

  Future<void> acceptRequest(String requestId) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    await DioClient.instance.post('/blood-requests/$requestId/accept');
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

    final response = await DioClient.instance.get('/blood-requests/', queryParameters: {
      'page': page,
      'donor_history': true,
    });
    return RequestResponse.fromJson(response.data);
  }
}
