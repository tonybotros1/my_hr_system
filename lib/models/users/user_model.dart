import '../../utils/app_date_utils.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.userName,
    required this.email,
    required this.status,
    required this.isAdmin,
    required this.roles,
    required this.branches,
    required this.hrScreenAccess,
    required this.expiryDate,
    required this.createdAt,
  });

  final String id;
  final String userName;
  final String email;
  final bool status;
  final bool isAdmin;
  final List<String> roles;
  final List<String> branches;
  final List<String>? hrScreenAccess;
  final DateTime? expiryDate;
  final DateTime? createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? '',
      userName: json['user_name']?.toString().trim() ?? '',
      email: json['email']?.toString().trim() ?? '',
      status: _readBool(json['status'], fallback: true),
      isAdmin: _readBool(json['is_admin']),
      roles: _stringList(json['roles']),
      branches: _stringList(json['branches']),
      hrScreenAccess:
          json.containsKey('hr_screen_access') &&
              json['hr_screen_access'] != null
          ? _stringList(json['hr_screen_access'])
          : null,
      expiryDate: _readDate(json['expiry_date']),
      createdAt: _readDate(json['createdAt']),
    );
  }

  UserModel copyWith({
    String? id,
    String? userName,
    String? email,
    bool? status,
    bool? isAdmin,
    List<String>? roles,
    List<String>? branches,
    List<String>? hrScreenAccess,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      status: status ?? this.status,
      isAdmin: isAdmin ?? this.isAdmin,
      roles: roles ?? this.roles,
      branches: branches ?? this.branches,
      hrScreenAccess: hrScreenAccess ?? this.hrScreenAccess,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.map((item) => item.toString()).toList(growable: false);
  }

  static bool _readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value == null) return fallback;
    return value.toString().toLowerCase() == 'true';
  }

  static DateTime? _readDate(dynamic value) {
    final source = value?.toString().trim() ?? '';
    return source.isEmpty ? null : DateTime.tryParse(source);
  }
}

String formatUserDate(DateTime? date) {
  if (date == null) return '—';
  return formatAppDate(date);
}

String userExpiryToIso(String value) {
  final parsed = parseAppDateValue(value);
  if (parsed == null) throw const FormatException('Invalid expiry date');
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    23,
    59,
    59,
  ).toIso8601String();
}
