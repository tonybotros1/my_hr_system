import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/payroll_controller.dart';
import '../form_fields/app_text_form_field.dart';

class PayrollDateField extends StatelessWidget {
  const PayrollDateField({
    required this.label,
    required this.controller,
    super.key,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: label,
      hintText: 'DD-MM-YYYY',
      controller: controller,
      validator: validator,
      readOnly: true,
      onTap: () => _selectDate(context),
      suffixIcon: IconButton(
        tooltip: 'Select $label',
        focusNode: FocusNode(skipTraversal: true),
        onPressed: () => _selectDate(context),
        icon: const Icon(
          Icons.calendar_today_outlined,
          size: 18,
          color: AppColors.iconMuted,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final existing = parsePayrollDate(controller.text);
    final selected = await showDatePicker(
      context: context,
      initialDate: existing ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2150),
      helpText: label,
    );
    if (selected != null) controller.text = formatPayrollDate(selected);
  }
}
