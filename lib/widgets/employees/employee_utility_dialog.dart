import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/employee_controllers/employees_controller.dart';
import '../../models/employees/employee_model.dart';
import '../../services/browser_dialog_history.dart';
import '../dialogs/app_alert_dialog.dart';
import 'employee_record_dialog.dart';
import 'employee_records_table.dart';

Future<void> showEmployeeUtilityDialog(
  BuildContext context, {
  required EmployeeRecordKind kind,
}) async {
  final controller = Get.find<EmployeesController>();
  if (kind == EmployeeRecordKind.leave) {
    await controller.loadLeaves();
  } else {
    await controller.loadContacts();
  }
  if (!context.mounted) return;
  final screen = MediaQuery.sizeOf(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final history = BrowserDialogHistory.open(() {
    if (navigator.canPop()) navigator.pop<void>();
  });
  try {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: AppColors.dialogScrim,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.xs),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.editor),
        ),
        child: SizedBox(
          width: math.max(280, screen.width - (AppSpacing.md * 2)),
          height: math.max(360, screen.height - (AppSpacing.md * 2)),
          child: _EmployeeUtilityBody(kind: kind),
        ),
      ),
    );
  } finally {
    history.complete();
  }
}

class _EmployeeUtilityBody extends StatefulWidget {
  const _EmployeeUtilityBody({required this.kind});

  final EmployeeRecordKind kind;

  @override
  State<_EmployeeUtilityBody> createState() => _EmployeeUtilityBodyState();
}

class _EmployeeUtilityBodyState extends State<_EmployeeUtilityBody> {
  final search = TextEditingController();
  String query = '';

  EmployeesController get controller => Get.find<EmployeesController>();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _UtilityHeader(title: labelForRecordKind(widget.kind)),
        Expanded(
          child: Container(
            color: AppColors.mainCanvas,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: DecoratedBox(
              decoration: AppDecorations.contentCard,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 580;
                        final searchField = TextField(
                          controller: search,
                          onChanged: (value) =>
                              setState(() => query = value.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: widget.kind == EmployeeRecordKind.leave
                                ? 'Search for leaves'
                                : 'Search for contacts',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      search.clear();
                                      setState(() => query = '');
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        );
                        final add = FilledButton.icon(
                          onPressed: () => showEmployeeRecordDialog(
                            context,
                            kind: widget.kind,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('New Record'),
                        );
                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              searchField,
                              const SizedBox(height: AppSpacing.sm),
                              add,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: searchField),
                            const SizedBox(width: AppSpacing.md),
                            add,
                          ],
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Obx(() {
                      final records = controller.recordsFor(widget.kind);
                      final visible = query.isEmpty
                          ? records
                          : records
                                .where(
                                  (record) => record.data.values.any(
                                    (value) => value
                                        .toString()
                                        .toLowerCase()
                                        .contains(query),
                                  ),
                                )
                                .toList(growable: false);
                      if (controller.isUtilityLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return EmployeeRecordsTable(
                        kind: widget.kind,
                        records: visible,
                        utility: true,
                        deletingRecordId: controller.isDeleting.value,
                        onEdit: (record) => _edit(context, record),
                        onDelete: (record) => _delete(context, record),
                      );
                    }),
                  ),
                  Obx(
                    () => Container(
                      height: 42,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: Text(
                        '${controller.recordsFor(widget.kind).length} records',
                        style: AppTextStyles.listCount,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, EmployeeRecord record) async {
    if (widget.kind == EmployeeRecordKind.leave &&
        record.text('status').toLowerCase() != 'new') {
      await showAppAlertDialog(
        title: 'Leave cannot be edited',
        message: 'Only leave records with New status can be edited.',
        kind: AppAlertKind.info,
      );
      return;
    }
    if (!context.mounted) return;
    await showEmployeeRecordDialog(context, kind: widget.kind, record: record);
  }

  Future<void> _delete(BuildContext context, EmployeeRecord record) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete this record?',
      message: 'This action permanently removes the selected employee record.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) await controller.deleteRecord(widget.kind, record);
  }
}

class _UtilityHeader extends StatelessWidget {
  const _UtilityHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      color: AppColors.primaryDark,
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, color: Colors.white, size: 21),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.heading(
                fontSize: 20,
              ).copyWith(color: Colors.white),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
