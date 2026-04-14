import 'package:flutter/material.dart';
import '../api/donor_service.dart';
import '../models/donor.dart';
import '../api/location_service.dart';
import 'package:flutter/widgets.dart'; 

class DonorProvider extends ChangeNotifier with WidgetsBindingObserver {

  DonorProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Update location every time donor brings app to foreground
    if (state == AppLifecycleState.resumed) {
      updateLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  final LocationService _locationService = LocationService();

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

      updateLocation();
      
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

  Future<void> updateLocation() async {
    final position = await _locationService.getLocationPermissionAndPosition();
    if (position != null) {
      await _locationService.updateLocationOnBackend(
        position.latitude,
        position.longitude,
      );
    }
  }
}
