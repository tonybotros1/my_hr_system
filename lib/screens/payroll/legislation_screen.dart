import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/legislation_controller.dart';
import '../../models/payroll/legislation_model.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';
import '../../widgets/form_fields/app_text_form_field.dart';
import '../../widgets/legislation/legislation_editor_dialog.dart';
import '../../widgets/legislation/legislation_table.dart';

class LegislationScreen extends GetView<LegislationController> {
  const LegislationScreen({super.key});

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
              const _PageHeader(),
              const SizedBox(height: AppSpacing.lg),
              const _FilterCard(),
              const SizedBox(height: AppSpacing.md),
              const Expanded(child: _LegislationListCard()),
            ],
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Legislation',
      textAlign: TextAlign.center,
      style: AppTextStyles.pageHeading,
    );
  }
}

class _FilterCard extends GetView<LegislationController> {
  const _FilterCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 720) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(child: _NameFilter()),
                  const SizedBox(width: AppSpacing.sm),
                  _FindButton(),
                  const SizedBox(width: AppSpacing.sm),
                  _ClearButton(),
                  const SizedBox(width: AppSpacing.sm),
                  _NewButton(),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _NameFilter(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _FindButton(),
                    const SizedBox(width: AppSpacing.sm),
                    _ClearButton(),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const _NewButton(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NameFilter extends GetView<LegislationController> {
  const _NameFilter();

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Name',
      hintText: 'Search by legislation name',
      controller: controller.nameFilter,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (_) => controller.fetchLegislations(),
    );
  }
}

class _FindButton extends GetView<LegislationController> {
  const _FindButton();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: AppSizes.inputMinHeight,
        child: FilledButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.fetchLegislations,
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

class _ClearButton extends GetView<LegislationController> {
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

class _NewButton extends GetView<LegislationController> {
  const _NewButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.inputMinHeight,
      child: FilledButton.icon(
        onPressed: () {
          controller.prepareNewLegislation();
          showLegislationEditorDialog(context);
        },
        label: const Text('New Legislation'),
      ),
    );
  }
}

class _LegislationListCard extends GetView<LegislationController> {
  const _LegislationListCard();

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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Obx(
                  () => Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${controller.legislations.length}',
                          style: AppTextStyles.listCount.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(text: ' legislations'),
                      ],
                    ),
                    style: AppTextStyles.listCount,
                  ),
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableRows =
                      constraints.maxHeight - AppSizes.payrollTableHeaderHeight;
                  final rows = availableRows <= 0
                      ? 1
                      : (availableRows / AppSizes.legislationTableRowHeight)
                            .floor()
                            .clamp(1, 1000)
                            .toInt();
                  controller.schedulePageSize(rows);
                  return Obx(() {
                    if (controller.isLoading.value &&
                        controller.legislations.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final error = controller.listError.value;
                    if (error != null && controller.legislations.isEmpty) {
                      return _ListMessage(
                        icon: Icons.cloud_off_rounded,
                        message: error,
                        actionLabel: 'Try again',
                        onAction: controller.fetchLegislations,
                      );
                    }
                    if (controller.legislations.isEmpty) {
                      return const _ListMessage(
                        icon: Icons.policy_outlined,
                        message: 'No legislations match these filters.',
                      );
                    }
                    return LegislationTable(
                      legislations: controller.visibleLegislations,
                      onEdit: (legislation) => _edit(context, legislation),
                      onDelete: (legislation) => _delete(context, legislation),
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

  void _edit(BuildContext context, LegislationModel legislation) {
    controller.prepareExistingLegislation(legislation);
    showLegislationEditorDialog(context);
  }

  Future<void> _delete(
    BuildContext context,
    LegislationModel legislation,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete legislation?',
      message: '"${legislation.name}" will be permanently deleted.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) await controller.deleteLegislation(legislation);
  }
}

class _TablePager extends GetView<LegislationController> {
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
                'Rows ${controller.rowStart}-${controller.rowEnd} of ${controller.legislations.length}',
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
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 34,
        child: IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.field),
            ),
          ),
          icon: Icon(icon, size: 19),
        ),
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
            Icon(icon, color: AppColors.iconMuted, size: 34),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
