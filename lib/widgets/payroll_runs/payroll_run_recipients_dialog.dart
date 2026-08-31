import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/payroll_runs_controller.dart';
import '../../models/payroll/payroll_run_model.dart';

Future<void> showPayrollRunRecipientsDialog() async {
  await Get.dialog<void>(
    const _RecipientsDialog(),
    barrierDismissible: false,
    barrierColor: AppColors.dialogScrim,
  );
}

class _RecipientsDialog extends StatefulWidget {
  const _RecipientsDialog();

  @override
  State<_RecipientsDialog> createState() => _RecipientsDialogState();
}

class _RecipientsDialogState extends State<_RecipientsDialog> {
  late final PayrollRunsController controller;
  late final List<PayrollRunEmployee> employees;
  late Set<String> selectedIds;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PayrollRunsController>();
    employees = List.of(controller.selectedDetails.value?.employees ?? []);
    selectedIds = employees
        .map((employee) => employee.employeeId)
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Set<String> get selectableIds => employees
      .map((employee) => employee.employeeId)
      .where((id) => id.isNotEmpty)
      .toSet();

  bool get allSelected =>
      selectableIds.isNotEmpty && selectedIds.length == selectableIds.length;

  List<PayrollRunEmployee> get selectedEmployees => employees
      .where((employee) => selectedIds.contains(employee.employeeId))
      .toList(growable: false);

  void _toggleAll() {
    setState(() {
      selectedIds = allSelected ? <String>{} : selectableIds;
    });
  }

  void _toggle(String id) {
    if (id.isEmpty) return;
    setState(() {
      if (!selectedIds.add(id)) selectedIds.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final run = controller.selectedDetails.value;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.editor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.payrollRecipientsDialogWidth,
          maxHeight: 720,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.forward_to_inbox_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Payslips',
                          style: AppTextStyles.heading(fontSize: 20),
                        ),
                        Text(
                          '${run?.payrollName ?? ''} • ${run?.periodName ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMuted.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back<void>(),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${selectedEmployees.length} of ${employees.length} employees selected',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: employees.isEmpty ? null : _toggleAll,
                    icon: Icon(
                      allSelected
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                      size: 18,
                    ),
                    label: Text(allSelected ? 'Clear All' : 'Select All'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: employees.isEmpty
                  ? Center(
                      child: Text(
                        'No employees found.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      itemCount: employees.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        final selected = selectedIds.contains(
                          employee.employeeId,
                        );
                        final email = employee.employeeEmail.trim();
                        return Material(
                          color: selected
                              ? AppColors.primaryLight
                              : AppColors.surface,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: selected
                                  ? const Color(0xFF9EDBD6)
                                  : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.field),
                          ),
                          child: InkWell(
                            onTap: employee.employeeId.isEmpty
                                ? null
                                : () => _toggle(employee.employeeId),
                            borderRadius: BorderRadius.circular(AppRadii.field),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: selected,
                                    onChanged: employee.employeeId.isEmpty
                                        ? null
                                        : (_) => _toggle(employee.employeeId),
                                  ),
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        AppColors.segmentBackground,
                                    child: Text(
                                      _initials(employee.employeeName),
                                      style: AppTextStyles.badge.copyWith(
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          employee.employeeName.isEmpty
                                              ? 'Employee'
                                              : employee.employeeName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.tableBody
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        if (employee.employeeNumber.isNotEmpty)
                                          Text(
                                            employee.employeeNumber,
                                            style: AppTextStyles.bodyMuted
                                                .copyWith(fontSize: 10),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    flex: 4,
                                    child: Row(
                                      children: [
                                        Icon(
                                          email.isEmpty
                                              ? Icons.warning_amber_rounded
                                              : Icons.alternate_email_rounded,
                                          size: 17,
                                          color: email.isEmpty
                                              ? AppColors.warning
                                              : AppColors.iconMuted,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            email.isEmpty
                                                ? 'No payslip email selected'
                                                : email,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.bodyMuted
                                                .copyWith(
                                                  fontSize: 11,
                                                  color: email.isEmpty
                                                      ? const Color(0xFFB67718)
                                                      : null,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.iconMuted,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Employees without a selected payslip email will be skipped by the server.',
                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 10),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back<void>(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  FilledButton.icon(
                    onPressed: selectedEmployees.isEmpty
                        ? null
                        : () {
                            final recipients = selectedEmployees;
                            Get.back<void>();
                            controller.emailPayslips(recipients);
                          },
                    icon: const Icon(Icons.send_rounded, size: 17),
                    label: Text('Send ${selectedEmployees.length}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2);
  final initials = words.map((word) => word[0].toUpperCase()).join();
  return initials.isEmpty ? 'E' : initials;
}
