import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/payroll/balance_model.dart';
import 'balances_table.dart';

class BalanceBasedElementsTable extends StatefulWidget {
  const BalanceBasedElementsTable({
    required this.elements,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<BalanceBasedElementModel> elements;
  final ValueChanged<BalanceBasedElementModel> onEdit;
  final ValueChanged<BalanceBasedElementModel> onDelete;

  @override
  State<BalanceBasedElementsTable> createState() =>
      _BalanceBasedElementsTableState();
}

class _BalanceBasedElementsTableState extends State<BalanceBasedElementsTable> {
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
        final width = constraints.maxWidth > AppSizes.balanceBasedTableMinWidth
            ? constraints.maxWidth
            : AppSizes.balanceBasedTableMinWidth;
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
                  Container(
                    height: AppSizes.payrollTableHeaderHeight,
                    color: AppColors.tableHeader,
                    child: const Row(
                      children: [
                        BalanceHeaderCell('Actions', width: 104),
                        BalanceHeaderCell('Element Name', flex: 4),
                        BalanceHeaderCell('Type', width: 220),
                      ],
                    ),
                  ),
                  Expanded(
                    child: widget.elements.isEmpty
                        ? Center(
                            child: Text(
                              'No based elements have been added yet.',
                              style: AppTextStyles.bodyMuted,
                            ),
                          )
                        : ListView.builder(
                            itemCount: widget.elements.length,
                            itemExtent: AppSizes.balancesTableRowHeight,
                            itemBuilder: (context, index) {
                              final element = widget.elements[index];
                              return _BasedElementRow(
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

class _BasedElementRow extends StatefulWidget {
  const _BasedElementRow({
    required this.element,
    required this.onEdit,
    required this.onDelete,
  });

  final BalanceBasedElementModel element;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_BasedElementRow> createState() => _BasedElementRowState();
}

class _BasedElementRowState extends State<_BasedElementRow> {
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
                  BalanceRowAction(
                    tooltip: 'Delete based element',
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                    onPressed: widget.onDelete,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  BalanceRowAction(
                    tooltip: 'Edit based element',
                    icon: Icons.edit_outlined,
                    onPressed: widget.onEdit,
                  ),
                ],
              ),
            ),
            BalanceBodyCell(
              widget.element.elementName,
              flex: 4,
              emphasized: true,
            ),
            SizedBox(
              width: 220,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _BasedTypeBadge(type: widget.element.type),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasedTypeBadge extends StatelessWidget {
  const _BasedTypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final add = type == 'Add';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: add ? AppColors.primaryLight : AppColors.dangerBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.isEmpty ? '-' : type,
        style: AppTextStyles.badge.copyWith(
          color: add ? AppColors.primaryDark : AppColors.errorText,
        ),
      ),
    );
  }
}
