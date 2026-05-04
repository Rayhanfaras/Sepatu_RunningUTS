import 'package:appsmarketplace/core/constants/api_constants.dart';
import 'package:appsmarketplace/core/features/auth/domain/repositories/auth_repository.dart.dart';
import 'package:appsmarketplace/core/services/dio_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<String> verifyFirebaseToken(String firebaseToken) async {
    final response = await DioClient.instance.post(
      ApiConstants.verifyToken,
      data: {'firebase_token': firebaseToken},
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return data['access_token'] as String;
  }
}
