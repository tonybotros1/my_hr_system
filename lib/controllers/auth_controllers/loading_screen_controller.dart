import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_session_service.dart';

enum _ValidationResult { valid, invalid, unauthorized, unavailable }

enum _RefreshResult { success, invalid, unavailable }

class LoadingScreenController extends GetxController {
  LoadingScreenController({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final needRefresh = false.obs;
  final isChecking = true.obs;

  AuthSessionService get _session => Get.find<AuthSessionService>();

  @override
  void onInit() {
    super.onInit();
    unawaited(checkLogStatus());
  }

  Future<void> checkLogStatus() async {
    if (isClosed) return;
    needRefresh.value = false;
    isChecking.value = true;

    try {
      final userId = (await _session.readUserId())?.trim() ?? '';
      if (userId.isEmpty) {
        await _openLogin(clearSession: true);
        return;
      }

      var validation = await _isUserValid(userId);
      if (validation == _ValidationResult.unauthorized) {
        final refreshResult = await _refreshAccessToken();
        if (refreshResult == _RefreshResult.success) {
          validation = await _isUserValid(userId);
        } else if (refreshResult == _RefreshResult.invalid) {
          await _openLogin(clearSession: true);
          return;
        } else {
          _showRetry();
          return;
        }
      }

      switch (validation) {
        case _ValidationResult.valid:
          Get.offAllNamed(AppRoutes.home);
          return;
        case _ValidationResult.invalid:
        case _ValidationResult.unauthorized:
          await _openLogin(clearSession: true);
          return;
        case _ValidationResult.unavailable:
          _showRetry();
          return;
      }
    } catch (_) {
      _showRetry();
    } finally {
      if (!isClosed) isChecking.value = false;
    }
  }

  Future<_ValidationResult> _isUserValid(String userId) async {
    try {
      final accessToken = (await _session.readAccessToken())?.trim() ?? '';
      if (accessToken.isEmpty) return _ValidationResult.unauthorized;

      final response = await _httpClient
          .get(
            AppConfig.endpoint('/auth/is_user_valid/$userId'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Accept': 'application/json',
            },
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic> && decoded['valid'] == true
            ? _ValidationResult.valid
            : _ValidationResult.invalid;
      }
      if (response.statusCode == 401) return _ValidationResult.unauthorized;
      if (response.statusCode >= 500) return _ValidationResult.unavailable;
      return _ValidationResult.invalid;
    } catch (_) {
      return _ValidationResult.unavailable;
    }
  }

  Future<_RefreshResult> _refreshAccessToken() async {
    try {
      final refreshToken = (await _session.readRefreshToken())?.trim() ?? '';
      if (refreshToken.isEmpty) return _RefreshResult.invalid;

      final response = await _httpClient
          .post(
            AppConfig.endpoint('/auth/refresh_token'),
            headers: const {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {'token': refreshToken},
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) return _RefreshResult.invalid;
        final accessToken = decoded['access_token']?.toString() ?? '';
        if (accessToken.isEmpty) return _RefreshResult.invalid;
        await _session.updateAccessToken(
          accessToken: accessToken,
          sessionId: decoded['session_id']?.toString(),
        );
        return _RefreshResult.success;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return _RefreshResult.invalid;
      }
      return _RefreshResult.unavailable;
    } catch (_) {
      return _RefreshResult.unavailable;
    }
  }

  Future<void> _openLogin({required bool clearSession}) async {
    if (clearSession) await _session.clear();
    if (!isClosed) Get.offAllNamed(AppRoutes.login);
  }

  void _showRetry() {
    if (isClosed) return;
    needRefresh.value = true;
    isChecking.value = false;
  }

  @override
  void onClose() {
    _httpClient.close();
    super.onClose();
  }
}
