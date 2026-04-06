// import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../models/user.dart';

class UserService {
  Future<User> getMyUser() async {
    final response = await DioClient.instance.get('/users/me');
    return User.fromJson(response.data);
  }
}