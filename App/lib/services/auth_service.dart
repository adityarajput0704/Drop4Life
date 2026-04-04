import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../config/config.dart';
import 'api_client.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Dio _dio = ApiClient().dio;

  /// Login with Firebase email/password
  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Register with Firebase + create donor profile on backend
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
    required String city,
    required int age,
    required String bloodGroup,
  }) async {
    // Step 1 — create Firebase account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Step 2 — register donor profile on backend
    // Token is auto-attached by ApiClient interceptor
    try {
      await _dio.post('/donors/register', data: {
        'full_name': name,
        'city': city,
        'age': age,
        'blood_group': bloodGroup,
        'phone': '',          // optional — can add field later
      });
    } catch (e) {
      // If backend registration fails, delete Firebase account
      // so user can retry cleanly
      await credential.user?.delete();
      rethrow;
    }

    return credential;
  }

  /// Get current user profile from backend
  Future<Map<String, dynamic>> getMyProfile() async {
    final res = await _dio.get('/users/me');
    return res.data as Map<String, dynamic>;
  }

  /// Sign out
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Auth state stream — emits user on login/logout
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}