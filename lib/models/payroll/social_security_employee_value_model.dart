import 'legislation_model.dart';

class SocialSecurityEmployeeValueModel {
  const SocialSecurityEmployeeValueModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeNumber,
    required this.socialSecurityRegistrationNumber,
    required this.payrollElementName,
    required this.value,
    required this.hasOverride,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeNumber;
  final String socialSecurityRegistrationNumber;
  final String payrollElementName;
  final double? value;
  final bool hasOverride;
  final DateTime? startDate;
  final DateTime? endDate;

  factory SocialSecurityEmployeeValueModel.fromJson(Map<String, dynamic> json) {
    return SocialSecurityEmployeeValueModel(
      id: json['_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString().trim() ?? '',
      employeeNumber: json['employee_number']?.toString().trim() ?? '',
      socialSecurityRegistrationNumber:
          json['social_security_registration_number']?.toString().trim() ?? '',
      payrollElementName: json['payroll_element_name']?.toString().trim() ?? '',
      value: json['value'] == null ? null : _asDouble(json['value']),
      hasOverride: json['has_override'] is bool
          ? json['has_override'] as bool
          : json['value'] != null,
      startDate: parseLegislationDate(json['start_date']),
      endDate: parseLegislationDate(json['end_date']),
    );
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return employeeName.toLowerCase().contains(normalized) ||
        employeeNumber.toLowerCase().contains(normalized) ||
        socialSecurityRegistrationNumber.toLowerCase().contains(normalized) ||
        payrollElementName.toLowerCase().contains(normalized) ||
        (value != null &&
            formatLegislationNumber(value!).toLowerCase().contains(normalized));
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
