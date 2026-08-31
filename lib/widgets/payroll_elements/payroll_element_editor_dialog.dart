import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/payroll_elements_controller.dart';
import '../../models/payroll/based_element_model.dart';
import '../dialogs/app_alert_dialog.dart';
import '../drop_down_menu.dart';
import '../form_fields/app_text_form_field.dart';

Map<String, dynamic> _namedDropdownItems(Iterable<String> values) => {
  for (final value in values) value: {'name': value},
};

Future<void> showPayrollElementEditor(BuildContext context) async {
  final screenSize = MediaQuery.sizeOf(context);
  final narrow = screenSize.width < AppSizes.payrollCompactBreakpoint;
  final width = narrow
      ? screenSize.width - AppSpacing.xl
      : math.min(screenSize.width * .75, AppSizes.payrollEditorMaxWidth);
  final height = screenSize.height - (narrow ? AppSpacing.lg : AppSpacing.xxl);

  await Get.dialog<void>(
    Dialog(
      insetPadding: EdgeInsets.all(narrow ? AppSpacing.sm : AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.editor),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: const PayrollElementEditor(),
      ),
    ),
    barrierDismissible: false,
  );
}

class PayrollElementEditor extends GetView<PayrollElementsController> {
  const PayrollElementEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            sliver: SliverList.list(
              children: [
                const _EditorHeader(),
                const SizedBox(height: AppSpacing.lg),
                DecoratedBox(
                  decoration: AppDecorations.contentCard,
                  child: Form(
                    key: controller.elementFormKey,
                    child: const Column(
                      children: [
                        _ElementDetailsSection(),
                        Divider(),
                        _BasedElementsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorHeader extends GetView<PayrollElementsController> {
  const _EditorHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final title = Obx(
          () => Text(
            controller.currentElementId.value.isEmpty
                ? 'New Payroll Element'
                : 'Edit Payroll Element',
            style: AppTextStyles.pageHeading,
          ),
        );
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Get.back<void>(),
              style: TextButton.styleFrom(foregroundColor: AppColors.textHint),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: AppSpacing.lg),
            Obx(
              () => TextButton(
                onPressed: controller.isSaving.value
                    ? null
                    : controller.saveElement,
                child: controller.isSaving.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Element'),
              ),
            ),
          ],
        );
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
    );
  }
}

class _ElementDetailsSection extends GetView<PayrollElementsController> {
  const _ElementDetailsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(title: 'Element Details'),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 880) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _DetailFields(maxColumns: 2)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextFormField(
                        label: 'Comments',
                        hintText: 'Add optional comments...',
                        controller: controller.comments,
                        minLines: 8,
                        maxLines: 8,
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailFields(
                    maxColumns: constraints.maxWidth >= 590 ? 2 : 1,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextFormField(
                    label: 'Comments',
                    hintText: 'Add optional comments...',
                    controller: controller.comments,
                    minLines: 4,
                    maxLines: 6,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ElementFlags(),
        ],
      ),
    );
  }
}

class _DetailFields extends GetView<PayrollElementsController> {
  const _DetailFields({required this.maxColumns});

  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = maxColumns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: width,
              child: AppTextFormField(
                label: 'Element Key',
                hintText: 'Enter the unique key',
                controller: controller.elementKey,
                validator: controller.requiredText,
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            SizedBox(
              width: width,
              child: AppTextFormField(
                label: 'Element Name',
                hintText: 'Enter the display name',
                controller: controller.elementName,
                validator: controller.requiredText,
                textCapitalization: TextCapitalization.words,
              ),
            ),
            SizedBox(
              width: width,
              child: Obx(
                () => CustomDropdown(
                  key: ValueKey(controller.selectedElementType.value),
                  width: double.infinity,
                  hintText: 'Element Type',
                  textcontroller: controller.selectedElementType.value,
                  showedSelectedName: 'name',
                  items: _namedDropdownItems(
                    PayrollElementsController.elementTypes,
                  ),
                  onChanged: (key, _) =>
                      controller.selectedElementType.value = key,
                  onDelete: () => controller.selectedElementType.value = '',
                ),
              ),
            ),
            SizedBox(
              width: width,
              child: Obx(
                () => CustomDropdown(
                  key: ValueKey(controller.selectedFunction.value),
                  width: double.infinity,
                  hintText: 'Function',
                  textcontroller: controller.selectedFunction.value,
                  showedSelectedName: 'name',
                  items: _namedDropdownItems(
                    PayrollElementsController.functions,
                  ),
                  onChanged: (key, _) =>
                      controller.selectedFunction.value = key,
                  onDelete: () => controller.selectedFunction.value = '',
                ),
              ),
            ),
            SizedBox(
              width: width,
              child: AppTextFormField(
                label: 'Priority',
                hintText: '0',
                controller: controller.priority,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: width,
              child: AppTextFormField(
                label: 'Entry Value Name',
                hintText: 'For example, Number of Days',
                controller: controller.entryValueName,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ElementFlags extends GetView<PayrollElementsController> {
  const _ElementFlags();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final columns = constraints.maxWidth >= 900
            ? 5
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _FlagCard(
              width: width,
              label: 'Allow Override',
              value: controller.allowOverride,
            ),
            _FlagCard(
              width: width,
              label: 'Recurring',
              value: controller.recurring,
            ),
            _FlagCard(
              width: width,
              label: 'Entry Value',
              value: controller.entryValue,
            ),
            _FlagCard(
              width: width,
              label: 'Standard Link',
              value: controller.standardLink,
            ),
            _FlagCard(
              width: width,
              label: 'Indirect',
              value: controller.indirect,
            ),
          ],
        );
      },
    );
  }
}

class _FlagCard extends StatelessWidget {
  const _FlagCard({
    required this.width,
    required this.label,
    required this.value,
  });

  final double width;
  final String label;
  final RxBool value;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: width,
        child: Material(
          color: AppColors.softSurface,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.field),
          ),
          child: CheckboxListTile(
            value: value.value,
            onChanged: (selected) => value.value = selected == true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
            ),
            dense: true,
            title: Text(label, style: AppTextStyles.checkboxLabel),
          ),
        ),
      ),
    );
  }
}

class _BasedElementsSection extends GetView<PayrollElementsController> {
  const _BasedElementsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              const _SectionTitle(title: 'Based Elements'),
              FilledButton.icon(
                onPressed: () => _openNewBasedElement(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Based Element'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Obx(() {
            if (controller.basedElements.isEmpty) {
              return Container(
                constraints: const BoxConstraints(minHeight: 190),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.softSurface,
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  border: Border.all(
                    color: AppColors.borderStrong,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(
                        text: 'No based elements added\n',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            'Add an element if this payroll element depends on another payroll value.',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
              );
            }
            return _BasedElementsTable(
              elements: controller.basedElements,
              onEdit: (element) => _openExistingBasedElement(context, element),
              onDelete: (element) => _deleteBasedElement(context, element),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _openNewBasedElement(BuildContext context) async {
    final ready = await controller.prepareNewBasedElement();
    if (ready && context.mounted) showBasedElementEditor(context);
  }

  Future<void> _openExistingBasedElement(
    BuildContext context,
    BasedElementModel element,
  ) async {
    final ready = await controller.prepareExistingBasedElement(element);
    if (ready && context.mounted) showBasedElementEditor(context);
  }

  Future<void> _deleteBasedElement(
    BuildContext context,
    BasedElementModel element,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete based element?',
      message:
          '"${element.elementName}" will be removed from this payroll element.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) await controller.deleteBasedElement(element.id);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: 9),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTextStyles.sectionTitle),
      ],
    );
  }
}

class _BasedElementsTable extends StatelessWidget {
  const _BasedElementsTable({
    required this.elements,
    required this.onEdit,
    required this.onDelete,
  });

  final List<BasedElementModel> elements;
  final ValueChanged<BasedElementModel> onEdit;
  final ValueChanged<BasedElementModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 650.0;

        final tableWidth = constraints.maxWidth > minTableWidth
            ? constraints.maxWidth
            : minTableWidth;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.field),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    height: 42,
                    color: AppColors.tableHeader,
                    child: const Row(
                      children: [
                        SizedBox(width: 100, child: _BasedHeader('Actions')),
                        Expanded(child: _BasedHeader('Element Name')),
                        SizedBox(width: 180, child: _BasedHeader('Type')),
                      ],
                    ),
                  ),

                  ...elements.map(
                    (element) => Container(
                      height: 52,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () => onDelete(element),
                                  tooltip: 'Delete',
                                  color: AppColors.error,
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => onEdit(element),
                                  tooltip: 'Edit',
                                  color: AppColors.primaryDark,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Text(
                                element.elementName,
                                style: AppTextStyles.tableBody,
                              ),
                            ),
                          ),

                          SizedBox(
                            width: 180,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Text(
                                element.type,
                                style: AppTextStyles.tableBody,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BasedHeader extends StatelessWidget {
  const _BasedHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label.toUpperCase(), style: AppTextStyles.tableHeader),
      ),
    );
  }
}

Future<void> showBasedElementEditor(BuildContext context) async {
  await Get.dialog<void>(
    Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.section),
      ),
      child: const SizedBox(width: 520, child: _BasedElementEditor()),
    ),
    barrierDismissible: false,
  );
}

class _BasedElementEditor extends GetView<PayrollElementsController> {
  const _BasedElementEditor();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: controller.basedElementFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => Text(
                      controller.editingBasedElementId.value.isEmpty
                          ? 'Add Based Element'
                          : 'Edit Based Element',
                      style: AppTextStyles.heading(fontSize: 18),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back<void>(),
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Obx(
              () => CustomDropdown(
                key: ValueKey(controller.selectedBasedElementId.value),
                width: double.infinity,
                hintText: 'Element Name',
                textcontroller: controller.basedElementOptionName(
                  controller.selectedBasedElementId.value,
                ),
                showedSelectedName: 'name',
                items: controller.basedElementDropdownItems,
                validator: true,
                onChanged: (key, _) =>
                    controller.selectedBasedElementId.value = key,
                onDelete: () => controller.selectedBasedElementId.value = null,
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
                items: _namedDropdownItems(
                  PayrollElementsController.basedElementTypes,
                ),
                onChanged: (key, _) =>
                    controller.selectedBasedElementType.value = key,
                onDelete: () => controller.selectedBasedElementType.value = '',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Get.back<void>(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Obx(
                  () => FilledButton(
                    onPressed: controller.isSavingBasedElement.value
                        ? null
                        : () async {
                            final saved = await controller.saveBasedElement();
                            if (saved) Get.back<void>();
                          },
                    child: controller.isSavingBasedElement.value
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  return showAppConfirmationDialog(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    destructive: destructive,
  );
}
