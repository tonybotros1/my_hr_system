import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/payroll_controller.dart';
import '../../models/payroll/payroll_model.dart';
import '../dialogs/app_alert_dialog.dart';
import '../drop_down_menu.dart';
import '../form_fields/app_text_form_field.dart';
import 'monthly_periods_dialog.dart';
import 'payroll_period_dialog.dart';
import 'payroll_period_table.dart';

Future<void> showPayrollEditor(BuildContext context) async {
  final screenSize = MediaQuery.sizeOf(context);
  final width = math.min(
    AppSizes.payrollEditorMaxWidth,
    screenSize.width - (AppSpacing.lg * 2),
  );
  final height = math.max(320.0, screenSize.height - (AppSpacing.lg * 2));

  await Get.dialog<void>(
    Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.editor),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: const _PayrollEditor(),
      ),
    ),
    barrierDismissible: false,
    barrierColor: AppColors.dialogScrim,
  );
}

class _PayrollEditor extends GetView<PayrollController> {
  const _PayrollEditor();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _EditorHeader(),
        const Divider(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 720) {
                  return const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PayrollDetailsSection(),
                        SizedBox(height: AppSpacing.md),
                        SizedBox(height: 430, child: _PeriodDetailsSection()),
                      ],
                    ),
                  );
                }
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PayrollDetailsSection(),
                    SizedBox(height: AppSpacing.md),
                    Expanded(child: _PeriodDetailsSection()),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorHeader extends GetView<PayrollController> {
  const _EditorHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final title = Obx(
            () => Text(
              controller.currentPayrollId.value.isEmpty
                  ? 'New Payroll'
                  : 'Edit Payroll',
              style: AppTextStyles.pageHeading.copyWith(fontSize: 26),
            ),
          );
          final actions = const _HeaderActions();
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: AppSpacing.sm),
                actions,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _HeaderActions extends GetView<PayrollController> {
  const _HeaderActions();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Wrap(
        alignment: WrapAlignment.end,
        spacing: AppSpacing.xs,
        children: [
          TextButton(
            onPressed: controller.isSaving.value ? null : () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              disabledForegroundColor: AppColors.textHint,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: controller.isSaving.value
                ? null
                : controller.savePayroll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              disabledForegroundColor: AppColors.primaryDisabled,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: AppTextStyles.link.copyWith(fontSize: 13),
            ),
            child: controller.isSaving.value
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text('Save Payroll'),
          ),
        ],
      ),
    );
  }
}

class _PayrollDetailsSection extends GetView<PayrollController> {
  const _PayrollDetailsSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Payroll Details',
      child: Form(
        key: controller.payrollFormKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 720;
            final fields = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextFormField(
                  label: 'Name',
                  hintText: 'Enter the payroll name',
                  controller: controller.name,
                  validator: controller.requiredText,
                ),
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => CustomDropdown(
                    key: ValueKey(controller.selectedPaymentTypeId.value),
                    width: double.infinity,
                    hintText: 'Payment Type',
                    textcontroller:
                        controller.selectedPaymentTypeName.value ??
                        controller.paymentTypeName(
                          controller.selectedPaymentTypeId.value,
                        ),
                    showedSelectedName: 'type',
                    items: controller.paymentTypeDropdownItems,
                    onOpen: controller.getPaymentTypesForDropdown,
                    onChanged: (key, value) {
                      controller.selectedPaymentTypeId.value = key;
                      controller.selectedPaymentTypeName.value =
                          value['type']?.toString() ?? '';
                    },
                    onDelete: () {
                      controller.selectedPaymentTypeId.value = null;
                      controller.selectedPaymentTypeName.value = null;
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => _openMonthlyPeriods(context),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('Generate Monthly Periods'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            );
            final notes = AppTextFormField(
              label: 'Notes',
              hintText: 'Add notes about this payroll',
              controller: controller.notes,
              minLines: 7,
              maxLines: 7,
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  fields,
                  const SizedBox(height: AppSpacing.md),
                  notes,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: fields),
                const SizedBox(width: AppSpacing.lg),
                Expanded(flex: 6, child: notes),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openMonthlyPeriods(BuildContext context) async {
    if (controller.currentPayrollId.value.isEmpty) {
      await controller.showInfo(
        'Save the payroll before generating monthly periods.',
      );
      return;
    }
    controller.prepareMonthlyGeneration();
    if (context.mounted) await showMonthlyPeriodsDialog(context);
  }
}

class _PeriodDetailsSection extends GetView<PayrollController> {
  const _PeriodDetailsSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Period Details',
      trailing: FilledButton.icon(
        onPressed: () => _newPeriod(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('New Period'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSizes.payrollActionHeight),
        ),
      ),
      contentPadding: EdgeInsets.zero,
      expandChild: true,
      child: Obx(
        () => PayrollPeriodTable(
          periods: controller.periods.toList(growable: false),
          onEdit: (period) => _editPeriod(context, period),
          onDelete: (period) => _deletePeriod(context, period),
        ),
      ),
    );
  }

  Future<void> _newPeriod(BuildContext context) async {
    if (controller.currentPayrollId.value.isEmpty) {
      await controller.showInfo('Save the payroll before adding a period.');
      return;
    }
    controller.prepareNewPeriod();
    if (context.mounted) await showPayrollPeriodDialog(context);
  }

  Future<void> _editPeriod(
    BuildContext context,
    PayrollPeriodModel period,
  ) async {
    controller.prepareExistingPeriod(period);
    await showPayrollPeriodDialog(context);
  }

  Future<void> _deletePeriod(
    BuildContext context,
    PayrollPeriodModel period,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete payroll period?',
      message: '"${period.name}" will be permanently deleted.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) await controller.deletePeriod(period.id);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    this.contentPadding = const EdgeInsets.all(AppSpacing.lg),
    this.expandChild = false,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry contentPadding;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.section),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.section),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(title, style: AppTextStyles.sectionTitle),
                  ),
                  ?trailing,
                ],
              ),
            ),
            const Divider(),
            if (expandChild)
              Expanded(
                child: Padding(padding: contentPadding, child: child),
              )
            else
              Padding(padding: contentPadding, child: child),
          ],
        ),
      ),
    );
  }
}
