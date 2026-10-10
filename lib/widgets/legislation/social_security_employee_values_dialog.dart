import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/legislation_controller.dart';
import '../../models/payroll/legislation_model.dart';
import '../../models/payroll/social_security_employee_value_model.dart';
import '../dialogs/app_alert_dialog.dart';

Future<void> showSocialSecurityEmployeeValuesDialog(
  BuildContext context,
) async {
  await Get.dialog<void>(
    const _SocialSecurityEmployeeValuesDialog(),
    barrierDismissible: false,
    barrierColor: AppColors.dialogScrim,
  );
}

class _SocialSecurityEmployeeValuesDialog extends StatefulWidget {
  const _SocialSecurityEmployeeValuesDialog();

  @override
  State<_SocialSecurityEmployeeValuesDialog> createState() =>
      _SocialSecurityEmployeeValuesDialogState();
}

class _SocialSecurityEmployeeValuesDialogState
    extends State<_SocialSecurityEmployeeValuesDialog> {
  late final LegislationController controller;
  final searchController = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();
    controller = Get.find<LegislationController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchSocialSecurityEmployeeValues();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _clearOverride(SocialSecurityEmployeeValueModel value) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Clear override value?',
      message:
          '${value.employeeName} will use the legislation social security ceiling instead of ${_valueLabel(value)}.',
      confirmLabel: 'Clear override',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await controller.clearSocialSecurityEmployeeOverride(value);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final width = math
        .max(280.0, math.min(900.0, screen.width - 24))
        .toDouble();
    final height = math
        .max(360.0, math.min(720.0, screen.height - 24))
        .toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.editor),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            _DialogHeader(controller: controller),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: searchController,
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                  hintText: 'Search employees, number, registration, or value',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: query.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            searchController.clear();
                            setState(() => query = '');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                  filled: true,
                  fillColor: AppColors.softSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.field),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.field),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final values = controller.socialSecurityEmployeeValues
                    .where((value) => value.matches(query))
                    .toList(growable: false);
                if (controller.isLoadingSocialSecurityEmployeeValues.value &&
                    controller.socialSecurityEmployeeValues.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final error =
                    controller.socialSecurityEmployeeValuesError.value;
                if (error != null) {
                  return _ErrorState(
                    message: error,
                    onRetry: controller.fetchSocialSecurityEmployeeValues,
                  );
                }
                if (values.isEmpty) {
                  return _EmptyState(hasSearch: query.trim().isNotEmpty);
                }
                return _EmployeeValuesList(
                  values: values,
                  clearingId:
                      controller.clearingSocialSecurityEmployeeValueId.value,
                  onClear: _clearOverride,
                );
              }),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.iconMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Overrides are listed first. Clear an override to use the legislation ceiling.',
                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () => Get.back<void>(),
                    child: const Text('Close'),
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

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.controller});

  final LegislationController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadii.field),
            ),
            child: Icon(
              Icons.groups_2_outlined,
              color: AppColors.primaryDark,
              size: 21,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Social Security Employee Values',
                  style: AppTextStyles.heading(fontSize: 20),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Obx(() {
                  final employeeCount = controller.socialSecurityEmployeeValues
                      .map((value) => value.employeeId)
                      .where((id) => id.isNotEmpty)
                      .toSet()
                      .length;
                  final overrideCount = controller.socialSecurityEmployeeValues
                      .where((value) => value.hasOverride)
                      .map((value) => value.employeeId)
                      .where((id) => id.isNotEmpty)
                      .toSet()
                      .length;
                  final policyName = controller.name.text.trim();
                  final employeeLabel = employeeCount == 1
                      ? '1 employee'
                      : '$employeeCount employees';
                  final overrideLabel = overrideCount == 1
                      ? '1 override'
                      : '$overrideCount overrides';
                  final countLabel = '$overrideLabel • $employeeLabel';
                  return Text(
                    policyName.isEmpty
                        ? countLabel
                        : '$policyName • $countLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 11),
                  );
                }),
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
    );
  }
}

class _EmployeeValuesList extends StatelessWidget {
  const _EmployeeValuesList({
    required this.values,
    required this.clearingId,
    required this.onClear,
  });

  final List<SocialSecurityEmployeeValueModel> values;
  final String? clearingId;
  final ValueChanged<SocialSecurityEmployeeValueModel> onClear;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            itemCount: values.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, index) => _EmployeeValueCard(
              value: values[index],
              isClearing: clearingId == values[index].id,
              onClear: onClear,
            ),
          );
        }
        return Column(
          children: [
            const _EmployeeValueTableHeader(),
            Expanded(
              child: ListView.separated(
                itemCount: values.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _EmployeeValueTableRow(
                  value: values[index],
                  isClearing: clearingId == values[index].id,
                  onClear: onClear,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmployeeValueTableHeader extends StatelessWidget {
  const _EmployeeValueTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tableHeader,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('Employee')),
          Expanded(flex: 2, child: _HeaderText('Employee No.')),
          Expanded(flex: 2, child: _HeaderText('SS Reg. No.')),
          Expanded(flex: 2, child: _HeaderText('Value')),
          Expanded(flex: 3, child: _HeaderText('Effective period')),
          Expanded(flex: 2, child: _HeaderText('Actions')),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTextStyles.tableHeader);
  }
}

class _EmployeeValueTableRow extends StatelessWidget {
  const _EmployeeValueTableRow({
    required this.value,
    required this.isClearing,
    required this.onClear,
  });

  final SocialSecurityEmployeeValueModel value;
  final bool isClearing;
  final ValueChanged<SocialSecurityEmployeeValueModel> onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.segmentBackground,
                  child: Text(
                    _initials(value.employeeName),
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    value.employeeName.isEmpty
                        ? 'Employee'
                        : value.employeeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.tableBody,
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: _BodyText(_display(value.employeeNumber))),
          Expanded(
            flex: 2,
            child: _BodyText(_display(value.socialSecurityRegistrationNumber)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _valueLabel(value),
              style: AppTextStyles.tableBody.copyWith(
                color: value.hasOverride
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
                fontWeight: value.hasOverride
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
          Expanded(flex: 3, child: _BodyText(_period(value))),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: value.hasOverride
                  ? TextButton.icon(
                      onPressed: isClearing ? null : () => onClear(value),
                      icon: isClearing
                          ? const SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.clear_rounded, size: 16),
                      label: const Text('Clear'),
                    )
                  : const _BodyText('—'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
    );
  }
}

class _EmployeeValueCard extends StatelessWidget {
  const _EmployeeValueCard({
    required this.value,
    required this.isClearing,
    required this.onClear,
  });

  final SocialSecurityEmployeeValueModel value;
  final bool isClearing;
  final ValueChanged<SocialSecurityEmployeeValueModel> onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softSurface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.segmentBackground,
                child: Text(
                  _initials(value.employeeName),
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  value.employeeName.isEmpty ? 'Employee' : value.employeeName,
                  style: AppTextStyles.tableBody.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadii.field),
                ),
                child: Text(
                  _valueLabel(value),
                  style: AppTextStyles.badge.copyWith(
                    color: value.hasOverride
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailLine(label: 'Employee No.', value: value.employeeNumber),
          _DetailLine(
            label: 'SS Reg. No.',
            value: value.socialSecurityRegistrationNumber,
          ),
          _DetailLine(label: 'Effective period', value: _period(value)),
          if (value.hasOverride) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: isClearing ? null : () => onClear(value),
                icon: isClearing
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.clear_rounded, size: 17),
                label: const Text('Clear override'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: AppTextStyles.fieldLabel),
          ),
          Expanded(child: _BodyText(_display(value))),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 34,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.person_search_outlined,
              color: AppColors.iconMuted,
              size: 38,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasSearch
                  ? 'No employees match this search.'
                  : 'No employees have a Social Security Employee assignment.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}

String _period(SocialSecurityEmployeeValueModel value) {
  final start = formatLegislationDate(value.startDate);
  final end = formatLegislationDate(value.endDate);
  return '${start.isEmpty ? 'No start date' : start} – '
      '${end.isEmpty ? 'Current' : end}';
}

String _valueLabel(SocialSecurityEmployeeValueModel value) {
  if (!value.hasOverride || value.value == null) return 'Default';
  return formatLegislationNumber(value.value!);
}

String _display(String value) => value.trim().isEmpty ? '—' : value.trim();

String _initials(String value) {
  final initials = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0].toUpperCase())
      .join();
  return initials.isEmpty ? 'E' : initials;
}
