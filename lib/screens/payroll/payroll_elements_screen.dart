import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/payroll_elements_controller.dart';
import '../../models/payroll/payroll_element_model.dart';
import '../../widgets/form_fields/app_text_form_field.dart';
import '../../widgets/payroll_elements/payroll_element_editor_dialog.dart';
import '../../widgets/payroll_elements/payroll_elements_table.dart';

class PayrollElementsScreen extends GetView<PayrollElementsController> {
  const PayrollElementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < AppSizes.payrollCompactBreakpoint;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? AppSpacing.md : AppSpacing.xxl,
            compact ? AppSpacing.md : 30,
            compact ? AppSpacing.md : AppSpacing.xxl,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PageHeader(compact: compact),
              const SizedBox(height: AppSpacing.lg),
              const _SearchToolbar(),
              const SizedBox(height: AppSpacing.sm),
              const Expanded(child: _ElementsCard()),
            ],
          ),
        );
      },
    );
  }
}

class _PageHeader extends GetView<PayrollElementsController> {
  const _PageHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final title = Text('Payroll Elements', style: AppTextStyles.pageHeading);
    final button = FilledButton.icon(
      onPressed: () {
        controller.prepareNewElement();
        showPayrollElementEditor(context);
      },
      icon: const Icon(Icons.add_rounded, size: 19),
      label: const Text('New Element'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(142, AppSizes.payrollActionHeight),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: AppSpacing.md),
          button,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        button,
      ],
    );
  }
}

class _SearchToolbar extends GetView<PayrollElementsController> {
  const _SearchToolbar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 680;
            final fieldWidth = stacked
                ? constraints.maxWidth
                : (constraints.maxWidth - 288) / 2;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: AppTextFormField(
                    label: 'Key',
                    hintText: 'Search by element key',
                    controller: controller.keyFilter,
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (_) => controller.fetchElements(),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: AppTextFormField(
                    label: 'Name',
                    hintText: 'Search by element name',
                    controller: controller.nameFilter,
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (_) => controller.fetchElements(),
                  ),
                ),
                Obx(
                  () => SizedBox(
                    width: stacked
                        ? (constraints.maxWidth - AppSpacing.sm) / 2
                        : 126,
                    height: AppSizes.payrollActionHeight,
                    child: FilledButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.fetchElements,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.primaryDark,
                        elevation: 0,
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Find'),
                    ),
                  ),
                ),
                SizedBox(
                  width: stacked
                      ? (constraints.maxWidth - AppSpacing.sm) / 2
                      : 126,
                  height: AppSizes.payrollActionHeight,
                  child: OutlinedButton(
                    onPressed: controller.clearFilters,
                    child: const Text('Clear'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ElementsCard extends GetView<PayrollElementsController> {
  const _ElementsCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.section),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 630;
                  final segments = const _TypeSegments();
                  final count = Obx(
                    () => Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${controller.elements.length}',
                            style: AppTextStyles.listCount.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(text: ' elements shown'),
                        ],
                      ),
                      style: AppTextStyles.listCount,
                    ),
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: segments,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        count,
                      ],
                    );
                  }
                  return Row(children: [segments, const Spacer(), count]);
                },
              ),
            ),
            const Divider(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final rowArea =
                      constraints.maxHeight - AppSizes.payrollTableHeaderHeight;
                  final rows = rowArea <= 0
                      ? 1
                      : (rowArea / AppSizes.payrollTableRowHeight)
                            .floor()
                            .clamp(1, 1000)
                            .toInt();
                  controller.schedulePageSize(rows);

                  return Obx(() {
                    if (controller.isLoading.value &&
                        controller.elements.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final error = controller.listError.value;
                    if (error != null && controller.elements.isEmpty) {
                      return _ListMessage(
                        icon: Icons.cloud_off_rounded,
                        message: error,
                        actionLabel: 'Try again',
                        onAction: controller.fetchElements,
                      );
                    }
                    if (controller.elements.isEmpty) {
                      return const _ListMessage(
                        icon: Icons.payments_outlined,
                        message: 'No payroll elements match these filters.',
                      );
                    }
                    return PayrollElementsTable(
                      elements: controller.visibleElements,
                      onEdit: (element) => _editElement(context, element),
                      onDelete: (element) => _deleteElement(context, element),
                    );
                  });
                },
              ),
            ),
            const Divider(),
            const _TablePager(),
          ],
        ),
      ),
    );
  }

  Future<void> _editElement(
    BuildContext context,
    PayrollElementModel element,
  ) async {
    final opened = await controller.loadElement(element.id);
    if (opened && context.mounted) showPayrollElementEditor(context);
  }

  Future<void> _deleteElement(
    BuildContext context,
    PayrollElementModel element,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete payroll element?',
      message: '"${element.name}" will be permanently deleted.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) await controller.deleteElement(element.id);
  }
}

class _TypeSegments extends GetView<PayrollElementsController> {
  const _TypeSegments();

  static const values = ['All', 'Earning', 'Deduction', 'Information'];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.segmentBackground,
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: values
                .map((value) {
                  final selected = controller.selectedListType.value == value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: TextButton(
                      onPressed: () => controller.selectListType(value),
                      style: TextButton.styleFrom(
                        backgroundColor: selected
                            ? AppColors.surface
                            : Colors.transparent,
                        foregroundColor: selected
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: AppTextStyles.segment,
                      ),
                      child: Text(value),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _TablePager extends GetView<PayrollElementsController> {
  const _TablePager();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Rows ${controller.rowStart}-${controller.rowEnd} of ${controller.elements.length}',
                style: AppTextStyles.listCount,
              ),
            ),
            _PagerButton(
              tooltip: 'Previous page',
              icon: Icons.chevron_left_rounded,
              onPressed: controller.canGoPrevious
                  ? controller.previousPage
                  : null,
            ),
            const SizedBox(width: AppSpacing.xs),
            _PagerButton(
              tooltip: 'Next page',
              icon: Icons.chevron_right_rounded,
              onPressed: controller.canGoNext ? controller.nextPage : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(34),
        maximumSize: const Size.square(34),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _ListMessage extends StatelessWidget {
  const _ListMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.iconMuted, size: 36),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
