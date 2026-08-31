import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/payroll/legislation_model.dart';

class LegislationTable extends StatefulWidget {
  const LegislationTable({
    required this.legislations,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<LegislationModel> legislations;
  final ValueChanged<LegislationModel> onEdit;
  final ValueChanged<LegislationModel> onDelete;

  @override
  State<LegislationTable> createState() => _LegislationTableState();
}

class _LegislationTableState extends State<LegislationTable> {
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
            constraints.maxWidth > AppSizes.legislationTableMinWidth
            ? constraints.maxWidth
            : AppSizes.legislationTableMinWidth;
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
                      itemCount: widget.legislations.length,
                      itemExtent: AppSizes.legislationTableRowHeight,
                      itemBuilder: (context, index) {
                        final legislation = widget.legislations[index];
                        return _LegislationRow(
                          legislation: legislation,
                          onDelete: () => widget.onDelete(legislation),
                          onEdit: () => widget.onEdit(legislation),
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
        children: [_HeaderCell('Actions', width: 100), _HeaderCell('Name')],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {this.width});

  final String text;
  final double? width;

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
        ? Expanded(child: child)
        : SizedBox(width: width, child: child);
  }
}

class _LegislationRow extends StatefulWidget {
  const _LegislationRow({
    required this.legislation,
    required this.onEdit,
    required this.onDelete,
  });

  final LegislationModel legislation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_LegislationRow> createState() => _LegislationRowState();
}

class _LegislationRowState extends State<_LegislationRow> {
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
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RowAction(
                    tooltip: 'Delete legislation',
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                    onPressed: widget.onDelete,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  _RowAction(
                    tooltip: 'Edit legislation',
                    icon: Icons.edit_outlined,
                    onPressed: widget.onEdit,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.legislation.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.tableBody.copyWith(
                      color: const Color(0xFF355F5C),
                      fontWeight: FontWeight.w700,
                    ),
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
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 34,
        child: IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            foregroundColor: destructive
                ? AppColors.error
                : AppColors.primaryDark,
            hoverColor: destructive
                ? AppColors.dangerBackground
                : AppColors.primaryLight,
            padding: EdgeInsets.zero,
          ),
          icon: Icon(icon, size: 18),
        ),
      ),
    );
  }
}
