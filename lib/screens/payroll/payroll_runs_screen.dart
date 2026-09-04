import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/payroll_runs_controller.dart';
import '../../widgets/drop_down_menu.dart';
import '../../widgets/form_fields/app_text_form_field.dart';
import '../../widgets/payroll_runs/payroll_run_create_dialog.dart';
import '../../widgets/payroll_runs/payroll_run_details_view.dart';
import '../../widgets/payroll_runs/payroll_runs_table.dart';

class PayrollRunsScreen extends GetView<PayrollRunsController> {
  const PayrollRunsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PayrollRunsList();
  }
}

class _PayrollRunsList extends GetView<PayrollRunsController> {
  const _PayrollRunsList();

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
            const _PageHeader(),
            const SizedBox(height: AppSpacing.lg),
            const _SearchToolbar(),
            const SizedBox(height: AppSpacing.md),
            if (phone)
              const SizedBox(height: 500, child: _RunsCard())
            else
              const Expanded(child: _RunsCard()),
          ],
        );
        final padded = Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? AppSpacing.md : AppSpacing.xxl,
            compact ? AppSpacing.md : 30,
            compact ? AppSpacing.md : AppSpacing.xxl,
            AppSpacing.md,
          ),
          child: content,
        );
        return phone ? SingleChildScrollView(child: padded) : padded;
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Payroll Runs',
      textAlign: TextAlign.center,
      style: AppTextStyles.pageHeading,
    );
  }
}

class _SearchToolbar extends GetView<PayrollRunsController> {
  const _SearchToolbar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1080) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 8, child: _RunNumberFilter()),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(flex: 11, child: _PayrollFilter()),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(flex: 12, child: _PeriodFilter()),
                  const SizedBox(width: AppSpacing.sm),
                  _FindButton(),
                  const SizedBox(width: AppSpacing.sm),
                  _ClearButton(),
                  const SizedBox(width: AppSpacing.sm),
                  _NewButton(),
                ],
              );
            }
            final singleColumn = constraints.maxWidth < 560;
            final halfWidth = singleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - AppSpacing.sm) / 2;
            final actionWidth = singleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - (AppSpacing.sm * 2)) / 3;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(width: halfWidth, child: _RunNumberFilter()),
                SizedBox(width: halfWidth, child: _PayrollFilter()),
                SizedBox(width: constraints.maxWidth, child: _PeriodFilter()),
                SizedBox(width: actionWidth, child: const _FindButton()),
                SizedBox(width: actionWidth, child: const _ClearButton()),
                SizedBox(width: actionWidth, child: const _NewButton()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RunNumberFilter extends GetView<PayrollRunsController> {
  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Run Number',
      hintText: 'Search run number',
      controller: controller.runNumberFilter,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (_) => controller.fetchPayrollRuns(),
    );
  }
}

class _PayrollFilter extends GetView<PayrollRunsController> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CustomDropdown(
        key: ValueKey(controller.selectedFilterPayrollId.value),
        width: double.infinity,
        hintText: 'Payroll Name',
        textcontroller: controller.payrollName(
          controller.selectedFilterPayrollId.value,
        ),
        showedSelectedName: 'name',
        items: controller.payrollDropdownItems,
        onOpen: controller.getPayrollsForDropdown,
        onChanged: (key, _) => controller.selectedFilterPayrollId.value = key,
        onDelete: () => controller.selectedFilterPayrollId.value = null,
      ),
    );
  }
}

class _PeriodFilter extends GetView<PayrollRunsController> {
  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Period Name',
      hintText: 'Search period',
      controller: controller.periodNameFilter,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (_) => controller.fetchPayrollRuns(),
    );
  }
}

class _FindButton extends GetView<PayrollRunsController> {
  const _FindButton();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: AppSizes.inputMinHeight,
        child: FilledButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.fetchPayrollRuns,
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

class _ClearButton extends GetView<PayrollRunsController> {
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

class _NewButton extends GetView<PayrollRunsController> {
  const _NewButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.inputMinHeight,
      child: FilledButton.icon(
        onPressed: () async {
          final ready = await controller.prepareNewRun();
          if (ready && context.mounted) showPayrollRunCreateDialog(context);
        },
        label: const Text('New Payroll'),
      ),
    );
  }
}

class _RunsCard extends GetView<PayrollRunsController> {
  const _RunsCard();

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
                          text: '${controller.filteredRuns.length}',
                          style: AppTextStyles.listCount.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: controller.filteredRuns.length == 1
                              ? ' payroll run'
                              : ' payroll runs',
                        ),
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
                      : (rowArea / AppSizes.payrollRunsTableRowHeight)
                            .floor()
                            .clamp(1, 1000)
                            .toInt();
                  controller.schedulePageSize(rows);
                  return Obx(() {
                    if (controller.isLoading.value &&
                        controller.allRuns.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final error = controller.listError.value;
                    if (error != null && controller.allRuns.isEmpty) {
                      return _ListMessage(
                        icon: Icons.cloud_off_rounded,
                        message: error,
                        actionLabel: 'Try again',
                        onAction: controller.fetchPayrollRuns,
                      );
                    }
                    if (controller.filteredRuns.isEmpty) {
                      return const _ListMessage(
                        icon: Icons.payments_outlined,
                        message: 'No payroll runs match these filters.',
                      );
                    }
                    return PayrollRunsTable(
                      runs: controller.visibleRuns,
                      onOpen: (run) async {
                        final opened = await controller.openRunDetails(run);
                        if (!opened || !context.mounted) return;
                        await showPayrollRunDetailsDialog(context);
                        controller.clearRunDetails();
                      },
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
}

class _TablePager extends GetView<PayrollRunsController> {
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
                'Rows ${controller.rowStart}-${controller.rowEnd} of ${controller.filteredRuns.length}',
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
