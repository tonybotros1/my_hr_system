class LeaveTypeModel {
  const LeaveTypeModel({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.basedElementName,
    required this.basedElementId,
  });

  final String id;
  final String name;
  final String code;
  final String type;
  final String basedElementName;
  final String basedElementId;

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      basedElementName: json['based_element_name']?.toString() ?? '',
      basedElementId: json['based_element']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'name': name,
      'code': code,
      'type': type,
      'based_element': basedElementId,
    };
  }
}

class LeavePayrollElementOption {
  const LeavePayrollElementOption({required this.id, required this.name});

  final String id;
  final String name;

  factory LeavePayrollElementOption.fromJson(Map<String, dynamic> json) {
    return LeavePayrollElementOption(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
