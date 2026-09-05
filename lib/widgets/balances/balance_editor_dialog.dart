import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/balances_controller.dart';
import '../../models/payroll/balance_model.dart';
import '../dialogs/app_alert_dialog.dart';
import '../drop_down_menu.dart';
import '../form_fields/app_text_form_field.dart';
import 'balance_based_element_dialog.dart';
import 'balance_based_elements_table.dart';

Future<void> showBalanceEditor(BuildContext context) async {
  final screenSize = MediaQuery.sizeOf(context);
  final width = math.min(
    AppSizes.balanceEditorMaxWidth,
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
        child: const _BalanceEditor(),
      ),
    ),
    barrierDismissible: false,
    barrierColor: AppColors.dialogScrim,
  );
}

class _BalanceEditor extends StatelessWidget {
  const _BalanceEditor();

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
                        _BalanceDetailsSection(),
                        SizedBox(height: AppSpacing.md),
                        SizedBox(height: 430, child: _BasedElementsSection()),
                      ],
                    ),
                  );
                }
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BalanceDetailsSection(),
                    SizedBox(height: AppSpacing.md),
                    Expanded(child: _BasedElementsSection()),
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

class _EditorHeader extends GetView<BalancesController> {
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
              controller.currentBalanceId.value.isEmpty
                  ? 'New Balance'
                  : 'Edit Balance',
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

class _HeaderActions extends GetView<BalancesController> {
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
                : controller.saveBalance,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              disabledForegroundColor: AppColors.primaryDisabled,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: AppTextStyles.link.copyWith(fontSize: 13),
            ),
            child: controller.isSaving.value
                ? SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text('Save Balance'),
          ),
        ],
      ),
    );
  }
}

class _BalanceDetailsSection extends GetView<BalancesController> {
  const _BalanceDetailsSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Balance Details',
      child: Form(
        key: controller.balanceFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 720;
                final fields = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextFormField(
                      label: 'Balance Name',
                      hintText: 'Enter the balance name',
                      controller: controller.name,
                      validator: controller.requiredText,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Obx(
                      () => CustomDropdown(
                        key: ValueKey(controller.selectedType.value),
                        width: double.infinity,
                        hintText: 'Balance Type',
                        textcontroller: controller.selectedType.value,
                        showedSelectedName: 'name',
                        items: BalancesController.typeDropdownItems,
                        validator: true,
                        onChanged: (key, _) =>
                            controller.selectedType.value = key,
                        onDelete: () => controller.selectedType.value = '',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Obx(
                      () => CustomDropdown(
                        key: ValueKey(controller.selectedDimension.value),
                        width: double.infinity,
                        hintText: 'Balance Dimensions',
                        textcontroller: controller.selectedDimension.value,
                        showedSelectedName: 'name',
                        items: BalancesController.dimensionDropdownItems,
                        validator: true,
                        onChanged: (key, _) =>
                            controller.selectedDimension.value = key,
                        onDelete: () => controller.selectedDimension.value = '',
                      ),
                    ),
                  ],
                );
                final description = AppTextFormField(
                  label: 'Description',
                  hintText: 'Add optional description...',
                  controller: controller.description,
                  minLines: 7,
                  maxLines: 7,
                );
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      fields,
                      const SizedBox(height: AppSpacing.md),
                      description,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: fields),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 7, child: description),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const _ShowOnCards(),
          ],
        ),
      ),
    );
  }
}

class _ShowOnCards extends GetView<BalancesController> {
  const _ShowOnCards();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 620;
        return Obx(() {
          final cards = [
            _CheckCard(
              label: 'Show on Assignment',
              value: controller.showOnAssignment.value,
              onChanged: (value) => controller.showOnAssignment.value = value,
            ),
            _CheckCard(
              label: 'Show on Payroll',
              value: controller.showOnPayroll.value,
              onChanged: (value) => controller.showOnPayroll.value = value,
            ),
            _CheckCard(
              label: 'Show on Leave',
              value: controller.showOnLeave.value,
              onChanged: (value) => controller.showOnLeave.value = value,
            ),
          ];
          if (stacked) {
            return Column(
              children: [
                cards[0],
                const SizedBox(height: AppSpacing.sm),
                cards[1],
                const SizedBox(height: AppSpacing.sm),
                cards[2],
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: cards[1]),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: cards[2]),
            ],
          );
        });
      },
    );
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.softSurface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppRadii.field),
        child: SizedBox(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                Checkbox(
                  value: value,
                  onChanged: (selected) => onChanged(selected ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(label, style: AppTextStyles.checkboxLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BasedElementsSection extends GetView<BalancesController> {
  const _BasedElementsSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Based Elements',
      trailing: FilledButton.icon(
        onPressed: () => _newBasedElement(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('New Based Element'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSizes.payrollActionHeight),
        ),
      ),
      contentPadding: EdgeInsets.zero,
      expandChild: true,
      child: Obx(
        () => BalanceBasedElementsTable(
          elements: controller.basedElements.toList(growable: false),
          onEdit: (element) => _editBasedElement(context, element),
          onDelete: (element) => _deleteBasedElement(context, element),
        ),
      ),
    );
  }

  Future<void> _newBasedElement(BuildContext context) async {
    if (controller.currentBalanceId.value.isEmpty) {
      await controller.showInfo(
        'Save the balance before adding a based element.',
      );
      return;
    }
    controller.prepareNewBasedElement();
    if (context.mounted) await showBalanceBasedElementDialog(context);
  }

  Future<void> _editBasedElement(
    BuildContext context,
    BalanceBasedElementModel element,
  ) async {
    await controller.prepareExistingBasedElement(element);
    if (context.mounted) await showBalanceBasedElementDialog(context);
  }

  Future<void> _deleteBasedElement(
    BuildContext context,
    BalanceBasedElementModel element,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete based element?',
      message: '"${element.elementName}" will be permanently deleted.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) await controller.deleteBasedElement(element.id);
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
                    decoration: BoxDecoration(
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
