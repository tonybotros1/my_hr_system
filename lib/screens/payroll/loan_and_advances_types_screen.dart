import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/loan_and_advances_types_controller.dart';
import '../../models/payroll/loan_advance_type_model.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';
import '../../widgets/drop_down_menu.dart';
import '../../widgets/form_fields/app_text_form_field.dart';
import '../../widgets/loan_and_advances_types/loan_advance_type_editor_dialog.dart';
import '../../widgets/loan_and_advances_types/loan_advance_types_table.dart';

class LoanAndAdvancesTypesScreen
    extends GetView<LoanAndAdvancesTypesController> {
  const LoanAndAdvancesTypesScreen({super.key});

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
              const SizedBox(height: 500, child: _TypesCard())
            else
              const Expanded(child: _TypesCard()),
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

class _PageHeader extends GetView<LoanAndAdvancesTypesController> {
  const _PageHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      'Loan and Advances Types',
      style: AppTextStyles.pageHeading,
    );
    final button = FilledButton.icon(
      onPressed: () async {
        final ready = await controller.prepareNewType();
        if (ready && context.mounted) showLoanAdvanceTypeEditor(context);
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

class _SearchToolbar extends GetView<LoanAndAdvancesTypesController> {
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

class _NameFilter extends GetView<LoanAndAdvancesTypesController> {
  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Name',
      hintText: 'Search by name',
      controller: controller.nameFilter,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (_) => controller.fetchLoanAdvanceTypes(),
    );
  }
}

class _CodeFilter extends GetView<LoanAndAdvancesTypesController> {
  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Code',
      hintText: 'Search by code',
      controller: controller.codeFilter,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (_) => controller.fetchLoanAdvanceTypes(),
      textCapitalization: TextCapitalization.characters,
    );
  }
}

class _BasedElementFilter extends GetView<LoanAndAdvancesTypesController> {
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
        onOpen: controller.getPayrollElementsForDropdown,
        onChanged: (key, _) =>
            controller.selectedFilterBasedElementId.value = key,
        onDelete: () => controller.selectedFilterBasedElementId.value = null,
      ),
    );
  }
}

class _FindButton extends GetView<LoanAndAdvancesTypesController> {
  const _FindButton();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: AppSizes.inputMinHeight,
        child: FilledButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.fetchLoanAdvanceTypes,
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

class _ClearButton extends GetView<LoanAndAdvancesTypesController> {
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

class _TypesCard extends GetView<LoanAndAdvancesTypesController> {
  const _TypesCard();

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
                          text: '${controller.loanAdvanceTypes.length}',
                          style: AppTextStyles.listCount.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(text: ' loan / advance types'),
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
                  final rowArea =
                      constraints.maxHeight - AppSizes.payrollTableHeaderHeight;
                  final rows = rowArea <= 0
                      ? 1
                      : (rowArea / AppSizes.loanAdvanceTypesTableRowHeight)
                            .floor()
                            .clamp(1, 1000)
                            .toInt();
                  controller.schedulePageSize(rows);
                  return Obx(() {
                    if (controller.isLoading.value &&
                        controller.loanAdvanceTypes.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final error = controller.listError.value;
                    if (error != null && controller.loanAdvanceTypes.isEmpty) {
                      return _ListMessage(
                        icon: Icons.cloud_off_rounded,
                        message: error,
                        actionLabel: 'Try again',
                        onAction: controller.fetchLoanAdvanceTypes,
                      );
                    }
                    if (controller.loanAdvanceTypes.isEmpty) {
                      return const _ListMessage(
                        icon: Icons.account_balance_wallet_outlined,
                        message:
                            'No loan or advance types match these filters.',
                      );
                    }
                    return LoanAdvanceTypesTable(
                      types: controller.visibleTypes,
                      onEdit: (type) => _editType(context, type),
                      onDelete: (type) => _deleteType(context, type),
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

  Future<void> _editType(
    BuildContext context,
    LoanAdvanceTypeModel type,
  ) async {
    final ready = await controller.prepareExistingType(type);
    if (ready && context.mounted) showLoanAdvanceTypeEditor(context);
  }

  Future<void> _deleteType(
    BuildContext context,
    LoanAdvanceTypeModel type,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete loan / advance type?',
      message: '"${type.name}" will be permanently deleted.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) await controller.deleteType(type.id);
  }
}

class _TablePager extends GetView<LoanAndAdvancesTypesController> {
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
                'Rows ${controller.rowStart}-${controller.rowEnd} of ${controller.loanAdvanceTypes.length}',
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
