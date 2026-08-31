class PublicHolidayModel {
  const PublicHolidayModel({
    required this.id,
    required this.name,
    required this.date,
    required this.legislationId,
  });

  final String id;
  final String name;
  final DateTime date;
  final String legislationId;

  factory PublicHolidayModel.fromJson(Map<String, dynamic> json) {
    return PublicHolidayModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString().trim() ?? '',
      date:
          parsePublicHolidayDate(json['date']) ??
          (throw const FormatException('Invalid public holiday date')),
      legislationId: json['legislation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'name': name,
      'date': publicHolidayDateToIso(date),
      if (legislationId.isNotEmpty) 'legislation': legislationId,
    };
  }

  PublicHolidayModel copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? legislationId,
  }) {
    return PublicHolidayModel(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      legislationId: legislationId ?? this.legislationId,
    );
  }
}

class PublicHolidayLegislationOption {
  const PublicHolidayLegislationOption({required this.id, required this.name});

  final String id;
  final String name;

  factory PublicHolidayLegislationOption.fromJson(Map<String, dynamic> json) {
    return PublicHolidayLegislationOption(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString().trim() ?? '',
    );
  }
}

DateTime? parsePublicHolidayDate(dynamic value) {
  final source = value?.toString().trim() ?? '';
  if (source.isEmpty) return null;
  final datePart = source.length >= 10 ? source.substring(0, 10) : source;
  final parts = datePart.split('-');
  if (parts.length == 3) {
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
  }
  final parsed = DateTime.tryParse(source);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

String publicHolidayDateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String publicHolidayDateToIso(DateTime date) {
  return DateTime.utc(date.year, date.month, date.day).toIso8601String();
}

String formatPublicHolidayDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}
