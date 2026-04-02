import 'dart:async';
import '../config/config.dart';

class AuthService {
  // Simulates an API call delay
  Future<void> _mockDelay() async => Future.delayed(AppConfig.mockNetworkDelay);

  Future<bool> login(String email, String password) async {
    if (AppConfig.useMockData) {
      await _mockDelay();
      // Accepts any input in mock mode
      return true;
    }
    // Real implementation goes here (e.g., Firebase Auth)
    throw UnimplementedError('API auth not implemented');
  }

  Future<bool> register(String name, String email, String password, String city, int age, String bloodGroup) async {
    if (AppConfig.useMockData) {
      await _mockDelay();
      return true;
    }
    // Real implementation goes here
    throw UnimplementedError('API auth not implemented');
  }

  Future<void> logout() async {
    if (AppConfig.useMockData) {
      await _mockDelay();
      return;
    }
    // Real implementation goes here
  }
}
