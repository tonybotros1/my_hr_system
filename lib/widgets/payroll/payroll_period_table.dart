import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/payroll_controller.dart';
import '../../models/payroll/payroll_model.dart';
import 'payroll_table.dart';

class PayrollPeriodTable extends StatefulWidget {
  const PayrollPeriodTable({
    required this.periods,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<PayrollPeriodModel> periods;
  final ValueChanged<PayrollPeriodModel> onEdit;
  final ValueChanged<PayrollPeriodModel> onDelete;

  @override
  State<PayrollPeriodTable> createState() => _PayrollPeriodTableState();
}

class _PayrollPeriodTableState extends State<PayrollPeriodTable> {
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
        final width = constraints.maxWidth > AppSizes.payrollPeriodTableMinWidth
            ? constraints.maxWidth
            : AppSizes.payrollPeriodTableMinWidth;
        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  const _PeriodHeader(),
                  Expanded(
                    child: widget.periods.isEmpty
                        ? Center(
                            child: Text(
                              'No periods have been added yet.',
                              style: AppTextStyles.bodyMuted,
                            ),
                          )
                        : ListView.builder(
                            itemCount: widget.periods.length,
                            itemExtent: AppSizes.payrollPeriodTableRowHeight,
                            itemBuilder: (context, index) {
                              final period = widget.periods[index];
                              return _PeriodRow(
                                period: period,
                                onEdit: () => widget.onEdit(period),
                                onDelete: () => widget.onDelete(period),
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

class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.payrollTableHeaderHeight,
      color: AppColors.tableHeader,
      child: const Row(
        children: [
          _Header('Actions', width: 104),
          _Header('Period', flex: 4),
          _Header('Start Date', width: 170),
          _Header('End Date', width: 170),
          _Header('Status', width: 130),
        ],
      ),
    );
  }
}

class _PeriodRow extends StatefulWidget {
  const _PeriodRow({
    required this.period,
    required this.onEdit,
    required this.onDelete,
  });

  final PayrollPeriodModel period;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_PeriodRow> createState() => _PeriodRowState();
}

class _PeriodRowState extends State<_PeriodRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final period = widget.period;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        decoration: BoxDecoration(
          color: _hovered ? AppColors.softSurface : AppColors.surface,
          border: const Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 104,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PayrollRowAction(
                    tooltip: 'Delete period',
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                    onPressed: widget.onDelete,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  PayrollRowAction(
                    tooltip: 'Edit period',
                    icon: Icons.edit_outlined,
                    onPressed: widget.onEdit,
                  ),
                ],
              ),
            ),
            _Cell(period.name, flex: 4, emphasized: true),
            _Cell(formatPayrollDate(period.startDate), width: 170),
            _Cell(formatPayrollDate(period.endDate), width: 170),
            SizedBox(
              width: 130,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusBadge(status: period.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text, {this.width, this.flex = 1});

  final String text;
  final double? width;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text.toUpperCase(), style: AppTextStyles.tableHeader),
      ),
    );
    return width == null
        ? Expanded(flex: flex, child: child)
        : SizedBox(width: width, child: child);
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.width, this.flex = 1, this.emphasized = false});

  final String text;
  final double? width;
  final int flex;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.isEmpty ? '-' : text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.tableBody.copyWith(
            color: emphasized ? const Color(0xFF355F5C) : AppColors.textPrimary,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
    return width == null
        ? Expanded(flex: flex, child: child)
        : SizedBox(width: width, child: child);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final active = status == 'Active';
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? AppColors.successBackground
            : AppColors.informationBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.isEmpty ? '-' : status,
        style: AppTextStyles.badge.copyWith(
          color: active ? AppColors.success : AppColors.informationText,
        ),
      ),
    );
  }
}
