import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../consts.dart';
import '../../utils/app_date_utils.dart';
import 'app_text_form_field.dart';

export '../../utils/app_date_utils.dart';

typedef AppDateParser = DateTime? Function(String value);
typedef AppDateFormatter = String Function(DateTime date);

/// The single project-wide date input.
///
/// It owns typed DD-MM-YYYY input, strict validation, date selection, and
/// clearing so every screen exposes the same date behavior and appearance.
class AppDateFormField extends StatelessWidget {
  const AppDateFormField({
    required this.label,
    required this.controller,
    super.key,
    this.hintText = 'DD-MM-YYYY',
    this.validator,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.helpText,
    this.parseDate = parseAppDate,
    this.formatDate = formatAppDate,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final String? helpText;
  final AppDateParser parseDate;
  final AppDateFormatter formatDate;
  final ValueChanged<DateTime?>? onChanged;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return AppTextFormField(
          label: label,
          hintText: hintText,
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.datetime,
          textInputAction: textInputAction,
          inputFormatters: const [AppDateInputFormatter()],
          validator: _validate,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          enabled: enabled,
          onChanged: _handleTypedValue,
          suffixIcon: ExcludeFocus(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Select $label',
                  onPressed: enabled ? () => _selectDate(context) : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: AppSizes.inputMinHeight,
                    height: AppSizes.inputMinHeight,
                  ),
                  color: AppColors.iconMuted,
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    size: AppSizes.inputIconSize,
                  ),
                ),
                if (value.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear $label',
                    onPressed: enabled ? _clear : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: AppSizes.inputMinHeight,
                      height: AppSizes.inputMinHeight,
                    ),
                    color: AppColors.error,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: AppSizes.inputIconSize,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _validate(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return validator?.call(rawValue);
    final parsed = _validDate(value);
    if (parsed == null) {
      return 'Enter a valid date in DD-MM-YYYY format.';
    }
    return validator?.call(value);
  }

  DateTime? _validDate(String value) {
    final parsed = parseDate(value);
    if (parsed == null || formatDate(parsed) != value) return null;
    final date = DateUtils.dateOnly(parsed);
    final minimum = DateUtils.dateOnly(firstDate ?? DateTime(1900));
    final maximum = DateUtils.dateOnly(lastDate ?? DateTime(2200, 12, 31));
    if (date.isBefore(minimum) || date.isAfter(maximum)) return null;
    return date;
  }

  void _handleTypedValue(String value) {
    if (value.isEmpty) {
      onChanged?.call(null);
      return;
    }
    onChanged?.call(_validDate(value));
  }

  Future<void> _selectDate(BuildContext context) async {
    final minimum = DateUtils.dateOnly(firstDate ?? DateTime(1900));
    final maximum = DateUtils.dateOnly(lastDate ?? DateTime(2200, 12, 31));
    var selected = _validDate(controller.text) ?? initialDate ?? DateTime.now();
    selected = DateUtils.dateOnly(selected);
    if (selected.isBefore(minimum)) selected = minimum;
    if (selected.isAfter(maximum)) selected = maximum;

    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: minimum,
      lastDate: maximum,
      helpText: helpText ?? label,
    );
    if (picked == null) return;
    final date = DateUtils.dateOnly(picked);
    controller.text = formatDate(date);
    onChanged?.call(date);
  }

  void _clear() {
    if (controller.text.isEmpty) {
      onChanged?.call(null);
      return;
    }
    controller.clear();
    onChanged?.call(null);
  }
}

class AppDateInputFormatter extends TextInputFormatter {
  const AppDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) return oldValue;
    final formatted = _formatDigits(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection(
        baseOffset: _selectionOffset(newValue, newValue.selection.baseOffset),
        extentOffset: _selectionOffset(
          newValue,
          newValue.selection.extentOffset,
        ),
      ),
    );
  }

  String _formatDigits(String digits) {
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index == 2 || index == 4) buffer.write('-');
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  int _selectionOffset(TextEditingValue value, int rawOffset) {
    if (rawOffset <= 0) return 0;
    final safeOffset = math.min(rawOffset, value.text.length);
    final digitsBeforeCursor = value.text
        .substring(0, safeOffset)
        .replaceAll(RegExp(r'\D'), '')
        .length;
    final formattedOffset = digitsBeforeCursor <= 2
        ? digitsBeforeCursor
        : digitsBeforeCursor <= 4
        ? digitsBeforeCursor + 1
        : digitsBeforeCursor + 2;
    return math.min(
      formattedOffset,
      _formatDigits(value.text.replaceAll(RegExp(r'\D'), '')).length,
    );
  }
}
