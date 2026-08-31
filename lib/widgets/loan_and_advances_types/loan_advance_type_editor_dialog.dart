import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/loan_and_advances_types_controller.dart';
import '../drop_down_menu.dart';
import '../form_fields/app_text_form_field.dart';

Future<void> showLoanAdvanceTypeEditor(BuildContext context) async {
  final screenSize = MediaQuery.sizeOf(context);
  final width = math.min(
    AppSizes.loanAdvanceTypeEditorWidth,
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
        child: const SingleChildScrollView(child: _TypeEditor()),
      ),
    ),
    barrierDismissible: false,
    barrierColor: AppColors.dialogScrim,
  );
}

class _TypeEditor extends GetView<LoanAndAdvancesTypesController> {
  const _TypeEditor();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: controller.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _EditorHeader(),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 480;
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _NameField(),
                      const SizedBox(height: AppSpacing.md),
                      _CodeField(),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _NameField()),
                    const SizedBox(width: AppSpacing.md),
                    const SizedBox(width: 160, child: _CodeField()),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(
              () => CustomDropdown(
                key: ValueKey(controller.selectedBasedElementId.value),
                width: double.infinity,
                hintText: 'Based Element',
                textcontroller: controller.payrollElementName(
                  controller.selectedBasedElementId.value,
                ),
                showedSelectedName: 'name',
                items: controller.payrollElementDropdownItems,
                onOpen: controller.getPayrollElementsForDropdown,
                validator: true,
                onChanged: (key, _) =>
                    controller.selectedBasedElementId.value = key,
                onDelete: () => controller.selectedBasedElementId.value = null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorHeader extends GetView<LoanAndAdvancesTypesController> {
  const _EditorHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 440;
        final title = Obx(
          () => Text(
            controller.currentTypeId.value.isEmpty
                ? 'New Loan / Advance Type'
                : 'Edit Loan / Advance Type',
            style: AppTextStyles.heading(fontSize: 22),
          ),
        );
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Get.back<void>(),
              style: TextButton.styleFrom(foregroundColor: AppColors.textHint),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Obx(
              () => TextButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () async {
                        final saved = await controller.saveType();
                        if (saved) Get.back<void>();
                      },
                child: controller.isSaving.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Type'),
              ),
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: AppSpacing.xs),
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
    );
  }
}

class _NameField extends GetView<LoanAndAdvancesTypesController> {
  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Name',
      hintText: 'Enter the type name',
      controller: controller.name,
      validator: controller.requiredText,
      textCapitalization: TextCapitalization.words,
    );
  }
}

class _CodeField extends GetView<LoanAndAdvancesTypesController> {
  const _CodeField();

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Code',
      hintText: 'For example, LOAN',
      controller: controller.code,
      validator: controller.requiredText,
      textCapitalization: TextCapitalization.characters,
    );
  }
}
