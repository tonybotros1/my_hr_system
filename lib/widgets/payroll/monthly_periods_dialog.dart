import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/payroll_controller.dart';
import 'payroll_date_field.dart';

Future<void> showMonthlyPeriodsDialog(BuildContext context) async {
  final screenSize = MediaQuery.sizeOf(context);
  final width = math.min(
    AppSizes.payrollMonthlyDialogWidth,
    screenSize.width - (AppSpacing.lg * 2),
  );

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.dialogScrim,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.editor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: const _MonthlyPeriodsEditor(),
      ),
    ),
  );
}

class _MonthlyPeriodsEditor extends GetView<PayrollController> {
  const _MonthlyPeriodsEditor();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: controller.monthlyPeriodsFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Generate Monthly Periods',
              style: AppTextStyles.heading(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose the first day of the payroll year. The backend will create the twelve monthly periods that do not already exist.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            PayrollDateField(
              label: 'Year Start Date',
              controller: controller.yearStartDate,
              validator: controller.requiredDate,
            ),
            const SizedBox(height: AppSpacing.xl),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: controller.isGeneratingPeriods.value
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: controller.isGeneratingPeriods.value
                        ? null
                        : () async {
                            final generated = await controller
                                .generateMonthlyPeriods();
                            if (generated && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                    ),
                    child: controller.isGeneratingPeriods.value
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Generate'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
