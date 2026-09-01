import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../consts.dart';
import 'app_text_form_field.dart';

typedef AppDateParser = DateTime? Function(String value);
typedef AppDateFormatter = String Function(DateTime date);

DateTime? parseAppDate(String value) {
  final parsed = DateTime.tryParse(value.trim());
  return parsed == null ? null : DateUtils.dateOnly(parsed);
}

String formatAppDate(DateTime date) {
  final day = DateUtils.dateOnly(date);
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

/// The single project-wide date input.
///
/// It owns date selection, visual clearing, and Delete/Backspace handling so
/// every screen exposes the same date behavior and appearance.
class AppDateFormField extends StatelessWidget {
  const AppDateFormField({
    required this.label,
    required this.controller,
    super.key,
    this.hintText = 'YYYY-MM-DD',
    this.validator,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.helpText,
    this.parseDate = parseAppDate,
    this.formatDate = formatAppDate,
    this.onChanged,
    this.enabled = true,
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Focus(
          onKeyEvent: (_, event) {
            if (!enabled || event is! KeyDownEvent) {
              return KeyEventResult.ignored;
            }
            if (event.logicalKey == LogicalKeyboardKey.delete ||
                event.logicalKey == LogicalKeyboardKey.backspace) {
              _clear();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: AppTextFormField(
            key: ValueKey(value.text),
            label: label,
            hintText: hintText,
            controller: controller,
            validator: validator,
            enabled: enabled,
            readOnly: true,
            onTap: enabled ? () => _selectDate(context) : null,
            suffixIcon: value.text.isEmpty
                ? IconButton(
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
                  )
                : IconButton(
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
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final minimum = DateUtils.dateOnly(firstDate ?? DateTime(1900));
    final maximum = DateUtils.dateOnly(lastDate ?? DateTime(2200, 12, 31));
    var selected = parseDate(controller.text) ?? initialDate ?? DateTime.now();
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
    if (controller.text.isEmpty) return;
    controller.clear();
    onChanged?.call(null);
  }
}
