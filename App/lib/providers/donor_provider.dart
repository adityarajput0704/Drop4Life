import 'package:flutter/material.dart';
import '../api/donor_service.dart';
import '../models/donor.dart';

class DonorProvider extends ChangeNotifier {
  final DonorService _donorService = DonorService();
  Donor? _donor;
  bool _isLoading = false;
  String? _error;

  Donor? get donor => _donor;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _donor = await _donorService.getMyProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _donor = await _donorService.updateMyProfile(data);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearProfile() {
    _donor = null;
    notifyListeners();
  }
}
