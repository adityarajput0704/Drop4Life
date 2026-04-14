// import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../models/user.dart';
import 'package:flutter/material.dart';

class UserService {
  Future<User> getMyUser() async {
    final response = await DioClient.instance.get('/users/me');
    return User.fromJson(response.data);
  }
}

Future<void> saveFcmToken(String token) async {
  try {
    await DioClient.instance.post(
      '/users/fcm-token',
      data: {'fcm_token': token},
    );
    debugPrint('FCM token saved to backend');
  } catch (e) {
    // Non-critical — don't crash the app if this fails
    debugPrint('Failed to save FCM token: $e');
  }
}
