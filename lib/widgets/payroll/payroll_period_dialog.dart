import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/payroll_controller.dart';
import '../drop_down_menu.dart';
import '../form_fields/app_text_form_field.dart';
import 'payroll_date_field.dart';

Future<void> showPayrollPeriodDialog(BuildContext context) async {
  final screenSize = MediaQuery.sizeOf(context);
  final width = math.min(
    AppSizes.payrollPeriodDialogWidth,
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
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: screenSize.height - (AppSpacing.lg * 2),
        ),
        child: const SingleChildScrollView(child: _PeriodEditor()),
      ),
    ),
  );
}

class _PeriodEditor extends GetView<PayrollController> {
  const _PeriodEditor();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: controller.periodFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => Text(
                controller.currentPeriodId.value.isEmpty
                    ? 'New Payroll Period'
                    : 'Edit Payroll Period',
                style: AppTextStyles.heading(fontSize: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextFormField(
              label: 'Period',
              hintText: 'Enter the period name',
              controller: controller.periodName,
              validator: controller.requiredText,
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 430;
                final start = PayrollDateField(
                  label: 'Start Date',
                  controller: controller.periodStartDate,
                  validator: controller.requiredDate,
                );
                final end = PayrollDateField(
                  label: 'End Date',
                  controller: controller.periodEndDate,
                  validator: controller.requiredDate,
                );
                if (stacked) {
                  return Column(
                    children: [
                      start,
                      const SizedBox(height: AppSpacing.md),
                      end,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: start),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: end),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(
              () => CustomDropdown(
                key: ValueKey(controller.selectedPeriodStatus.value),
                width: double.infinity,
                hintText: 'Status',
                textcontroller: controller.selectedPeriodStatus.value,
                showedSelectedName: 'name',
                items: PayrollController.statusDropdownItems,
                validator: true,
                onChanged: (key, _) =>
                    controller.selectedPeriodStatus.value = key,
                onDelete: () => controller.selectedPeriodStatus.value = '',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _PeriodActions(),
          ],
        ),
      ),
    );
  }
}

class _PeriodActions extends GetView<PayrollController> {
  const _PeriodActions();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: controller.isSavingPeriod.value
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: controller.isSavingPeriod.value
                ? null
                : () async {
                    final saved = await controller.savePeriod();
                    if (saved && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            child: controller.isSavingPeriod.value
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
