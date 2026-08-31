import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/payroll/payroll_model.dart';

class PayrollTable extends StatefulWidget {
  const PayrollTable({
    required this.payrolls,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<PayrollModel> payrolls;
  final ValueChanged<PayrollModel> onEdit;
  final ValueChanged<PayrollModel> onDelete;

  @override
  State<PayrollTable> createState() => _PayrollTableState();
}

class _PayrollTableState extends State<PayrollTable> {
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
            constraints.maxWidth > AppSizes.payrollDefinitionsTableMinWidth
            ? constraints.maxWidth
            : AppSizes.payrollDefinitionsTableMinWidth;
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
                  const _PayrollTableHeader(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.payrolls.length,
                      itemExtent: AppSizes.payrollTableRowHeight,
                      itemBuilder: (context, index) {
                        final payroll = widget.payrolls[index];
                        return _PayrollRow(
                          payroll: payroll,
                          onEdit: () => widget.onEdit(payroll),
                          onDelete: () => widget.onDelete(payroll),
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

class _PayrollTableHeader extends StatelessWidget {
  const _PayrollTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.payrollTableHeaderHeight,
      color: AppColors.tableHeader,
      child: const Row(
        children: [
          _HeaderCell('Actions', width: 104),
          _HeaderCell('Name', flex: 3),
          _HeaderCell('Payment Type', width: 220),
          _HeaderCell('Notes', flex: 4),
        ],
      ),
    );
  }
}

class _PayrollRow extends StatefulWidget {
  const _PayrollRow({
    required this.payroll,
    required this.onEdit,
    required this.onDelete,
  });

  final PayrollModel payroll;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_PayrollRow> createState() => _PayrollRowState();
}

class _PayrollRowState extends State<_PayrollRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
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
                    tooltip: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                    onPressed: widget.onDelete,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  PayrollRowAction(
                    tooltip: 'Edit',
                    icon: Icons.edit_outlined,
                    onPressed: widget.onEdit,
                  ),
                ],
              ),
            ),
            _BodyCell(widget.payroll.name, flex: 3, emphasized: true),
            _BodyCell(
              widget.payroll.paymentTypeName.isEmpty
                  ? '-'
                  : widget.payroll.paymentTypeName,
              width: 220,
            ),
            _BodyCell(
              widget.payroll.notes.isEmpty ? '-' : widget.payroll.notes,
              flex: 4,
              muted: true,
            ),
          ],
        ),
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

class _BodyCell extends StatelessWidget {
  const _BodyCell(
    this.text, {
    this.width,
    this.flex = 1,
    this.emphasized = false,
    this.muted = false,
  });

  final String text;
  final double? width;
  final int flex;
  final bool emphasized;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.tableBody.copyWith(
            color: muted
                ? AppColors.textSecondary
                : emphasized
                ? const Color(0xFF355F5C)
                : AppColors.textPrimary,
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

class PayrollRowAction extends StatelessWidget {
  const PayrollRowAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
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
