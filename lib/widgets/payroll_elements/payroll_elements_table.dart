import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/payroll/payroll_element_model.dart';

class PayrollElementsTable extends StatefulWidget {
  const PayrollElementsTable({
    required this.elements,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<PayrollElementModel> elements;
  final ValueChanged<PayrollElementModel> onEdit;
  final ValueChanged<PayrollElementModel> onDelete;

  @override
  State<PayrollElementsTable> createState() => _PayrollElementsTableState();
}

class _PayrollElementsTableState extends State<PayrollElementsTable> {
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
        final tableWidth = constraints.maxWidth > AppSizes.payrollTableMinWidth
            ? constraints.maxWidth
            : AppSizes.payrollTableMinWidth;

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
                      itemCount: widget.elements.length,
                      itemExtent: AppSizes.payrollTableRowHeight,
                      itemBuilder: (context, index) {
                        final element = widget.elements[index];

                        return _TableRow(
                          element: element,
                          onEdit: () => widget.onEdit(element),
                          onDelete: () => widget.onDelete(element),
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
          _HeaderCell('Key', flex: 3),
          _HeaderCell('Name', flex: 3),
          _HeaderCell('Type', width: 150),
          _HeaderCell('Priority', width: 100),
          _HeaderCell('Comments', flex: 2),
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

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.element,
    required this.onEdit,
    required this.onDelete,
  });

  final PayrollElementModel element;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
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
                  onPressed: onDelete,
                ),
                const SizedBox(width: AppSpacing.xxs),
                _RowAction(
                  tooltip: 'Edit',
                  icon: Icons.edit_outlined,
                  onPressed: onEdit,
                ),
              ],
            ),
          ),
          _BodyCell(element.key, flex: 3, keyStyle: true),
          _BodyCell(element.name, flex: 3),
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TypeBadge(type: element.type),
              ),
            ),
          ),
          _BodyCell(element.priority, width: 100),
          _BodyCell(element.comments.isEmpty ? '-' : element.comments, flex: 2),
        ],
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(
    this.text, {
    this.width,
    this.flex = 1,
    this.keyStyle = false,
  });

  final String text;
  final double? width;
  final int flex;
  final bool keyStyle;

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
          style: keyStyle ? AppTextStyles.tableKey : AppTextStyles.tableBody,
        ),
      ),
    );
    return width == null
        ? Expanded(flex: flex, child: child)
        : SizedBox(width: width, child: child);
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

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final colors = switch (type) {
      'Earning' => (AppColors.primaryLight, AppColors.primaryDark),
      'Deduction' => (AppColors.dangerBackground, AppColors.errorText),
      _ => (AppColors.informationBackground, AppColors.informationText),
    };
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.isEmpty ? '-' : type,
        style: AppTextStyles.badge.copyWith(color: colors.$2),
      ),
    );
  }
}
