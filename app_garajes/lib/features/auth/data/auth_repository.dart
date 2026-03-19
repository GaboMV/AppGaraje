import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final Dio _dio = DioClient.instance;

  Future<UserModel> register({
    required String nombreCompleto,
    required String correo,
    required String password,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.register, data: {
        'nombre_completo': nombreCompleto,
        'correo': correo,
        'password': password,
      });
      final data = response.data;
      final token = data['token'];
      final userJson = Map<String, dynamic>.from(data['user']);
      userJson['token'] = token;

      final user = UserModel.fromJson(userJson);
      await SecureStorageService.saveToken(token);
      await SecureStorageService.saveUserInfo(
        id: user.id,
        name: user.nombreCompleto,
        email: user.correo,
        kycApproved: user.estaVerificado,
        modoActual: user.modoActual,
        dniFotoUrl: user.dniFotoUrl,
        selfieUrl: user.selfieUrl,
      );
      return user;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> login({
    required String correo,
    required String password,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.login, data: {
        'correo': correo,
        'password': password,
      });
      final data = response.data;
      final token = data['token'];
      final userJson = Map<String, dynamic>.from(data['user']);
      print('[AuthRepo] DEBUG: User JSON from server: $userJson');
      userJson['token'] = token;

      final user = UserModel.fromJson(userJson);
      print('[AuthRepo] DEBUG: Mapped mode: ${user.modoActual}');
      await SecureStorageService.saveToken(token);
      await SecureStorageService.saveUserInfo(
        id: user.id,
        name: user.nombreCompleto,
        email: user.correo,
        kycApproved: user.estaVerificado,
        modoActual: user.modoActual,
        dniFotoUrl: user.dniFotoUrl,
        selfieUrl: user.selfieUrl,
      );
      return user;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> loginWithGoogle({String? idToken, String? accessToken}) async {
    try {
      final response = await _dio.post(ApiConstants.googleAuth, data: {
        if (idToken != null) 'idToken': idToken,
        if (accessToken != null) 'accessToken': accessToken,
      });
      final data = response.data;
      final token = data['token'];
      final userJson = Map<String, dynamic>.from(data['user']);
      userJson['token'] = token;

      final user = UserModel.fromJson(userJson);
      await SecureStorageService.saveToken(token);
      await SecureStorageService.saveUserInfo(
        id: user.id,
        name: user.nombreCompleto,
        email: user.correo,
        kycApproved: user.estaVerificado,
        modoActual: user.modoActual,
        dniFotoUrl: user.dniFotoUrl,
        selfieUrl: user.selfieUrl,
      );
      return user;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.userProfile);
      final data = response.data;
      final userJson = Map<String, dynamic>.from(data['user']);
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    await SecureStorageService.clearAll();
    DioClient.reset();
  }
}
