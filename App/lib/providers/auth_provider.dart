// App/lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  Map<String, dynamic>? _profile;  // from /users/me
  bool _isLoading = true;
  String? _error;

  // ── Getters ──────────────────────────────────────────────────────────────
  bool get isAuthenticated => _firebaseUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get profile => _profile;
  String? get role => _profile?['role'];
  String? get displayName => _profile?['full_name'];

  AuthProvider() {
    // Listen to Firebase auth state changes
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    _error = null;

    if (user == null) {
      _profile = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // User logged in — fetch backend profile
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _authService.getMyProfile();
    } catch (e) {
      _error = 'Failed to load profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
      // _onAuthStateChanged fires automatically — handles profile fetch
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String city,
    required int age,
    required String bloodGroup,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
        city: city,
        age: age,
        bloodGroup: bloodGroup,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    // _onAuthStateChanged fires automatically
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}