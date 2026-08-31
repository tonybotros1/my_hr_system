class IncomeTaxBracketModel {
  const IncomeTaxBracketModel({
    required this.fromAmount,
    required this.toAmount,
    required this.percentage,
  });

  final double fromAmount;
  final double? toAmount;
  final double percentage;

  factory IncomeTaxBracketModel.fromJson(Map<String, dynamic> json) {
    return IncomeTaxBracketModel(
      fromAmount: _asDouble(json['from_amount']),
      toAmount: json['to_amount'] == null ? null : _asDouble(json['to_amount']),
      percentage: _asDouble(json['percentage']),
    );
  }

  Map<String, dynamic> toRequestJson() => {
    'from_amount': fromAmount,
    'to_amount': toAmount,
    'percentage': percentage,
  };
}

class SocialSecurityCeilingModel {
  const SocialSecurityCeilingModel({
    required this.employeePercentage,
    required this.employerPercentage,
    required this.ceiling,
    required this.startDate,
    required this.endDate,
  });

  final double employeePercentage;
  final double employerPercentage;
  final double ceiling;
  final DateTime? startDate;
  final DateTime? endDate;

  factory SocialSecurityCeilingModel.fromJson(Map<String, dynamic> json) {
    return SocialSecurityCeilingModel(
      employeePercentage: _asDouble(json['employee_percentage']),
      employerPercentage: _asDouble(json['employer_percentage']),
      ceiling: _asDouble(json['ceiling']),
      startDate: parseLegislationDate(json['start_date']),
      endDate: parseLegislationDate(json['end_date']),
    );
  }

  Map<String, dynamic> toRequestJson() => {
    'employee_percentage': employeePercentage,
    'employer_percentage': employerPercentage,
    'ceiling': ceiling,
    'start_date': legislationDateToIso(startDate),
    'end_date': legislationDateToIso(endDate),
  };
}

class LegislationModel {
  const LegislationModel({
    required this.id,
    required this.name,
    required this.weekend,
    required this.paidSickLeaveDays,
    required this.halfPaidSickLeaveDays,
    required this.unpaidSickLeaveDays,
    required this.maternityLeaveDays,
    required this.compassionateLeaveDays,
    required this.paternityLeaveDays,
    required this.normalOvertimeHours,
    required this.holidayOvertimeHours,
    required this.socialSecurityCeilings,
    required this.serviceTaxPercentage,
    required this.incomeTaxPercentage,
    required this.incomeTaxCeiling,
    required this.incomeTaxBrackets,
    required this.gratuityFirstFiveYears,
    required this.gratuityAfterFiveYears,
  });

  final String id;
  final String name;
  final List<String> weekend;
  final int paidSickLeaveDays;
  final int halfPaidSickLeaveDays;
  final int unpaidSickLeaveDays;
  final int maternityLeaveDays;
  final int compassionateLeaveDays;
  final int paternityLeaveDays;
  final double normalOvertimeHours;
  final double holidayOvertimeHours;
  final List<SocialSecurityCeilingModel> socialSecurityCeilings;
  final double serviceTaxPercentage;
  final double incomeTaxPercentage;
  final double incomeTaxCeiling;
  final List<IncomeTaxBracketModel> incomeTaxBrackets;
  final int gratuityFirstFiveYears;
  final int gratuityAfterFiveYears;

  factory LegislationModel.fromJson(Map<String, dynamic> json) {
    final ceilings = _modelList(
      json['social_security_ceilings'],
      SocialSecurityCeilingModel.fromJson,
    );
    if (ceilings.isEmpty && _hasLegacySocialSecurity(json)) {
      ceilings.add(
        SocialSecurityCeilingModel(
          employeePercentage: _asDouble(
            json['social_security_employee_percentage'],
          ),
          employerPercentage: _asDouble(
            json['social_security_employer_percentage'],
          ),
          ceiling: _asDouble(json['social_security_ceiling']),
          startDate: parseLegislationDate(
            json['social_security_ceiling_start_date'],
          ),
          endDate: parseLegislationDate(
            json['social_security_ceiling_end_date'],
          ),
        ),
      );
    }

    return LegislationModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString().trim() ?? '',
      weekend: (json['weekend'] is List)
          ? (json['weekend'] as List).map((day) => day.toString()).toList()
          : const [],
      paidSickLeaveDays: _asInt(json['number_of_paid_days_for_sick_leave']),
      halfPaidSickLeaveDays: _asInt(
        json['number_of_half_paid_days_for_sick_leave'],
      ),
      unpaidSickLeaveDays: _asInt(json['number_of_unpaid_days_for_sick_leave']),
      maternityLeaveDays: _asInt(
        json['number_of_paid_days_for_maternity_leave'],
      ),
      compassionateLeaveDays: _asInt(
        json['number_of_paid_days_for_compassionate_leave'],
      ),
      paternityLeaveDays: _asInt(
        json['number_of_paid_days_for_paternity_leave'],
      ),
      normalOvertimeHours: _asDouble(
        json['number_of_working_hours_for_overtime_normal'],
      ),
      holidayOvertimeHours: _asDouble(
        json['number_of_working_hours_for_overtime_holidays'],
      ),
      socialSecurityCeilings: ceilings,
      serviceTaxPercentage: _asDouble(json['service_tax_percentage']),
      incomeTaxPercentage: _asDouble(json['income_tax_percentage']),
      incomeTaxCeiling: _asDouble(json['income_tax_ceiling']),
      incomeTaxBrackets: _modelList(
        json['income_tax_brackets'],
        IncomeTaxBracketModel.fromJson,
      ),
      gratuityFirstFiveYears: _asInt(json['gratuity_first_5_years']),
      gratuityAfterFiveYears: _asInt(json['gratuity_after_5_years']),
    );
  }

  Map<String, dynamic> toRequestJson() {
    final firstCeiling = socialSecurityCeilings.isEmpty
        ? null
        : socialSecurityCeilings.first;
    return {
      'name': name,
      'weekend': weekend,
      'number_of_paid_days_for_sick_leave': paidSickLeaveDays,
      'number_of_half_paid_days_for_sick_leave': halfPaidSickLeaveDays,
      'number_of_unpaid_days_for_sick_leave': unpaidSickLeaveDays,
      'number_of_paid_days_for_maternity_leave': maternityLeaveDays,
      'number_of_paid_days_for_compassionate_leave': compassionateLeaveDays,
      'number_of_paid_days_for_paternity_leave': paternityLeaveDays,
      'number_of_working_hours_for_overtime_normal': normalOvertimeHours,
      'number_of_working_hours_for_overtime_holidays': holidayOvertimeHours,
      'social_security_employee_percentage':
          firstCeiling?.employeePercentage ?? 0,
      'social_security_employer_percentage':
          firstCeiling?.employerPercentage ?? 0,
      'social_security_ceiling': firstCeiling?.ceiling ?? 0,
      'social_security_ceiling_start_date': legislationDateToIso(
        firstCeiling?.startDate,
      ),
      'social_security_ceiling_end_date': legislationDateToIso(
        firstCeiling?.endDate,
      ),
      'social_security_ceilings': socialSecurityCeilings
          .map((line) => line.toRequestJson())
          .toList(),
      'service_tax_percentage': serviceTaxPercentage,
      'income_tax_percentage': incomeTaxPercentage,
      'income_tax_ceiling': incomeTaxCeiling,
      'income_tax_brackets': incomeTaxBrackets
          .map((bracket) => bracket.toRequestJson())
          .toList(),
      'gratuity_first_5_years': gratuityFirstFiveYears,
      'gratuity_after_5_years': gratuityAfterFiveYears,
    };
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ??
      double.tryParse(value?.toString() ?? '')?.toInt() ??
      0;
}

List<T> _modelList<T>(dynamic source, T Function(Map<String, dynamic>) parse) {
  if (source is! List) return <T>[];
  return source
      .whereType<Map>()
      .map((item) => parse(Map<String, dynamic>.from(item)))
      .toList();
}

bool _hasLegacySocialSecurity(Map<String, dynamic> json) {
  return json['social_security_employee_percentage'] != null ||
      json['social_security_employer_percentage'] != null ||
      json['social_security_ceiling'] != null ||
      json['social_security_ceiling_start_date'] != null;
}

DateTime? parseLegislationDate(dynamic value) {
  final source = value?.toString().trim() ?? '';
  if (source.isEmpty) return null;
  final isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(source);
  if (isoDate != null) {
    return DateTime(
      int.parse(isoDate.group(1)!),
      int.parse(isoDate.group(2)!),
      int.parse(isoDate.group(3)!),
    );
  }
  final displayDate = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(source);
  if (displayDate != null) {
    return DateTime(
      int.parse(displayDate.group(3)!),
      int.parse(displayDate.group(2)!),
      int.parse(displayDate.group(1)!),
    );
  }
  final parsed = DateTime.tryParse(source);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

String? legislationDateToIso(DateTime? date) {
  if (date == null) return null;
  return DateTime.utc(date.year, date.month, date.day).toIso8601String();
}

String formatLegislationDate(DateTime? date) {
  if (date == null) return '';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

String formatLegislationNumber(num value) {
  final doubleValue = value.toDouble();
  return doubleValue == doubleValue.truncateToDouble()
      ? doubleValue.toInt().toString()
      : doubleValue.toString();
}
