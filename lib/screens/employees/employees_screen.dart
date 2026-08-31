import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/employee_controllers/employees_controller.dart';
import '../../models/employees/employee_model.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';
import '../../widgets/drop_down_menu.dart';
import '../../widgets/employees/employee_workspace_dialog.dart';
import '../../widgets/employees/employees_table.dart';
import '../../widgets/form_fields/app_text_form_field.dart';

class EmployeesScreen extends GetView<EmployeesController> {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PageHeader(onNew: () => _openNew(context)),
          const SizedBox(height: AppSpacing.md),
          const _EmployeeFilters(),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: DecoratedBox(
              decoration: AppDecorations.contentCard,
              child: Column(
                children: [
                  const _ResultsHeader(),
                  const Divider(height: 1),
                  Expanded(
                    child: Obx(
                      () => Stack(
                        children: [
                          Positioned.fill(
                            child: EmployeesTable(
                              employees: controller.employees,
                              deletingEmployeeId: controller.isDeleting.value,
                              onEdit: (employee) =>
                                  _openEmployee(context, employee),
                              onDelete: (employee) =>
                                  _deleteEmployee(context, employee),
                            ),
                          ),
                          if (controller.isLoading.value ||
                              controller.isLoadingDetails.value)
                            const Positioned.fill(
                              child: ColoredBox(
                                color: Color(0x55FFFFFF),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNew(BuildContext context) async {
    controller.beginNewEmployee();
    await showEmployeeWorkspaceDialog(context);
  }

  Future<void> _openEmployee(
    BuildContext context,
    EmployeeSummary employee,
  ) async {
    final loaded = await controller.loadEmployee(employee.id);
    if (loaded && context.mounted) await showEmployeeWorkspaceDialog(context);
  }

  Future<void> _deleteEmployee(
    BuildContext context,
    EmployeeSummary employee,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete ${employee.fullName}?',
      message:
          'The employee and related records will be permanently removed. The server may refuse this when payroll or time-sheet history exists.',
      confirmLabel: 'Delete employee',
      destructive: true,
    );
    if (!confirmed) return;
    final deleted = await controller.deleteEmployee(employee.id);
    if (deleted) {
      await showAppAlertDialog(
        title: 'Employee deleted',
        message: '${employee.fullName} was removed successfully.',
        kind: AppAlertKind.success,
      );
    }
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Text('Employees', style: AppTextStyles.pageHeading);
        final action = FilledButton.icon(
          onPressed: onNew,
          icon: const Icon(Icons.add_rounded, size: 19),
          label: const Text('New Record'),
        );
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: AppSpacing.sm),
              action,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: AppSpacing.md),
            action,
          ],
        );
      },
    );
  }
}

class _EmployeeFilters extends GetView<EmployeesController> {
  const _EmployeeFilters();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width:
                        constraints.maxWidth < AppSizes.employeeFiltersMinWidth
                        ? AppSizes.employeeFiltersMinWidth
                        : constraints.maxWidth,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: AppTextFormField(
                            label: 'Name',
                            hintText: 'Search employee name',
                            controller: controller.employeeNameFilter,
                            onFieldSubmitted: (_) =>
                                controller.loadEmployees(filtered: true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _FilterDropdown(
                            label: 'Employer',
                            textController: controller.employerFilter,
                            selectedId: controller.employerFilterId,
                            onOpen: () => controller.listValues('EMPLOYERS'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _FilterDropdown(
                            label: 'Department',
                            textController: controller.departmentFilter,
                            selectedId: controller.departmentFilterId,
                            onOpen: () => controller.listValues('DEPARTMENTS'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _FilterDropdown(
                            label: 'Job Title',
                            textController: controller.jobTitleFilter,
                            selectedId: controller.jobTitleFilterId,
                            onOpen: () => controller.listValues('JOBS'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _FilterDropdown(
                            label: 'Location',
                            textController: controller.locationFilter,
                            selectedId: controller.locationFilterId,
                            onOpen: () => controller.listValues('LOCATIONS'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: AppSizes.employeeFilterActionsWidth,
                          child: _FilterActions(controller: controller),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children:
                        const [
                              'ALL',
                              'EMPLOYEE',
                              'APPLICANT',
                              'EX-EMPLOYEE',
                              'EX-APPLICANT',
                            ]
                            .map((type) {
                              final selected =
                                  controller.selectedType.value == type;
                              return ChoiceChip(
                                label: Text(type),
                                selected: selected,
                                onSelected: (_) => controller.setType(type),
                                selectedColor: AppColors.primaryLight,
                                side: BorderSide(
                                  color: selected
                                      ? AppColors.borderStrong
                                      : AppColors.border,
                                ),
                                labelStyle: AppTextStyles.segment.copyWith(
                                  color: selected
                                      ? AppColors.primaryDark
                                      : AppColors.textSecondary,
                                ),
                              );
                            })
                            .toList(growable: false),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.textController,
    required this.selectedId,
    required this.onOpen,
  });

  final String label;
  final TextEditingController textController;
  final RxString selectedId;
  final Future<Map<String, dynamic>> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      selectedId.value;
      return LayoutBuilder(
        builder: (context, constraints) => CustomDropdown(
          width: constraints.maxWidth,
          hintText: label,
          textcontroller: textController.text,
          showedSelectedName: 'name',
          onOpen: onOpen,
          onDelete: () {
            selectedId.value = '';
            textController.clear();
          },
          onChanged: (key, value) {
            selectedId.value = key;
            textController.text = employeeString((value as Map)['name']);
          },
        ),
      );
    });
  }
}

class _FilterActions extends StatelessWidget {
  const _FilterActions({required this.controller});

  final EmployeesController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.labelLeftPadding,
            bottom: AppSpacing.xs,
          ),
          child: Text('Actions', style: AppTextStyles.fieldLabel),
        ),
        SizedBox(
          height: AppSizes.inputMinHeight,
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => controller.loadEmployees(filtered: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.primaryDark,
                    elevation: 0,
                  ),
                  child: const Text('Find'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.clearFilters,
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultsHeader extends GetView<EmployeesController> {
  const _ResultsHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            Obx(
              () => Text(
                '${controller.employees.length} records',
                style: AppTextStyles.listCount.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Edit a row to open the full employee profile',
              style: AppTextStyles.listCount.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
