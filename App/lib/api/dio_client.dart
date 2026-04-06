import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';

class DioClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))..interceptors.addAll([
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        error: true,
        logPrint: (obj) => print('🌐 DIO: $obj'),
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!AppConfig.useMockData) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final token = await user.getIdToken();
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Handle 401 Unauthorized
            // Normally, trigger a logout logic here or throw a specific exception
          }
          return handler.next(e);
        },
      ),
    ]);

  static Dio get instance => _dio;
}
