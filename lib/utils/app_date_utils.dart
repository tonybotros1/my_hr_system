DateTime? parseAppDate(String value) {
  final match = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(value.trim());
  if (match == null) return null;
  return _checkedDate(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
  );
}

/// Reads either the app's display format or an ISO value returned by the API.
DateTime? parseAppDateValue(dynamic value) {
  final source = value?.toString().trim() ?? '';
  if (source.isEmpty) return null;
  final displayDate = parseAppDate(source);
  if (displayDate != null) return displayDate;

  final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(source);
  if (isoMatch == null) return null;
  return _checkedDate(
    int.parse(isoMatch.group(1)!),
    int.parse(isoMatch.group(2)!),
    int.parse(isoMatch.group(3)!),
  );
}

String formatAppDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year.toString().padLeft(4, '0')}';
}

String? appDateToIsoOrNull(String value) {
  final date = parseAppDateValue(value);
  return date == null
      ? null
      : DateTime.utc(date.year, date.month, date.day).toIso8601String();
}

DateTime? _checkedDate(int year, int month, int day) {
  if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) {
    return null;
  }
  final result = DateTime(year, month, day);
  if (result.year != year || result.month != month || result.day != day) {
    return null;
  }
  return result;
}
