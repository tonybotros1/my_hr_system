class LoginResponseModel {
  const LoginResponseModel({
    required this.userId,
    required this.email,
    required this.companyId,
    required this.roles,
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
    required this.sessionId,
    required this.tokenType,
  });

  final String userId;
  final String email;
  final String companyId;
  final List<String> roles;
  final String accessToken;
  final int expiresIn;
  final String refreshToken;
  final String sessionId;
  final String tokenType;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['role'];
    final roles = rawRoles is List
        ? rawRoles.map((role) => role.toString()).toList(growable: false)
        : rawRoles == null
        ? const <String>[]
        : <String>[rawRoles.toString()];

    return LoginResponseModel(
      userId: _requiredString(json, 'user_id'),
      email: _requiredString(json, 'email'),
      companyId: _requiredString(json, 'company_id'),
      roles: roles,
      accessToken: _requiredString(json, 'access_token'),
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      refreshToken: _requiredString(json, 'refresh_token'),
      sessionId: json['session_id']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key]?.toString() ?? '';
    if (value.isEmpty) {
      throw FormatException('Missing required login response field: $key');
    }
    return value;
  }
}
