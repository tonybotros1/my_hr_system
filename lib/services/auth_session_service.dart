import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth/login_response_model.dart';

class AuthSessionService extends GetxService {
  AuthSessionService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _userIdKey = 'userId';
  static const _companyIdKey = 'companyId';
  static const _userEmailKey = 'userEmail';
  static const _rolesKey = 'roles';
  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';
  static const _sessionIdKey = 'sessionId';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveLogin(LoginResponseModel login) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_userIdKey, login.userId),
      preferences.setString(_companyIdKey, login.companyId),
      preferences.setString(_userEmailKey, login.email),
      preferences.setStringList(_rolesKey, login.roles),
      preferences.setString(_accessTokenKey, login.accessToken),
      preferences.setString(_sessionIdKey, login.sessionId),
      _secureStorage.write(key: _refreshTokenKey, value: login.refreshToken),
    ]);
  }

  Future<String?> readUserId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_userIdKey);
  }

  Future<String?> readAccessToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> updateAccessToken({
    required String accessToken,
    String? sessionId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accessTokenKey, accessToken);
    if (sessionId != null && sessionId.isNotEmpty) {
      await preferences.setString(_sessionIdKey, sessionId);
    }
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.remove(_userIdKey),
      preferences.remove(_companyIdKey),
      preferences.remove(_userEmailKey),
      preferences.remove(_rolesKey),
      preferences.remove(_accessTokenKey),
      preferences.remove(_sessionIdKey),
      _secureStorage.delete(key: _refreshTokenKey),
    ]);
  }
}
