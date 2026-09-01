import 'package:flutter/material.dart';

import '../../controllers/payroll_controllers/payroll_controller.dart';
import '../form_fields/app_date_form_field.dart';

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
    return AppDateFormField(
      label: label,
      hintText: 'DD-MM-YYYY',
      controller: controller,
      validator: validator,
      firstDate: DateTime(2000),
      lastDate: DateTime(2150),
      helpText: label,
      parseDate: parsePayrollDate,
      formatDate: (date) => formatPayrollDate(date),
    );
  }
}
