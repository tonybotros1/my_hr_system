import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/payroll/balance_model.dart';

class BalancesTable extends StatefulWidget {
  const BalancesTable({
    required this.balances,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<BalanceModel> balances;
  final ValueChanged<BalanceModel> onEdit;
  final ValueChanged<BalanceModel> onDelete;

  @override
  State<BalancesTable> createState() => _BalancesTableState();
}

class _BalancesTableState extends State<BalancesTable> {
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
        final width = constraints.maxWidth > AppSizes.balancesTableMinWidth
            ? constraints.maxWidth
            : AppSizes.balancesTableMinWidth;
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
                  const _TableHeader(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.balances.length,
                      itemExtent: AppSizes.balancesTableRowHeight,
                      itemBuilder: (context, index) {
                        final balance = widget.balances[index];
                        return _BalanceRow(
                          balance: balance,
                          onEdit: () => widget.onEdit(balance),
                          onDelete: () => widget.onDelete(balance),
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
          BalanceHeaderCell('Actions', width: 104),
          BalanceHeaderCell('Name', flex: 3),
          BalanceHeaderCell('Type', width: 170),
          BalanceHeaderCell('Show In', width: 340),
          BalanceHeaderCell('Description', flex: 3),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatefulWidget {
  const _BalanceRow({
    required this.balance,
    required this.onEdit,
    required this.onDelete,
  });

  final BalanceModel balance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_BalanceRow> createState() => _BalanceRowState();
}

class _BalanceRowState extends State<_BalanceRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final balance = widget.balance;
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
                    tooltip: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                    onPressed: widget.onDelete,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  BalanceRowAction(
                    tooltip: 'Edit',
                    icon: Icons.edit_outlined,
                    onPressed: widget.onEdit,
                  ),
                ],
              ),
            ),
            BalanceBodyCell(balance.name, flex: 3, emphasized: true),
            SizedBox(
              width: 170,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _TypeBadge(type: balance.type),
                ),
              ),
            ),
            SizedBox(
              width: 340,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: AppSpacing.xxs,
                    runSpacing: AppSpacing.xxs,
                    children: [
                      if (balance.showOnAssignment)
                        const _ShowChip(label: 'Assignment'),
                      if (balance.showOnPayroll)
                        const _ShowChip(label: 'Payroll'),
                      if (balance.showOnLeave) const _ShowChip(label: 'Leave'),
                      if (!balance.showOnAssignment &&
                          !balance.showOnPayroll &&
                          !balance.showOnLeave)
                        Text('-', style: AppTextStyles.tableBody),
                    ],
                  ),
                ),
              ),
            ),
            BalanceBodyCell(
              balance.description.isEmpty ? '-' : balance.description,
              flex: 3,
              muted: balance.description.isEmpty,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final number = type == 'Number';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: number
            ? AppColors.primaryLight
            : AppColors.informationBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.isEmpty ? '-' : type,
        style: AppTextStyles.badge.copyWith(
          color: number ? AppColors.primaryDark : AppColors.informationText,
        ),
      ),
    );
  }
}

class _ShowChip extends StatelessWidget {
  const _ShowChip({required this.label});

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
        label,
        style: AppTextStyles.badge.copyWith(
          color: const Color(0xFF5B7774),
          fontSize: 10,
        ),
      ),
    );
  }
}

class BalanceHeaderCell extends StatelessWidget {
  const BalanceHeaderCell(this.text, {super.key, this.width, this.flex = 1});

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

class BalanceBodyCell extends StatelessWidget {
  const BalanceBodyCell(
    this.text, {
    super.key,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.tableBody.copyWith(
            color: muted
                ? AppColors.textHint
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

class BalanceRowAction extends StatelessWidget {
  const BalanceRowAction({
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
