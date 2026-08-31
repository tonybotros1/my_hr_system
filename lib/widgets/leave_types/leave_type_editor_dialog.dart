import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/leave_types_controller.dart';
import '../drop_down_menu.dart';
import '../form_fields/app_text_form_field.dart';

Future<void> showLeaveTypeEditor(BuildContext context) async {
  final screenSize = MediaQuery.sizeOf(context);
  final width = math.min(
    AppSizes.leaveTypeEditorWidth,
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
        child: const SingleChildScrollView(child: _LeaveTypeEditor()),
      ),
    ),
    barrierDismissible: false,
  );
}

class _LeaveTypeEditor extends GetView<LeaveTypesController> {
  const _LeaveTypeEditor();

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
                    const SizedBox(width: 140, child: _CodeField()),
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
                onOpen: controller.getLeavePayrollElementsForDropdown,
                validator: true,
                onChanged: (key, _) =>
                    controller.selectedBasedElementId.value = key,
                onDelete: () => controller.selectedBasedElementId.value = null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _DayTypeCards(),
          ],
        ),
      ),
    );
  }
}

class _EditorHeader extends GetView<LeaveTypesController> {
  const _EditorHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final title = Obx(
          () => Text(
            controller.currentLeaveTypeId.value.isEmpty
                ? 'New Leave Type'
                : 'Edit Leave Type',
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
                        final saved = await controller.saveLeaveType();
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

class _NameField extends GetView<LeaveTypesController> {
  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Name',
      hintText: 'Enter the leave type name',
      controller: controller.name,
      validator: controller.requiredText,
      textCapitalization: TextCapitalization.words,
    );
  }
}

class _CodeField extends GetView<LeaveTypesController> {
  const _CodeField();

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Code',
      hintText: 'For example, AL',
      controller: controller.code,
      validator: controller.requiredText,
      textCapitalization: TextCapitalization.characters,
    );
  }
}

class _DayTypeCards extends GetView<LeaveTypesController> {
  const _DayTypeCards();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 420;
        return Obx(() {
          final cards = LeaveTypesController.dayTypes
              .map(
                (type) => _DayTypeCard(
                  type: type,
                  selected: controller.selectedDayType.value == type,
                  onTap: () => controller.selectedDayType.value = type,
                ),
              )
              .toList(growable: false);
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cards.first,
                const SizedBox(height: AppSpacing.sm),
                cards.last,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: cards.first),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: cards.last),
            ],
          );
        });
      },
    );
  }
}

class _DayTypeCard extends StatelessWidget {
  const _DayTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final String type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.softSurface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? const Color(0xFF9EDBD6) : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.field),
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 19,
                  color: selected ? AppColors.primary : AppColors.iconMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    type,
                    style: AppTextStyles.checkboxLabel.copyWith(
                      color: selected
                          ? AppColors.primaryDark
                          : const Color(0xFF496663),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
