import 'package:flutter/material.dart';
import '../api/request_service.dart';
import '../models/blood_request.dart';

class RequestProvider extends ChangeNotifier {
  final RequestService _requestService = RequestService();
  
  List<BloodRequest> _requests = [];
  List<BloodRequest> _urgentRequests = [];
  List<BloodRequest> _history = [];
  
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  int _currentPage = 1;
  bool _hasNextPage = true;
  String _currentFilter = 'ALL';

  List<BloodRequest> get requests => _requests;
  List<BloodRequest> get urgentRequests => _urgentRequests;
  List<BloodRequest> get history => _history;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasNextPage => _hasNextPage;
  String get currentFilter => _currentFilter;

  Future<void> fetchRequests({bool refresh = false, String filter = 'ALL'}) async {
    if (refresh) {
      _currentPage = 1;
      _hasNextPage = true;
      _requests.clear();
      _currentFilter = filter;
      _isLoading = true;
      _error = null;
      notifyListeners();
    } else {
      if (!_hasNextPage || _isLoadingMore) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      final filters = <String, dynamic>{};
      if (_currentFilter != 'ALL') {
        filters['urgency'] = _currentFilter;
      }
      
      final response = await _requestService.getBloodRequests(_currentPage, filters);
      
      if (refresh) {
        _requests = response.items;
      } else {
        _requests.addAll(response.items);
      }
      
      _hasNextPage = response.hasNext;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (refresh) {
        _isLoading = false;
      } else {
        _isLoadingMore = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchUrgentRequests() async {
    try {
      _urgentRequests = await _requestService.getMatchingRequests();
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> fetchHistory() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _requestService.getMyHistory(1);
      _history = response.items;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptRequest(String requestId) async {
    try {
      await _requestService.acceptRequest(requestId);
      // Remove from list if accepted, or just fetch again
      _requests.removeWhere((r) => r.id == requestId);
      _urgentRequests.removeWhere((r) => r.id == requestId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
