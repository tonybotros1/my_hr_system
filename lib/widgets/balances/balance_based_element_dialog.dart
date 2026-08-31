import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/balances_controller.dart';
import '../drop_down_menu.dart';

Future<void> showBalanceBasedElementDialog(BuildContext context) async {
  final screenSize = MediaQuery.sizeOf(context);
  final width = math.min(
    AppSizes.balanceBasedDialogWidth,
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
        child: const SingleChildScrollView(child: _BasedElementEditor()),
      ),
    ),
  );
}

class _BasedElementEditor extends GetView<BalancesController> {
  const _BasedElementEditor();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: controller.basedElementFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => Text(
                controller.currentBasedElementId.value.isEmpty
                    ? 'New Based Element'
                    : 'Edit Based Element',
                style: AppTextStyles.heading(fontSize: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Obx(
              () => CustomDropdown(
                key: ValueKey(controller.selectedBasedElementId.value),
                width: double.infinity,
                hintText: 'Element Name',
                textcontroller:
                    controller.selectedBasedElementName.value ??
                    controller.payrollElementName(
                      controller.selectedBasedElementId.value,
                    ),
                showedSelectedName: 'name',
                items: controller.payrollElementDropdownItems,
                onOpen: controller.getPayrollElementsForDropdown,
                validator: true,
                onChanged: (key, value) {
                  controller.selectedBasedElementId.value = key;
                  controller.selectedBasedElementName.value =
                      value['name']?.toString() ?? '';
                },
                onDelete: () {
                  controller.selectedBasedElementId.value = null;
                  controller.selectedBasedElementName.value = null;
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(
              () => CustomDropdown(
                key: ValueKey(controller.selectedBasedElementType.value),
                width: double.infinity,
                hintText: 'Type',
                textcontroller: controller.selectedBasedElementType.value,
                showedSelectedName: 'name',
                items: BalancesController.basedElementTypeDropdownItems,
                validator: true,
                onChanged: (key, _) =>
                    controller.selectedBasedElementType.value = key,
                onDelete: () => controller.selectedBasedElementType.value = '',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: controller.isSavingBasedElement.value
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: controller.isSavingBasedElement.value
                        ? null
                        : () async {
                            final saved = await controller.saveBasedElement();
                            if (saved && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: controller.isSavingBasedElement.value
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
            ),
          ],
        ),
      ),
    );
  }
}
