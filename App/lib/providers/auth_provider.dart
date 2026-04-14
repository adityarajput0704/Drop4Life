import 'package:flutter/material.dart';
import '../api/auth_service.dart';
import '../api/user_service.dart';
import '../models/user.dart';
import '../api/dio_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _error;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;

  // Role helpers — used by router and screens
  bool get isAuthenticated => _authService.getCurrentFirebaseUser() != null;
  bool get isDonor => _currentUser?.role == 'donor';
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isHospital => _currentUser?.role == 'hospital';

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  /// Called after any successful Firebase login.
  /// Fetches /users/me to get role and profile.
  /// Returns the role string so the router knows where to navigate.
  Future<String?> _fetchUserRole() async {
    try {
      _currentUser = await _userService.getMyUser();
      notifyListeners();

      // Save FCM token to backend — runs silently after every login/session restore
      _saveFcmTokenSilently();

      return _currentUser?.role;
    } catch (e) {
      debugPrint('fetchUserRole error: $e');
      return null;
    }
  }

  Future<void> _saveFcmTokenSilently() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await saveFcmToken(token);
        debugPrint('FCM token saved to backend');
      }
    } catch (e) {
      // Non-critical — never block login flow for this
      debugPrint('FCM token save failed (non-critical): $e');
    }
  }

  /// Returns: 'donor', 'admin', 'hospital', 'unregistered', or null on failure
  Future<String?> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      await _authService.loginWithEmail(email, password);
      return await _fetchUserRole();
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Returns: 'donor', 'admin', 'hospital', 'unregistered', or null on failure
  Future<String?> loginWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);
      await _authService.loginWithGoogle();
      return await _fetchUserRole();
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Register creates Firebase user only — DB record created separately
  Future<bool> register(String email, String password) async {
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

  Future<bool> registerAsDonor({
    required String fullName,
    required String city,
    required int age,
    required String bloodGroup,
    required String phone,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Get email from the Firebase user who just registered
      final firebaseUser = _authService.getCurrentFirebaseUser();
      if (firebaseUser == null) {
        _setError('Session expired. Please try again.');
        return false;
      }

      // Step 1: Register user in our DB — email comes from Firebase, not form
      await DioClient.instance.post('/users/register', data: {
        'full_name': fullName,
        'email': firebaseUser.email ?? '', // ← THIS was missing
        'phone': phone,
        'blood_group': bloodGroup,
      });

      // Step 2: Register as donor
      await DioClient.instance.post('/donors/register', data: {
        'city': city,
        'age': age,
        'blood_group': bloodGroup,
      });

      // Step 3: Fetch role to confirm
      await _fetchUserRole();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// Called on app start — restores session if Firebase user exists
  Future<String?> restoreSession() async {
    if (!isAuthenticated) return null;
    return await _fetchUserRole();
  }
}
