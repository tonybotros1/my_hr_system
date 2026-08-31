import 'based_element_model.dart';

class PayrollElementModel {
  const PayrollElementModel({
    required this.id,
    required this.key,
    required this.name,
    required this.type,
    required this.priority,
    required this.entryValueName,
    required this.comments,
    required this.functionName,
    required this.allowOverride,
    required this.recurring,
    required this.entryValue,
    required this.standardLink,
    required this.indirect,
    required this.basedElements,
  });

  final String id;
  final String key;
  final String name;
  final String type;
  final String priority;
  final String entryValueName;
  final String comments;
  final String functionName;
  final bool allowOverride;
  final bool recurring;
  final bool entryValue;
  final bool standardLink;
  final bool indirect;
  final List<BasedElementModel> basedElements;

  factory PayrollElementModel.fromJson(Map<String, dynamic> json) {
    final rawBasedElements = json['element_details'];
    return PayrollElementModel(
      id: json['_id']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      entryValueName: json['entry_value_name']?.toString() ?? '',
      comments: json['comments']?.toString() ?? '',
      functionName: json['function']?.toString() ?? '',
      allowOverride: json['is_allow_override'] == true,
      recurring: json['is_recurring'] == true,
      entryValue: json['is_entry_value'] == true,
      standardLink: json['is_standard_link'] == true,
      indirect: json['is_indirect'] == true,
      basedElements: rawBasedElements is List
          ? rawBasedElements
                .whereType<Map>()
                .map(
                  (item) => BasedElementModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'key': key,
      'name': name,
      'type': type,
      'priority': priority,
      'entry_value_name': entryValueName,
      'comments': comments,
      'function': functionName,
      'is_allow_override': allowOverride,
      'is_recurring': recurring,
      'is_entry_value': entryValue,
      'is_standard_link': standardLink,
      'is_indirect': indirect,
    };
  }
}

class PayrollElementOption {
  const PayrollElementOption({required this.id, required this.name});

  final String id;
  final String name;

  factory PayrollElementOption.fromJson(Map<String, dynamic> json) {
    return PayrollElementOption(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
