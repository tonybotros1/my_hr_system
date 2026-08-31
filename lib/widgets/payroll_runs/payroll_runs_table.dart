import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/payroll/payroll_run_model.dart';

class PayrollRunsTable extends StatefulWidget {
  const PayrollRunsTable({required this.runs, required this.onOpen, super.key});

  final List<PayrollRunSummary> runs;
  final ValueChanged<PayrollRunSummary> onOpen;

  @override
  State<PayrollRunsTable> createState() => _PayrollRunsTableState();
}

class _PayrollRunsTableState extends State<PayrollRunsTable> {
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
            constraints.maxWidth > AppSizes.payrollRunsTableMinWidth
            ? constraints.maxWidth
            : AppSizes.payrollRunsTableMinWidth;
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
                      itemCount: widget.runs.length,
                      itemExtent: AppSizes.payrollRunsTableRowHeight,
                      itemBuilder: (context, index) {
                        final run = widget.runs[index];
                        return _RunRow(
                          run: run,
                          onOpen: () => widget.onOpen(run),
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
          _HeaderCell('Action', width: 90),
          _HeaderCell('Run Number', width: 160),
          _HeaderCell('Payroll Name', width: 220),
          _HeaderCell('Period Name', flex: 3),
          _HeaderCell('Description', flex: 3),
          _HeaderCell('Payment Number', width: 190),
        ],
      ),
    );
  }
}

class _RunRow extends StatefulWidget {
  const _RunRow({required this.run, required this.onOpen});

  final PayrollRunSummary run;
  final VoidCallback onOpen;

  @override
  State<_RunRow> createState() => _RunRowState();
}

class _RunRowState extends State<_RunRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
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
              width: 90,
              child: Center(
                child: IconButton.outlined(
                  onPressed: widget.onOpen,
                  tooltip: 'Open payroll run',
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  color: AppColors.primaryDark,
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(34),
                    maximumSize: const Size.square(34),
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            _BodyCell(
              run.runNumber,
              width: 160,
              style: AppTextStyles.tableKey.copyWith(
                color: const Color(0xFFC58422),
              ),
            ),
            _BodyCell(
              run.payrollName,
              width: 220,
              style: AppTextStyles.tableBody.copyWith(
                color: const Color(0xFF355F5C),
                fontWeight: FontWeight.w700,
              ),
            ),
            _BodyCell(run.periodName, flex: 3),
            _BodyCell(
              run.description.isEmpty ? '-' : run.description,
              flex: 3,
              muted: run.description.isEmpty,
            ),
            SizedBox(
              width: 190,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _PaymentBadge(value: run.paymentNumber),
                ),
              ),
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
    this.style,
    this.muted = false,
  });

  final String text;
  final double? width;
  final int flex;
  final TextStyle? style;
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
          style:
              style ??
              AppTextStyles.tableBody.copyWith(
                color: muted ? AppColors.textHint : AppColors.textPrimary,
              ),
        ),
      ),
    );
    return width == null
        ? Expanded(flex: flex, child: child)
        : SizedBox(width: width, child: child);
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: empty
            ? AppColors.segmentBackground
            : AppColors.successBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        empty ? '-' : value,
        style: AppTextStyles.badge.copyWith(
          color: empty ? AppColors.textSecondary : AppColors.success,
        ),
      ),
    );
  }
}
