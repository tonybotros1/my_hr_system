class BalanceBasedElementModel {
  const BalanceBasedElementModel({
    required this.id,
    required this.elementId,
    required this.elementName,
    required this.type,
  });

  final String id;
  final String elementId;
  final String elementName;
  final String type;

  factory BalanceBasedElementModel.fromJson(Map<String, dynamic> json) {
    return BalanceBasedElementModel(
      id: json['_id']?.toString() ?? '',
      elementId: json['name']?.toString() ?? '',
      elementName: json['name_value']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {'name': elementId, 'type': type};
  }
}

class BalancePayrollElementOption {
  const BalancePayrollElementOption({required this.id, required this.name});

  final String id;
  final String name;

  factory BalancePayrollElementOption.fromJson(Map<String, dynamic> json) {
    return BalancePayrollElementOption(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class BalanceModel {
  const BalanceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.dimension,
    required this.description,
    required this.showOnAssignment,
    required this.showOnPayroll,
    required this.showOnLeave,
    this.basedElements = const [],
  });

  final String id;
  final String name;
  final String type;
  final String dimension;
  final String description;
  final bool showOnAssignment;
  final bool showOnPayroll;
  final bool showOnLeave;
  final List<BalanceBasedElementModel> basedElements;

  factory BalanceModel.fromJson(Map<String, dynamic> json) {
    final rawElements = json['element_details'];
    return BalanceModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      dimension: json['balance_dimension']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      showOnAssignment: _toBool(json['show_on_assignment']),
      showOnPayroll: _toBool(json['show_on_payroll']),
      showOnLeave: _toBool(json['show_on_leave']),
      basedElements: rawElements is List
          ? rawElements
                .whereType<Map>()
                .map(
                  (item) => BalanceBasedElementModel.fromJson(
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
      'type': type,
      'balance_dimension': dimension,
      'description': description,
      'show_on_assignment': showOnAssignment,
      'show_on_payroll': showOnPayroll,
      'show_on_leave': showOnLeave,
    };
  }
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}
