import 'dart:async';
import '../config/config.dart';
import '../models/donor.dart';
import '../mock/mock_donor.dart';

class DonorService {
  Future<Donor> getDonorProfile() async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockNetworkDelay);
      return mockDonor;
    }
    throw UnimplementedError('API getDonorProfile not implemented');
  }

  Future<Donor> updateDonorProfile(Donor updatedProfile) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockNetworkDelay);
      return updatedProfile; // Return the updated mock directly
    }
    throw UnimplementedError('API updateDonorProfile not implemented');
  }
}
