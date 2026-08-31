import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../models/auth/login_response_model.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_session_service.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';

class LoginScreenController extends GetxController {
  LoginScreenController({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  final obscurePassword = true.obs;
  final isSigningIn = false.obs;
  final errorMessage = RxnString();

  AuthSessionService get _session => Get.find<AuthSessionService>();

  void togglePasswordVisibility() {
    obscurePassword.toggle();
  }

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email address';
    if (!GetUtils.isEmail(email)) return 'Please enter a valid email address';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    return null;
  }

  Future<void> submit() async {
    if (isSigningIn.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    errorMessage.value = null;
    isSigningIn.value = true;

    try {
      final response = await _httpClient
          .post(
            AppConfig.endpoint('/auth/login'),
            headers: const {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {
              'email': emailController.text.trim().toLowerCase(),
              'password': passwordController.text,
            },
          )
          .timeout(AppConfig.requestTimeout);

      final body = _decodeResponse(response.body);
      if (response.statusCode == 200) {
        final login = LoginResponseModel.fromJson(body);
        await _session.saveLogin(login);
        Get.offAllNamed(AppRoutes.home);
        return;
      }

      errorMessage.value = _errorFor(response.statusCode, body);
    } on FormatException {
      errorMessage.value = 'The server returned an invalid response.';
    } catch (_) {
      errorMessage.value =
          'We could not reach the server. Check your connection and try again.';
    } finally {
      isSigningIn.value = false;
    }
  }

  void showForgotPasswordHelp() {
    unawaited(
      showAppAlertDialog(
        title: 'Password help',
        message:
            'Please contact your organization administrator to reset your password.',
      ),
    );
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }
    return decoded;
  }

  String _errorFor(int statusCode, Map<String, dynamic> body) {
    final detail = body['detail']?.toString().trim();
    if (detail != null && detail.isNotEmpty) return detail;
    if (statusCode >= 500) return 'The server is temporarily unavailable.';
    return 'Sign in failed. Please try again.';
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    _httpClient.close();
    super.onClose();
  }
}
