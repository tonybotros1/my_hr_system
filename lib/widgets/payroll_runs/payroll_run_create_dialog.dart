import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/payroll_runs_controller.dart';
import '../drop_down_menu.dart';

Future<void> showPayrollRunCreateDialog(BuildContext context) async {
  final screenSize = MediaQuery.sizeOf(context);
  final width = math.min(
    AppSizes.payrollRunCreateDialogWidth,
    screenSize.width - (AppSpacing.lg * 2),
  );
  await Get.dialog<void>(
    Dialog(
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
        child: const SingleChildScrollView(child: _CreateRunDialog()),
      ),
    ),
    barrierDismissible: false,
    barrierColor: AppColors.dialogScrim,
  );
}

class _CreateRunDialog extends GetView<PayrollRunsController> {
  const _CreateRunDialog();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.createFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'New Payroll Run',
                    style: AppTextStyles.heading(fontSize: 22),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back<void>(),
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(
                  () => CustomDropdown(
                    key: ValueKey(controller.selectedPayrollId.value),
                    width: double.infinity,
                    hintText: 'Payroll Name',
                    textcontroller: controller.payrollName(
                      controller.selectedPayrollId.value,
                    ),
                    showedSelectedName: 'name',
                    items: controller.payrollDropdownItems,
                    onOpen: controller.getPayrollsForDropdown,
                    validator: true,
                    onChanged: (key, _) {
                      unawaited(controller.selectPayroll(key));
                    },
                    onDelete: () {
                      controller.selectedPayrollId.value = null;
                      controller.selectedPeriodId.value = null;
                      controller.selectedEmployeeId.value = null;
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => CustomDropdown(
                    key: ValueKey(
                      '${controller.selectedPayrollId.value}-${controller.selectedPeriodId.value}',
                    ),
                    width: double.infinity,
                    hintText: 'Period Name',
                    textcontroller: controller.periodName(
                      controller.selectedPeriodId.value,
                    ),
                    showedSelectedName: 'period_name',
                    items: controller.periodDropdownItems,
                    enabled: controller.selectedPayrollId.value != null,
                    onOpen: controller.getPeriodsForDropdown,
                    validator: true,
                    onChanged: (key, _) =>
                        controller.selectedPeriodId.value = key,
                    onDelete: () => controller.selectedPeriodId.value = null,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => CustomDropdown(
                    key: ValueKey(
                      '${controller.selectedPayrollId.value}-${controller.selectedEmployeeId.value}',
                    ),
                    width: double.infinity,
                    hintText: 'Employee (optional)',
                    textcontroller: controller.employeeName(
                      controller.selectedEmployeeId.value,
                    ),
                    showedSelectedName: 'full_name',
                    items: controller.employeeDropdownItems,
                    enabled: controller.selectedPayrollId.value != null,
                    onOpen: controller.getEmployeesForDropdown,
                    onChanged: (key, _) =>
                        controller.selectedEmployeeId.value = key,
                    onDelete: () => controller.selectedEmployeeId.value = null,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => CustomDropdown(
                    key: ValueKey(controller.selectedElementId.value),
                    width: double.infinity,
                    hintText: 'Element Name (optional)',
                    textcontroller: controller.elementName(
                      controller.selectedElementId.value,
                    ),
                    showedSelectedName: 'name',
                    items: controller.elementDropdownItems,
                    onOpen: controller.getElementsForDropdown,
                    onChanged: (key, _) =>
                        controller.selectedElementId.value = key,
                    onDelete: () => controller.selectedElementId.value = null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Leave Employee and Element empty to run the complete payroll period.',
                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: controller.isCreating.value
                        ? null
                        : () => Get.back<void>(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: controller.isCreating.value
                        ? null
                        : () async {
                            final created = await controller.createPayrollRun();
                            if (created) Get.back<void>();
                          },
                    child: controller.isCreating.value
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Run'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
