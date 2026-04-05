import 'dio_client.dart';
import '../models/donor.dart';
import '../config/app_config.dart';
import '../mock/mock_data.dart';

class DonorService {
  Future<Donor> getMyProfile() async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return MockData.currentDonor;
    }
    
    final response = await DioClient.instance.get('/donors/me');
    return Donor.fromJson(response.data);
  }

  Future<Donor> updateMyProfile(Map<String, dynamic> data) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      // In mock mode, simply return the updated donor. Real updates handled by Provider
      return MockData.currentDonor.copyWith(
        fullName: data['full_name'],
        city: data['city'],
        age: data['age'],
        isAvailable: data['is_available'],
      );
    }

    final response = await DioClient.instance.patch('/donors/me', data: data);
    return Donor.fromJson(response.data);
  }

  Future<Donor> registerAsDonor(Map<String, dynamic> data) async {
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return MockData.currentDonor;
    }

    final response = await DioClient.instance.post('/donors/register', data: data);
    return Donor.fromJson(response.data);
  }
}
