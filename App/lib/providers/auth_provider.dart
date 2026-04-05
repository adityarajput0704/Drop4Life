import 'package:flutter/material.dart';
import '../api/auth_service.dart';
import '../config/app_config.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isAuthenticated {
    if (AppConfig.useMockData) return true;
    return _authService.getCurrentFirebaseUser() != null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    if (AppConfig.useMockData) return true;
    
    try {
      _setLoading(true);
      _setError(null);
      await _authService.loginWithEmail(email, password);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password) async {
    if (AppConfig.useMockData) return true;

    try {
      _setLoading(true);
      _setError(null);
      await _authService.registerWithEmail(email, password);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithGoogle() async {
    if (AppConfig.useMockData) return true;

    try {
      _setLoading(true);
      _setError(null);
      await _authService.loginWithGoogle();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    if (!AppConfig.useMockData) {
      await _authService.logout();
    }
    notifyListeners();
  }
}
