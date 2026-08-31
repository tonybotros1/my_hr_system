class PaymentTypeOption {
  const PaymentTypeOption({required this.id, required this.name});

  final String id;
  final String name;

  factory PaymentTypeOption.fromJson(Map<String, dynamic> json) {
    return PaymentTypeOption(
      id: json['_id']?.toString() ?? '',
      name: json['type']?.toString() ?? '',
    );
  }
}

class PayrollPeriodModel {
  const PayrollPeriodModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  final String id;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;

  factory PayrollPeriodModel.fromJson(Map<String, dynamic> json) {
    return PayrollPeriodModel(
      id: json['_id']?.toString() ?? '',
      name: json['period_name']?.toString() ?? '',
      startDate: _dateFromJson(json['start_date']),
      endDate: _dateFromJson(json['end_date']),
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'period_name': name,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
    };
  }
}

class PayrollModel {
  const PayrollModel({
    required this.id,
    required this.name,
    required this.notes,
    required this.paymentTypeName,
    required this.paymentTypeId,
    this.periods = const [],
  });

  final String id;
  final String name;
  final String notes;
  final String paymentTypeName;
  final String paymentTypeId;
  final List<PayrollPeriodModel> periods;

  factory PayrollModel.fromJson(Map<String, dynamic> json) {
    final rawPeriods = json['details'];
    return PayrollModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      paymentTypeName: json['payment_type_name']?.toString() ?? '',
      paymentTypeId: json['payment_type']?.toString() ?? '',
      periods: rawPeriods is List
          ? rawPeriods
                .whereType<Map>()
                .map(
                  (item) => PayrollPeriodModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'name': name,
      'notes': notes,
      'payment_type': paymentTypeId.isEmpty ? null : paymentTypeId,
    };
  }
}

DateTime? _dateFromJson(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
