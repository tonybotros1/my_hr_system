import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_session_service.dart';

class SessionExpiredException implements Exception {
  const SessionExpiredException();
}

class ApiRequestException implements Exception {
  const ApiRequestException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthenticatedApiService extends GetxService {
  AuthenticatedApiService({
    http.Client? httpClient,
    AuthSessionService? session,
  }) : _httpClient = httpClient ?? http.Client(),
       _sessionOverride = session;

  final http.Client _httpClient;
  final AuthSessionService? _sessionOverride;
  Future<bool>? _refreshFuture;

  AuthSessionService get _session =>
      _sessionOverride ?? Get.find<AuthSessionService>();

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _authorizedRequest('GET', path);
    return _validatedBody(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _authorizedRequest('POST', path, body: body);
    return _validatedBody(response, allowNullSuccess: true);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _authorizedRequest('PATCH', path, body: body);
    return _validatedBody(response, allowNullSuccess: true);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final response = await _authorizedRequest('DELETE', path);
    return _validatedBody(response, allowNullSuccess: true);
  }

  Future<Map<String, dynamic>> postMultipartBytes(
    String path, {
    required String fieldName,
    required Map<String, List<int>> files,
  }) async {
    final response = await _authorizedMultipartRequest(
      path,
      fieldName: fieldName,
      files: files,
    );
    return _validatedBody(response, allowNullSuccess: true);
  }

  Future<Map<String, dynamic>> multipartJson(
    String method,
    String path, {
    required Map<String, String> fields,
    String? fileField,
    List<int>? fileBytes,
    String? fileName,
    Map<String, List<int>> files = const {},
  }) async {
    final response = await _authorizedFormRequest(
      method,
      path,
      fields: fields,
      fileField: fileField,
      fileBytes: fileBytes,
      fileName: fileName,
      files: files,
    );
    return _validatedBody(response, allowNullSuccess: true);
  }

  Map<String, dynamic> _validatedBody(
    http.Response response, {
    bool allowNullSuccess = false,
  }) {
    final succeeded = response.statusCode >= 200 && response.statusCode < 300;
    if (succeeded &&
        allowNullSuccess &&
        response.body.trim().toLowerCase() == 'null') {
      return <String, dynamic>{};
    }
    final body = _decodeObject(response.body);
    if (!succeeded) {
      throw ApiRequestException(
        _errorMessage(body),
        statusCode: response.statusCode,
      );
    }
    return body;
  }

  Future<void> logout() async {
    final refreshToken = (await _session.readRefreshToken())?.trim() ?? '';
    try {
      if (refreshToken.isNotEmpty) {
        await _httpClient
            .post(
              AppConfig.endpoint('/auth/logout'),
              headers: const {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json',
              },
              body: {'refresh_token': refreshToken},
            )
            .timeout(AppConfig.requestTimeout);
      }
    } catch (_) {
      // Local credentials must still be removed if the server is unavailable.
    } finally {
      await _session.clear();
    }
  }

  Future<http.Response> _authorizedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      var accessToken = (await _session.readAccessToken())?.trim() ?? '';
      if (accessToken.isEmpty) throw const SessionExpiredException();

      var response = await _request(method, path, accessToken, body: body);
      if (response.statusCode != 401) return response;

      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        await _session.clear();
        throw const SessionExpiredException();
      }

      accessToken = (await _session.readAccessToken())?.trim() ?? '';
      if (accessToken.isEmpty) throw const SessionExpiredException();
      response = await _request(method, path, accessToken, body: body);
      if (response.statusCode == 401) {
        await _session.clear();
        throw const SessionExpiredException();
      }
      return response;
    } on SessionExpiredException {
      rethrow;
    } on ApiRequestException {
      rethrow;
    } on TimeoutException {
      throw const ApiRequestException('The server took too long to respond.');
    } catch (_) {
      throw const ApiRequestException(
        'We could not reach the server. Check your connection and try again.',
      );
    }
  }

  Future<http.Response> _request(
    String method,
    String path,
    String accessToken, {
    Map<String, dynamic>? body,
  }) {
    final request = http.Request(method, AppConfig.endpoint(path));
    request.headers.addAll({
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    });
    if (body != null) request.body = jsonEncode(body);
    return _httpClient
        .send(request)
        .timeout(AppConfig.requestTimeout)
        .then(http.Response.fromStream);
  }

  Future<http.Response> _authorizedMultipartRequest(
    String path, {
    required String fieldName,
    required Map<String, List<int>> files,
  }) async {
    try {
      var accessToken = (await _session.readAccessToken())?.trim() ?? '';
      if (accessToken.isEmpty) throw const SessionExpiredException();

      var response = await _multipartRequest(
        path,
        accessToken,
        fieldName: fieldName,
        files: files,
      );
      if (response.statusCode != 401) return response;

      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        await _session.clear();
        throw const SessionExpiredException();
      }

      accessToken = (await _session.readAccessToken())?.trim() ?? '';
      if (accessToken.isEmpty) throw const SessionExpiredException();
      response = await _multipartRequest(
        path,
        accessToken,
        fieldName: fieldName,
        files: files,
      );
      if (response.statusCode == 401) {
        await _session.clear();
        throw const SessionExpiredException();
      }
      return response;
    } on SessionExpiredException {
      rethrow;
    } on ApiRequestException {
      rethrow;
    } on TimeoutException {
      throw const ApiRequestException('The server took too long to respond.');
    } catch (_) {
      throw const ApiRequestException(
        'We could not reach the server. Check your connection and try again.',
      );
    }
  }

  Future<http.Response> _authorizedFormRequest(
    String method,
    String path, {
    required Map<String, String> fields,
    String? fileField,
    List<int>? fileBytes,
    String? fileName,
    Map<String, List<int>> files = const {},
  }) async {
    try {
      var accessToken = (await _session.readAccessToken())?.trim() ?? '';
      if (accessToken.isEmpty) throw const SessionExpiredException();

      var response = await _formRequest(
        method,
        path,
        accessToken,
        fields: fields,
        fileField: fileField,
        fileBytes: fileBytes,
        fileName: fileName,
        files: files,
      );
      if (response.statusCode != 401) return response;

      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        await _session.clear();
        throw const SessionExpiredException();
      }

      accessToken = (await _session.readAccessToken())?.trim() ?? '';
      if (accessToken.isEmpty) throw const SessionExpiredException();
      response = await _formRequest(
        method,
        path,
        accessToken,
        fields: fields,
        fileField: fileField,
        fileBytes: fileBytes,
        fileName: fileName,
        files: files,
      );
      if (response.statusCode == 401) {
        await _session.clear();
        throw const SessionExpiredException();
      }
      return response;
    } on SessionExpiredException {
      rethrow;
    } on ApiRequestException {
      rethrow;
    } on TimeoutException {
      throw const ApiRequestException('The server took too long to respond.');
    } catch (_) {
      throw const ApiRequestException(
        'We could not reach the server. Check your connection and try again.',
      );
    }
  }

  Future<http.Response> _formRequest(
    String method,
    String path,
    String accessToken, {
    required Map<String, String> fields,
    String? fileField,
    List<int>? fileBytes,
    String? fileName,
    Map<String, List<int>> files = const {},
  }) async {
    final request = http.MultipartRequest(method, AppConfig.endpoint(path));
    request.headers.addAll({
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    });
    request.fields.addAll(fields);
    if (fileField != null && fileBytes != null && fileBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName ?? 'upload.bin',
        ),
      );
    }
    if (fileField != null) {
      for (final entry in files.entries) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            entry.value,
            filename: entry.key,
          ),
        );
      }
    }
    return _httpClient
        .send(request)
        .timeout(AppConfig.requestTimeout)
        .then(http.Response.fromStream);
  }

  Future<http.Response> _multipartRequest(
    String path,
    String accessToken, {
    required String fieldName,
    required Map<String, List<int>> files,
  }) async {
    final request = http.MultipartRequest('POST', AppConfig.endpoint(path));
    request.headers.addAll({
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    });
    for (final entry in files.entries) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          entry.value,
          filename: entry.key,
        ),
      );
    }
    return _httpClient
        .send(request)
        .timeout(AppConfig.requestTimeout)
        .then(http.Response.fromStream);
  }

  Future<bool> _refreshAccessToken() async {
    final activeRefresh = _refreshFuture;
    if (activeRefresh != null) return activeRefresh;

    final refresh = _performRefresh();
    _refreshFuture = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshFuture, refresh)) _refreshFuture = null;
    }
  }

  Future<bool> _performRefresh() async {
    try {
      final refreshToken = (await _session.readRefreshToken())?.trim() ?? '';
      if (refreshToken.isEmpty) return false;

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
      if (response.statusCode != 200) return false;

      final body = _decodeObject(response.body);
      final accessToken = body['access_token']?.toString().trim() ?? '';
      if (accessToken.isEmpty) return false;
      await _session.updateAccessToken(
        accessToken: accessToken,
        sessionId: body['session_id']?.toString(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _decodeObject(String source) {
    if (source.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiRequestException('The server returned invalid data.');
    }
    return decoded;
  }

  String _errorMessage(Map<String, dynamic> body) {
    final detail = body['detail'] ?? body['message'];
    if (detail != null && detail.toString().trim().isNotEmpty) {
      return detail.toString();
    }
    return 'The request could not be completed.';
  }
}
