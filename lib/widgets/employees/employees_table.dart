import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/employees/employee_model.dart';

class EmployeesTable extends StatefulWidget {
  const EmployeesTable({
    required this.employees,
    required this.deletingEmployeeId,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<EmployeeSummary> employees;
  final String deletingEmployeeId;
  final ValueChanged<EmployeeSummary> onEdit;
  final ValueChanged<EmployeeSummary> onDelete;

  @override
  State<EmployeesTable> createState() => _EmployeesTableState();
}

class _EmployeesTableState extends State<EmployeesTable> {
  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
            constraints.maxWidth < AppSizes.employeesTableMinWidth
            ? AppSizes.employeesTableMinWidth
            : constraints.maxWidth;
        final availableRows =
            ((constraints.maxHeight - 83) / AppSizes.employeesTableRowHeight)
                .floor()
                .clamp(0, widget.employees.length);
        return Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        const _Header(),
                        Expanded(
                          child: widget.employees.isEmpty
                              ? const _EmptyTable()
                              : Scrollbar(
                                  controller: _verticalController,
                                  thumbVisibility:
                                      widget.employees.length > availableRows,
                                  child: ListView.builder(
                                    controller: _verticalController,
                                    itemCount: widget.employees.length,
                                    itemExtent:
                                        AppSizes.employeesTableRowHeight,
                                    itemBuilder: (context, index) {
                                      final employee = widget.employees[index];
                                      return _EmployeeRow(
                                        employee: employee,
                                        deleting:
                                            widget.deletingEmployeeId ==
                                            employee.id,
                                        onEdit: () => widget.onEdit(employee),
                                        onDelete: () =>
                                            widget.onDelete(employee),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 40,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Text(
                widget.employees.isEmpty
                    ? 'Rows 0 of 0'
                    : '${widget.employees.length} employees • $availableRows fit in the current height',
                style: AppTextStyles.listCount,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.payrollTableHeaderHeight,
      color: AppColors.tableHeader,
      child: const Row(
        children: [
          _HeaderCell('Actions', width: 100),
          _HeaderCell('Full name', flex: 2),
          _HeaderCell('Type', width: 132),
          _HeaderCell('Employer', flex: 3),
          _HeaderCell('Department', flex: 2),
          _HeaderCell('Job title', flex: 2),
          _HeaderCell('Location', flex: 2),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {this.width, this.flex = 1});

  final String label;
  final double? width;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label.toUpperCase(), style: AppTextStyles.tableHeader),
      ),
    );
    if (width != null) return SizedBox(width: width, child: content);
    return Expanded(flex: flex, child: content);
  }
}

class _EmployeeRow extends StatefulWidget {
  const _EmployeeRow({
    required this.employee,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });

  final EmployeeSummary employee;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_EmployeeRow> createState() => _EmployeeRowState();
}

class _EmployeeRowState extends State<_EmployeeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;
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
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    tooltip: 'Delete employee',
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                    busy: widget.deleting,
                    onPressed: widget.deleting ? null : widget.onDelete,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  _ActionButton(
                    tooltip: 'Edit employee',
                    icon: Icons.edit_outlined,
                    onPressed: widget.deleting ? null : widget.onEdit,
                  ),
                ],
              ),
            ),
            _Cell(employee.fullName, flex: 2, emphasized: true),
            SizedBox(width: 132, child: _TypeBadge(employee.personType)),
            _Cell(employee.employerName, flex: 3),
            _Cell(employee.departmentName, flex: 2),
            _Cell(employee.jobTitleName, flex: 2),
            _Cell(employee.locationName, flex: 2),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.value, {required this.flex, this.emphasized = false});

  final String value;
  final int flex;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text(
          value.trim().isEmpty ? '—' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.tableBody.copyWith(
            color: emphasized ? const Color(0xFF426F70) : AppColors.textPrimary,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge(this.type);

  final String type;

  @override
  Widget build(BuildContext context) {
    final normalized = type.toLowerCase();
    final color = normalized.contains('ex-')
        ? AppColors.error
        : normalized.contains('applicant')
        ? AppColors.warning
        : AppColors.primaryDark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Text(
          type.trim().isEmpty ? 'Applicant' : type,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.badge.copyWith(color: color),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,
    required this.icon,
    this.onPressed,
    this.destructive = false,
    this.busy = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 34,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            foregroundColor: destructive
                ? AppColors.error
                : AppColors.primaryDark,
            hoverColor: destructive
                ? AppColors.dangerBackground
                : AppColors.primaryLight,
          ),
          icon: busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class _EmptyTable extends StatelessWidget {
  const _EmptyTable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline_rounded,
            size: 40,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('No employees found', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Change the filters or create a new employee.',
            style: AppTextStyles.listCount,
          ),
        ],
      ),
    );
  }
}
