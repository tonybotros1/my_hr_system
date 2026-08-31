import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/payroll/loan_advance_type_model.dart';

class LoanAdvanceTypesTable extends StatefulWidget {
  const LoanAdvanceTypesTable({
    required this.types,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<LoanAdvanceTypeModel> types;
  final ValueChanged<LoanAdvanceTypeModel> onEdit;
  final ValueChanged<LoanAdvanceTypeModel> onDelete;

  @override
  State<LoanAdvanceTypesTable> createState() => _LoanAdvanceTypesTableState();
}

class _LoanAdvanceTypesTableState extends State<LoanAdvanceTypesTable> {
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
            constraints.maxWidth > AppSizes.loanAdvanceTypesTableMinWidth
            ? constraints.maxWidth
            : AppSizes.loanAdvanceTypesTableMinWidth;
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
                      itemCount: widget.types.length,
                      itemExtent: AppSizes.loanAdvanceTypesTableRowHeight,
                      itemBuilder: (context, index) {
                        final type = widget.types[index];
                        return _TypeRow(
                          type: type,
                          onEdit: () => widget.onEdit(type),
                          onDelete: () => widget.onDelete(type),
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
          _HeaderCell('Code', width: 220),
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

class _TypeRow extends StatefulWidget {
  const _TypeRow({
    required this.type,
    required this.onEdit,
    required this.onDelete,
  });

  final LoanAdvanceTypeModel type;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_TypeRow> createState() => _TypeRowState();
}

class _TypeRowState extends State<_TypeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
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
            _BodyCell(type.name, flex: 3, emphasized: true),
            _BodyCell(type.code, width: 220, codeStyle: true),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _BasedElementBadge(
                    name: type.basedElementName.isEmpty
                        ? '-'
                        : type.basedElementName,
                  ),
                ),
              ),
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

class _BasedElementBadge extends StatelessWidget {
  const _BasedElementBadge({required this.name});

  final String name;

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
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.badge.copyWith(
          color: const Color(0xFF5B7774),
          fontSize: 10,
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
