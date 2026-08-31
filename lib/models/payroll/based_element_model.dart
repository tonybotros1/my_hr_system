class BasedElementModel {
  const BasedElementModel({
    required this.id,
    required this.elementId,
    required this.elementName,
    required this.type,
  });

  final String id;
  final String elementId;
  final String elementName;
  final String type;

  factory BasedElementModel.fromJson(Map<String, dynamic> json) {
    return BasedElementModel(
      id: json['_id']?.toString() ?? '',
      elementId: json['name']?.toString() ?? '',
      elementName: json['name_value']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }
}
