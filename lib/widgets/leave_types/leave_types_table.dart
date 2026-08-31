import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/payroll/leave_type_model.dart';

class LeaveTypesTable extends StatefulWidget {
  const LeaveTypesTable({
    required this.leaveTypes,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<LeaveTypeModel> leaveTypes;
  final ValueChanged<LeaveTypeModel> onEdit;
  final ValueChanged<LeaveTypeModel> onDelete;

  @override
  State<LeaveTypesTable> createState() => _LeaveTypesTableState();
}

class _LeaveTypesTableState extends State<LeaveTypesTable> {
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
        if (constraints.maxHeight <= AppSizes.payrollTableHeaderHeight) {
          return const ColoredBox(color: AppColors.tableHeader);
        }
        final tableWidth =
            constraints.maxWidth > AppSizes.leaveTypesTableMinWidth
            ? constraints.maxWidth
            : AppSizes.leaveTypesTableMinWidth;
        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  const _TableHeader(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.leaveTypes.length,
                      itemExtent: AppSizes.leaveTypesTableRowHeight,
                      itemBuilder: (context, index) {
                        final leaveType = widget.leaveTypes[index];
                        return _LeaveTypeRow(
                          leaveType: leaveType,
                          onEdit: () => widget.onEdit(leaveType),
                          onDelete: () => widget.onDelete(leaveType),
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

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.payrollTableHeaderHeight,
      color: AppColors.tableHeader,
      child: const Row(
        children: [
          _HeaderCell('Actions', width: 100),
          _HeaderCell('Name', flex: 3),
          _HeaderCell('Code', width: 140),
          _HeaderCell('Type', width: 210),
          _HeaderCell('Based Element', flex: 3),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {this.width, this.flex = 1});

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

class _LeaveTypeRow extends StatefulWidget {
  const _LeaveTypeRow({
    required this.leaveType,
    required this.onEdit,
    required this.onDelete,
  });

  final LeaveTypeModel leaveType;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_LeaveTypeRow> createState() => _LeaveTypeRowState();
}

class _LeaveTypeRowState extends State<_LeaveTypeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final leaveType = widget.leaveType;
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
                  _RowAction(
                    tooltip: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                    onPressed: widget.onDelete,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  _RowAction(
                    tooltip: 'Edit',
                    icon: Icons.edit_outlined,
                    onPressed: widget.onEdit,
                  ),
                ],
              ),
            ),
            _BodyCell(leaveType.name, flex: 3, emphasized: true),
            _BodyCell(leaveType.code, width: 140, codeStyle: true),
            SizedBox(
              width: 210,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _DayTypeBadge(type: leaveType.type),
                ),
              ),
            ),
            _BodyCell(
              leaveType.basedElementName.isEmpty
                  ? '-'
                  : leaveType.basedElementName,
              flex: 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(
    this.text, {
    this.width,
    this.flex = 1,
    this.emphasized = false,
    this.codeStyle = false,
  });

  final String text;
  final double? width;
  final int flex;
  final bool emphasized;
  final bool codeStyle;

  @override
  Widget build(BuildContext context) {
    final style = codeStyle
        ? AppTextStyles.tableKey
        : emphasized
        ? AppTextStyles.tableBody.copyWith(
            color: const Color(0xFF355F5C),
            fontWeight: FontWeight.w700,
          )
        : AppTextStyles.tableBody;
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
    return width == null
        ? Expanded(flex: flex, child: child)
        : SizedBox(width: width, child: child);
  }
}

class _DayTypeBadge extends StatelessWidget {
  const _DayTypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final working = type == 'Working Days';
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: working
            ? AppColors.primaryLight
            : AppColors.informationBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.isEmpty ? '-' : type,
        style: AppTextStyles.badge.copyWith(
          color: working ? AppColors.primaryDark : AppColors.informationText,
        ),
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 17),
      color: destructive ? AppColors.error : AppColors.primaryDark,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(34),
        maximumSize: const Size.square(34),
        padding: EdgeInsets.zero,
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}
