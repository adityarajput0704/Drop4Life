import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // ── Request interceptor — attach Firebase token ──────────────────────
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final token = await user.getIdToken();
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            // If token fetch fails, proceed without auth header
            // Backend will return 401 and we handle it in onError
          }
          return handler.next(options);
        },

        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            // Token expired or invalid — sign out
            FirebaseAuth.instance.signOut();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}