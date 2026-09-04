import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/payroll_controller.dart';
import '../../models/payroll/payroll_model.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';
import '../../widgets/drop_down_menu.dart';
import '../../widgets/form_fields/app_text_form_field.dart';
import '../../widgets/payroll/payroll_editor_dialog.dart';
import '../../widgets/payroll/payroll_table.dart';

class PayrollScreen extends GetView<PayrollController> {
  const PayrollScreen({super.key});

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
              const SizedBox(height: 500, child: _PayrollCard())
            else
              const Expanded(child: _PayrollCard()),
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

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Payroll',
      textAlign: TextAlign.center,
      style: AppTextStyles.pageHeading,
    );
  }
}

class _SearchToolbar extends GetView<PayrollController> {
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
                  Expanded(flex: 11, child: _NameFilter()),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(flex: 11, child: _PaymentTypeFilter()),
                  const SizedBox(width: AppSpacing.sm),
                  _FindButton(),
                  const SizedBox(width: AppSpacing.sm),
                  _ClearButton(),
                  const SizedBox(width: AppSpacing.sm),
                  _NewButton(),
                ],
              );
            }

            final singleColumn = constraints.maxWidth < 500;
            final width = singleColumn
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
                SizedBox(width: width, child: _NameFilter()),
                SizedBox(width: width, child: _PaymentTypeFilter()),
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

class _NameFilter extends GetView<PayrollController> {
  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Name',
      hintText: 'Search by payroll name',
      controller: controller.nameFilter,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (_) => controller.findPayrolls(),
    );
  }
}

class _PaymentTypeFilter extends GetView<PayrollController> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CustomDropdown(
        key: ValueKey(controller.selectedFilterPaymentTypeId.value),
        width: double.infinity,
        hintText: 'Payment Type',
        textcontroller: controller.selectedFilterPaymentTypeName.value ?? '',
        showedSelectedName: 'type',
        items: controller.paymentTypeDropdownItems,
        onOpen: controller.getPaymentTypesForDropdown,
        onChanged: (key, value) {
          controller.selectedFilterPaymentTypeId.value = key;
          controller.selectedFilterPaymentTypeName.value =
              value['type']?.toString() ?? '';
        },
        onDelete: () {
          controller.selectedFilterPaymentTypeId.value = null;
          controller.selectedFilterPaymentTypeName.value = null;
        },
      ),
    );
  }
}

class _FindButton extends GetView<PayrollController> {
  const _FindButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.inputMinHeight,
      child: FilledButton(
        onPressed: controller.findPayrolls,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primaryDark,
          elevation: 0,
        ),
        child: const Text('Find'),
      ),
    );
  }
}

class _ClearButton extends GetView<PayrollController> {
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

class _NewButton extends GetView<PayrollController> {
  const _NewButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.inputMinHeight,
      child: FilledButton.icon(
        onPressed: () async {
          final ready = await controller.prepareNewPayroll();
          if (ready && context.mounted) await showPayrollEditor(context);
        },
        label: const Text('New Payroll'),
      ),
    );
  }
}

class _PayrollCard extends GetView<PayrollController> {
  const _PayrollCard();

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
                          text: '${controller.payrolls.length}',
                          style: AppTextStyles.listCount.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(text: ' payroll definitions'),
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
                      : (rowArea / AppSizes.payrollTableRowHeight)
                            .floor()
                            .clamp(1, 1000)
                            .toInt();
                  controller.schedulePageSize(rows);
                  return Obx(() {
                    if (controller.isLoading.value &&
                        controller.payrolls.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final error = controller.listError.value;
                    if (error != null && controller.payrolls.isEmpty) {
                      return _ListMessage(
                        icon: Icons.cloud_off_rounded,
                        message: error,
                        actionLabel: 'Try again',
                        onAction: controller.fetchPayrolls,
                      );
                    }
                    if (controller.payrolls.isEmpty) {
                      return const _ListMessage(
                        icon: Icons.payments_outlined,
                        message: 'No payroll definitions match these filters.',
                      );
                    }
                    return PayrollTable(
                      payrolls: controller.visiblePayrolls,
                      onEdit: (payroll) => _editPayroll(context, payroll),
                      onDelete: (payroll) => _deletePayroll(context, payroll),
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

  Future<void> _editPayroll(BuildContext context, PayrollModel payroll) async {
    final ready = await controller.prepareExistingPayroll(payroll);
    if (ready && context.mounted) await showPayrollEditor(context);
  }

  Future<void> _deletePayroll(
    BuildContext context,
    PayrollModel payroll,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete payroll?',
      message:
          '"${payroll.name}" and all its periods will be permanently deleted.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) await controller.deletePayroll(payroll.id);
  }
}

class _TablePager extends GetView<PayrollController> {
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
                'Rows ${controller.rowStart}-${controller.rowEnd} of ${controller.payrolls.length}',
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
