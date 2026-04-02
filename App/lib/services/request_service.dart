import 'dart:async';
import '../config/config.dart';
import '../models/blood_request.dart';
import '../models/donation_history.dart';
import '../mock/mock_requests.dart';
import '../mock/mock_history.dart';

class RequestService {
  Future<List<BloodRequest>> getBloodRequests() async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockNetworkDelay);
      return mockRequests;
    }
    throw UnimplementedError('API getBloodRequests not implemented');
  }

  Future<BloodRequest> getRequestDetail(String id) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockNetworkDelay);
      return mockRequests.firstWhere((req) => req.id == id, orElse: () => mockRequests.first);
    }
    throw UnimplementedError('API getRequestDetail not implemented');
  }

  Future<bool> acceptRequest(String id) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockNetworkDelay);
      return true;
    }
    throw UnimplementedError('API acceptRequest not implemented');
  }

  Future<List<DonationHistory>> getHistory() async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockNetworkDelay);
      return mockHistory;
    }
    throw UnimplementedError('API getHistory not implemented');
  }
}
