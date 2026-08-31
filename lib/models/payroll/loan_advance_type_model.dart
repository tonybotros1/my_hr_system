class LoanAdvanceTypeModel {
  const LoanAdvanceTypeModel({
    required this.id,
    required this.name,
    required this.code,
    required this.basedElementName,
    required this.basedElementId,
  });

  final String id;
  final String name;
  final String code;
  final String basedElementName;
  final String basedElementId;

  factory LoanAdvanceTypeModel.fromJson(Map<String, dynamic> json) {
    return LoanAdvanceTypeModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      basedElementName: json['based_element_name']?.toString() ?? '',
      basedElementId: json['based_element']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {'name': name, 'code': code, 'based_element': basedElementId};
  }
}

class LoanAdvancePayrollElementOption {
  const LoanAdvancePayrollElementOption({required this.id, required this.name});

  final String id;
  final String name;

  factory LoanAdvancePayrollElementOption.fromJson(Map<String, dynamic> json) {
    return LoanAdvancePayrollElementOption(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
