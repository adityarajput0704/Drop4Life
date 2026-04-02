import 'package:flutter/material.dart';
import '../services/request_service.dart';
import '../models/blood_request.dart';
import '../models/donation_history.dart';

class RequestProvider extends ChangeNotifier {
  final RequestService _requestService = RequestService();
  
  List<BloodRequest> _requests = [];
  List<DonationHistory> _history = [];
  
  bool _isLoadingRequests = false;
  bool _isLoadingHistory = false;
  String? _error;

  List<BloodRequest> get requests => _requests;
  List<DonationHistory> get history => _history;
  
  bool get isLoadingRequests => _isLoadingRequests;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;

  Future<void> fetchBloodRequests() async {
    _isLoadingRequests = true;
    _error = null;
    // Don't clear old data to avoid flicker, just set loading true
    notifyListeners();

    try {
      _requests = await _requestService.getBloodRequests();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    _isLoadingHistory = true;
    _error = null;
    notifyListeners();

    try {
      _history = await _requestService.getHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }
  
  Future<bool> acceptRequest(String id) async {
    _isLoadingRequests = true;
    notifyListeners();
    
    try {
      final success = await _requestService.acceptRequest(id);
      if (success) {
        // Optimistically remove it from requests (or update its status)
        _requests.removeWhere((req) => req.id == id);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoadingRequests = false;
      notifyListeners();
    }
  }
}
