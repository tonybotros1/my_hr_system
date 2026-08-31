import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/leave_types_controller.dart';
import '../../models/payroll/leave_type_model.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';
import '../../widgets/drop_down_menu.dart';
import '../../widgets/form_fields/app_text_form_field.dart';
import '../../widgets/leave_types/leave_type_editor_dialog.dart';
import '../../widgets/leave_types/leave_types_table.dart';

class LeaveTypesScreen extends GetView<LeaveTypesController> {
  const LeaveTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < AppSizes.payrollCompactBreakpoint;
        final phone = constraints.maxWidth < 560;
        final content = Column(
          mainAxisSize: phone ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PageHeader(compact: compact),
            const SizedBox(height: AppSpacing.lg),
            const _SearchToolbar(),
            const SizedBox(height: AppSpacing.md),
            if (phone)
              const SizedBox(height: 500, child: _LeaveTypesCard())
            else
              const Expanded(child: _LeaveTypesCard()),
          ],
        );
        final paddedContent = Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? AppSpacing.md : AppSpacing.xxl,
            compact ? AppSpacing.md : 30,
            compact ? AppSpacing.md : AppSpacing.xxl,
            AppSpacing.md,
          ),
          child: content,
        );
        return phone
            ? SingleChildScrollView(child: paddedContent)
            : paddedContent;
      },
    );
  }
}

class _PageHeader extends GetView<LeaveTypesController> {
  const _PageHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final title = Text('Leave Types', style: AppTextStyles.pageHeading);
    final button = FilledButton.icon(
      onPressed: () async {
        final ready = await controller.prepareNewLeaveType();
        if (ready && context.mounted) showLeaveTypeEditor(context);
      },
      icon: const Icon(Icons.add_rounded, size: 19),
      label: const Text('New Type'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(132, AppSizes.payrollActionHeight),
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

class _SearchToolbar extends GetView<LeaveTypesController> {
  const _SearchToolbar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 10, child: _NameFilter()),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(flex: 8, child: _CodeFilter()),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(flex: 12, child: _BasedElementFilter()),
                  const SizedBox(width: AppSpacing.sm),
                  const SizedBox(width: 94, child: _FindButton()),
                  const SizedBox(width: AppSpacing.sm),
                  const SizedBox(width: 94, child: _ClearButton()),
                ],
              );
            }

            final singleColumn = constraints.maxWidth < 560;
            final fieldWidth = singleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - AppSpacing.sm) / 2;
            final buttonWidth = singleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - AppSpacing.sm) / 2;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(width: fieldWidth, child: _NameFilter()),
                SizedBox(width: fieldWidth, child: _CodeFilter()),
                SizedBox(
                  width: constraints.maxWidth,
                  child: _BasedElementFilter(),
                ),
                SizedBox(width: buttonWidth, child: const _FindButton()),
                SizedBox(width: buttonWidth, child: const _ClearButton()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NameFilter extends GetView<LeaveTypesController> {
  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Name',
      hintText: 'Search by name',
      controller: controller.nameFilter,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (_) => controller.fetchLeaveTypes(),
    );
  }
}

class _CodeFilter extends GetView<LeaveTypesController> {
  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Code',
      hintText: 'Search by code',
      controller: controller.codeFilter,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (_) => controller.fetchLeaveTypes(),
      textCapitalization: TextCapitalization.characters,
    );
  }
}

class _BasedElementFilter extends GetView<LeaveTypesController> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CustomDropdown(
        key: ValueKey(controller.selectedFilterBasedElementId.value),
        width: double.infinity,
        hintText: 'Based Element',
        textcontroller: controller.payrollElementName(
          controller.selectedFilterBasedElementId.value,
        ),
        showedSelectedName: 'name',
        items: controller.payrollElementDropdownItems,
        onOpen: controller.getLeavePayrollElementsForDropdown,
        onChanged: (key, _) =>
            controller.selectedFilterBasedElementId.value = key,
        onDelete: () => controller.selectedFilterBasedElementId.value = null,
      ),
    );
  }
}

class _FindButton extends GetView<LeaveTypesController> {
  const _FindButton();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: AppSizes.inputMinHeight,
        child: FilledButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.fetchLeaveTypes,
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
    );
  }
}

class _ClearButton extends GetView<LeaveTypesController> {
  const _ClearButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.inputMinHeight,
      child: OutlinedButton(
        onPressed: controller.clearFilters,
        child: const Text('Clear'),
      ),
    );
  }
}

class _LeaveTypesCard extends GetView<LeaveTypesController> {
  const _LeaveTypesCard();

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
                  final compact = constraints.maxWidth < 560;
                  final segments = const _DayTypeSegments();
                  final count = Obx(
                    () => Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${controller.leaveTypes.length}',
                            style: AppTextStyles.listCount.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(text: ' leave types'),
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
                      : (rowArea / AppSizes.leaveTypesTableRowHeight)
                            .floor()
                            .clamp(1, 1000)
                            .toInt();
                  controller.schedulePageSize(rows);
                  return Obx(() {
                    if (controller.isLoading.value &&
                        controller.leaveTypes.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final error = controller.listError.value;
                    if (error != null && controller.leaveTypes.isEmpty) {
                      return _ListMessage(
                        icon: Icons.cloud_off_rounded,
                        message: error,
                        actionLabel: 'Try again',
                        onAction: controller.fetchLeaveTypes,
                      );
                    }
                    if (controller.leaveTypes.isEmpty) {
                      return const _ListMessage(
                        icon: Icons.event_busy_outlined,
                        message: 'No leave types match these filters.',
                      );
                    }
                    return LeaveTypesTable(
                      leaveTypes: controller.visibleLeaveTypes,
                      onEdit: (leaveType) => _editLeaveType(context, leaveType),
                      onDelete: (leaveType) =>
                          _deleteLeaveType(context, leaveType),
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

  Future<void> _editLeaveType(
    BuildContext context,
    LeaveTypeModel leaveType,
  ) async {
    final ready = await controller.prepareExistingLeaveType(leaveType);
    if (ready && context.mounted) showLeaveTypeEditor(context);
  }

  Future<void> _deleteLeaveType(
    BuildContext context,
    LeaveTypeModel leaveType,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete leave type?',
      message: '"${leaveType.name}" will be permanently deleted.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) await controller.deleteLeaveType(leaveType.id);
  }
}

class _DayTypeSegments extends GetView<LeaveTypesController> {
  const _DayTypeSegments();

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
            children: LeaveTypesController.listTypes
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

class _TablePager extends GetView<LeaveTypesController> {
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
                'Rows ${controller.rowStart}-${controller.rowEnd} of ${controller.leaveTypes.length}',
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
