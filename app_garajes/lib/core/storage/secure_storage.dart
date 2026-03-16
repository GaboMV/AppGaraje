import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _kycApproved = 'kyc_approved';

  // Token
  static Future<void> saveToken(String token) async =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() async =>
      _storage.read(key: _tokenKey);

  static Future<void> deleteToken() async =>
      _storage.delete(key: _tokenKey);

  static Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  // User info
  static Future<void> saveUserInfo({
    required String id,
    required String name,
    required String email,
    bool kycApproved = false,
  }) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: id),
      _storage.write(key: _userNameKey, value: name),
      _storage.write(key: _userEmailKey, value: email),
      _storage.write(key: _kycApproved, value: kycApproved.toString()),
    ]);
  }

  static Future<Map<String, String?>> getUserInfo() async {
    final values = await Future.wait([
      _storage.read(key: _userIdKey),
      _storage.read(key: _userNameKey),
      _storage.read(key: _userEmailKey),
      _storage.read(key: _kycApproved),
    ]);
    return {
      'id': values[0],
      'name': values[1],
      'email': values[2],
      'kyc_approved': values[3],
    };
  }

  static Future<void> clearAll() async => _storage.deleteAll();
}
