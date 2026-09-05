import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/payroll_runs_controller.dart';
import '../../models/payroll/payroll_run_model.dart';
import '../dialogs/app_alert_dialog.dart';
import 'payroll_run_recipients_dialog.dart';

Future<void> showPayrollRunDetailsDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: 'Payroll run details',
    barrierColor: AppColors.dialogScrim,
    transitionDuration: AppDurations.normal,
    pageBuilder: (dialogContext, _, _) {
      final compact =
          MediaQuery.sizeOf(dialogContext).width <
          AppSizes.payrollCompactBreakpoint;
      return Dialog(
        insetPadding: EdgeInsets.all(compact ? AppSpacing.xs : AppSpacing.md),
        backgroundColor: AppColors.background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            compact ? AppRadii.section : AppRadii.editor,
          ),
        ),
        child: SizedBox.expand(
          child: PayrollRunDetailsView(
            onClose: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(),
          ),
        ),
      );
    },
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class PayrollRunDetailsView extends GetView<PayrollRunsController> {
  const PayrollRunDetailsView({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final run = controller.selectedDetails.value;
      if (run == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < AppSizes.payrollCompactBreakpoint;
          final wide = constraints.maxWidth >= 1080;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? AppSpacing.md : AppSpacing.xxl,
              compact ? AppSpacing.md : AppSpacing.lg,
              compact ? AppSpacing.md : AppSpacing.xxl,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailsHeader(run: run, onClose: onClose),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Expanded(flex: 3, child: _EmployeesPanel()),
                            const SizedBox(width: AppSpacing.md),
                            const Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Expanded(child: _ElementsPanel()),
                                  SizedBox(height: AppSpacing.md),
                                  Expanded(child: _BalancesPanel()),
                                ],
                              ),
                            ),
                          ],
                        )
                      : const SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: 520, child: _EmployeesPanel()),
                              SizedBox(height: AppSpacing.md),
                              SizedBox(height: 410, child: _ElementsPanel()),
                              SizedBox(height: AppSpacing.md),
                              SizedBox(height: 330, child: _BalancesPanel()),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _DetailsHeader extends GetView<PayrollRunsController> {
  const _DetailsHeader({required this.run, required this.onClose});

  final PayrollRunDetails run;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = Obx(
          () => Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: controller.isExporting.value
                    ? null
                    : controller.exportBankPayments,
                child: controller.isExporting.value
                    ? const _SmallLoader()
                    : const Text('Bank Export'),
              ),
              TextButton(
                onPressed: controller.isEmailing.value
                    ? null
                    : showPayrollRunRecipientsDialog,
                child: controller.isEmailing.value
                    ? const _SmallLoader()
                    : const Text('Email Payslips'),
              ),
              TextButton(
                onPressed: controller.isRollingBack.value
                    ? null
                    : () async {
                        final confirmed = await showAppConfirmationDialog(
                          context,
                          title: 'Rollback payroll run?',
                          message:
                              'Run ${run.runNumber} and all generated employee results will be permanently removed.',
                          confirmLabel: 'Rollback',
                          destructive: true,
                        );
                        if (!confirmed) return;
                        final rolledBack = await controller
                            .rollbackCurrentRun();
                        if (rolledBack && context.mounted) onClose();
                      },
                style: TextButton.styleFrom(foregroundColor: AppColors.warning),
                child: controller.isRollingBack.value
                    ? const _SmallLoader(color: AppColors.warning)
                    : const Text('Rollback'),
              ),
              TextButton(
                onPressed: onClose,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payroll Run ${run.runNumber}',
              style: AppTextStyles.pageHeading,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _MetaChip(label: run.payrollName),
                _MetaChip(label: run.periodName),
                _MetaChip(
                  label: run.description.isEmpty
                      ? 'All Employees'
                      : run.description,
                ),
                if (run.paymentNumber.isNotEmpty)
                  _MetaChip(label: run.paymentNumber),
              ],
            ),
          ],
        );
        if (constraints.maxWidth < 820) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: AppSpacing.sm),
              Align(alignment: Alignment.centerLeft, child: actions),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: AppSpacing.md),
            actions,
          ],
        );
      },
    );
  }
}

class _EmployeesPanel extends GetView<PayrollRunsController> {
  const _EmployeesPanel();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => _PanelCard(
        title: 'Employees',
        search: _PanelSearchField(
          controller: controller.employeeSearch,
          hint: 'Search employees',
          onChanged: controller.updateEmployeeSearch,
          onClear: () {
            controller.employeeSearch.clear();
            controller.updateEmployeeSearch('');
          },
        ),
        footer: Text(
          '${controller.visibleEmployees.length} employees shown',
          style: AppTextStyles.listCount,
        ),
        child: _EmployeesTable(
          employees: controller.visibleEmployees,
          selectedEmployeeId: controller.selectedEmployee.value?.id ?? '',
          printingEmployeeId: controller.printingEmployeeId.value,
          onSelect: controller.selectRunEmployee,
          onPrint: controller.printPayslip,
        ),
      ),
    );
  }
}

class _ElementsPanel extends GetView<PayrollRunsController> {
  const _ElementsPanel();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => _PanelCard(
        title: 'Payroll Elements',
        search: _PanelSearchField(
          controller: controller.elementSearch,
          hint: 'Search elements',
          onChanged: controller.updateElementSearch,
          onClear: () {
            controller.elementSearch.clear();
            controller.updateElementSearch('');
          },
        ),
        child: _ElementsTable(elements: controller.visibleElements),
      ),
    );
  }
}

class _BalancesPanel extends GetView<PayrollRunsController> {
  const _BalancesPanel();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => _PanelCard(
        title: 'Information',
        subtitle:
            controller.selectedEmployee.value?.employeeName ??
            'Select an employee',
        child: _BalancesTable(elements: controller.visibleInformationElements),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.search,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final Widget? search;
  final Widget? footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.section),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final heading = Row(
                    children: [
                      Text(title, style: AppTextStyles.heading(fontSize: 15)),
                      if (subtitle != null) ...[
                        const Spacer(),
                        Flexible(
                          child: Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.listCount,
                          ),
                        ),
                      ],
                    ],
                  );
                  if (search == null) return heading;
                  if (constraints.maxWidth < 520) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        heading,
                        const SizedBox(height: AppSpacing.sm),
                        search!,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: heading),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(width: 285, child: search),
                    ],
                  );
                },
              ),
            ),
            const Divider(),
            Expanded(child: child),
            if (footer != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Align(alignment: Alignment.centerLeft, child: footer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PanelSearchField extends StatelessWidget {
  const _PanelSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.inputMinHeight,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.input,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          suffixIcon: IconButton(
            onPressed: onClear,
            tooltip: 'Clear search',
            icon: const Icon(Icons.close_rounded, size: 17),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _EmployeesTable extends StatefulWidget {
  const _EmployeesTable({
    required this.employees,
    required this.selectedEmployeeId,
    required this.printingEmployeeId,
    required this.onSelect,
    required this.onPrint,
  });

  final List<PayrollRunEmployee> employees;
  final String selectedEmployeeId;
  final String printingEmployeeId;
  final ValueChanged<PayrollRunEmployee> onSelect;
  final ValueChanged<PayrollRunEmployee> onPrint;

  @override
  State<_EmployeesTable> createState() => _EmployeesTableState();
}

class _EmployeesTableState extends State<_EmployeesTable> {
  final _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = mathMax(
          constraints.maxWidth,
          AppSizes.payrollRunEmployeesTableMinWidth,
        );
        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: width > constraints.maxWidth,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  const _EmployeeHeader(),
                  Expanded(
                    child: widget.employees.isEmpty
                        ? const _EmptyPanel(message: 'No employees found.')
                        : ListView.builder(
                            itemCount: widget.employees.length,
                            itemExtent: AppSizes.payrollRunDetailsRowHeight,
                            itemBuilder: (context, index) {
                              final employee = widget.employees[index];
                              return _EmployeeRow(
                                employee: employee,
                                selected:
                                    employee.id == widget.selectedEmployeeId,
                                printing:
                                    employee.employeeId ==
                                    widget.printingEmployeeId,
                                onSelect: () => widget.onSelect(employee),
                                onPrint: () => widget.onPrint(employee),
                              );
                            },
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

class _EmployeeHeader extends StatelessWidget {
  const _EmployeeHeader();

  @override
  Widget build(BuildContext context) {
    return const _TableHeaderRow(
      cells: [
        _TableCellSpec('Payslip', 76),
        _TableCellSpec('Employee Name', 0, flex: 3),
        _TableCellSpec('Payment', 130),
        _TableCellSpec('Deduction', 130),
        _TableCellSpec('Net', 130),
      ],
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({
    required this.employee,
    required this.selected,
    required this.printing,
    required this.onSelect,
    required this.onPrint,
  });

  final PayrollRunEmployee employee;
  final bool selected;
  final bool printing;
  final VoidCallback onSelect;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.surface,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Center(
                  child: IconButton.outlined(
                    onPressed: printing ? null : onPrint,
                    tooltip: 'Print payslip',
                    icon: printing
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.receipt_long_outlined, size: 17),
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(34),
                      maximumSize: const Size.square(34),
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              _DataCell(employee.employeeName, flex: 3, emphasized: true),
              _MoneyCell(employee.totalPayments, color: AppColors.success),
              _MoneyCell(employee.totalDeductions, color: AppColors.error),
              _MoneyCell(employee.netSalary, color: const Color(0xFF3A79B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ElementsTable extends StatelessWidget {
  const _ElementsTable({required this.elements});

  final List<PayrollRunElement> elements;

  @override
  Widget build(BuildContext context) {
    return _SimpleScrollableTable(
      minWidth: AppSizes.payrollRunElementsTableMinWidth,
      header: const _TableHeaderRow(
        cells: [
          _TableCellSpec('Element Name', 0, flex: 3),
          _TableCellSpec('Payment', 130),
          _TableCellSpec('Deduction', 130),
        ],
      ),
      rows: elements
          .map(
            (element) => Row(
              children: [
                _DataCell(element.name, flex: 3),
                _MoneyCell(element.payment, color: AppColors.success),
                _MoneyCell(element.deduction, color: AppColors.error),
              ],
            ),
          )
          .toList(growable: false),
      emptyMessage: 'Select an employee to view payroll elements.',
    );
  }
}

class _BalancesTable extends StatelessWidget {
  const _BalancesTable({required this.elements});

  final List<PayrollRunElement> elements;

  @override
  Widget build(BuildContext context) {
    return _SimpleScrollableTable(
      minWidth: AppSizes.payrollRunBalancesTableMinWidth,
      header: const _TableHeaderRow(
        cells: [
          _TableCellSpec('Element Name', 0, flex: 3),
          _TableCellSpec('Number', 110),
          _TableCellSpec('Value', 120),
        ],
      ),
      rows: elements
          .map(
            (element) => Row(
              children: [
                _DataCell(element.name, flex: 3),
                _NumberCell(element.number, color: const Color(0xFF3A79B8)),
                _NumberCell(element.information, color: AppColors.success),
              ],
            ),
          )
          .toList(growable: false),
      emptyMessage: 'No balance information for this employee.',
    );
  }
}

class _SimpleScrollableTable extends StatefulWidget {
  const _SimpleScrollableTable({
    required this.minWidth,
    required this.header,
    required this.rows,
    required this.emptyMessage,
  });

  final double minWidth;
  final Widget header;
  final List<Widget> rows;
  final String emptyMessage;

  @override
  State<_SimpleScrollableTable> createState() => _SimpleScrollableTableState();
}

class _SimpleScrollableTableState extends State<_SimpleScrollableTable> {
  final _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = mathMax(constraints.maxWidth, widget.minWidth);
        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: width > constraints.maxWidth,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  widget.header,
                  Expanded(
                    child: widget.rows.isEmpty
                        ? _EmptyPanel(message: widget.emptyMessage)
                        : ListView.builder(
                            itemCount: widget.rows.length,
                            itemExtent: AppSizes.payrollRunDetailsRowHeight,
                            itemBuilder: (context, index) => Container(
                              decoration: const BoxDecoration(
                                color: AppColors.surface,
                                border: Border(
                                  bottom: BorderSide(color: AppColors.divider),
                                ),
                              ),
                              child: widget.rows[index],
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

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.cells});

  final List<_TableCellSpec> cells;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.payrollTableHeaderHeight,
      color: AppColors.tableHeader,
      child: Row(
        children: cells
            .map((cell) {
              final content = Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    cell.label.toUpperCase(),
                    style: AppTextStyles.tableHeader,
                  ),
                ),
              );
              return cell.width > 0
                  ? SizedBox(width: cell.width, child: content)
                  : Expanded(flex: cell.flex, child: content);
            })
            .toList(growable: false),
      ),
    );
  }
}

class _TableCellSpec {
  const _TableCellSpec(this.label, this.width, {this.flex = 1});

  final String label;
  final double width;
  final int flex;
}

class _DataCell extends StatelessWidget {
  const _DataCell(this.value, {this.flex = 1, this.emphasized = false});

  final String value;
  final int flex;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            value.isEmpty ? '-' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.tableBody.copyWith(
              color: emphasized
                  ? const Color(0xFF355F5C)
                  : AppColors.textPrimary,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoneyCell extends StatelessWidget {
  const _MoneyCell(this.value, {required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _formatAmount(value),
            maxLines: 1,
            style: AppTextStyles.tableBody.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberCell extends StatelessWidget {
  const _NumberCell(this.value, {required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 115,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _formatAmount(value),
            maxLines: 1,
            style: AppTextStyles.tableBody.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.segmentBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.isEmpty ? '-' : label,
        style: AppTextStyles.badge.copyWith(color: const Color(0xFF5B7774)),
      ),
    );
  }
}

class _SmallLoader extends StatelessWidget {
  const _SmallLoader({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? AppColors.primary,
      ),
    );
  }
}

double mathMax(double first, double second) => first > second ? first : second;

String _formatAmount(double value) {
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }
  return '${value < 0 ? '-' : ''}$buffer.${parts.last}';
}
