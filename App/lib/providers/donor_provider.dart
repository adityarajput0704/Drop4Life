import 'package:flutter/material.dart';
import '../services/donor_service.dart';
import '../models/donor.dart';

class DonorProvider extends ChangeNotifier {
  final DonorService _donorService = DonorService();
  Donor? _donor;
  bool _isLoading = false;
  String? _error;

  Donor? get donor => _donor;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDonorProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _donor = await _donorService.getDonorProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDonorProfile(Donor updated) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _donor = await _donorService.updateDonorProfile(updated);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
