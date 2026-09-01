import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/legislation_controller.dart';
import '../../models/payroll/legislation_model.dart';
import '../form_fields/app_date_form_field.dart';
import '../form_fields/app_text_form_field.dart';

Future<void> showLegislationEditorDialog(BuildContext context) async {
  final screenSize = MediaQuery.sizeOf(context);
  final width = math.max(
    280,
    math.min(
      AppSizes.legislationEditorMaxWidth,
      screenSize.width - (AppSpacing.md * 2),
    ),
  );
  final height = math.max(
    360,
    math.min(
      AppSizes.legislationEditorMaxHeight,
      screenSize.height - (AppSpacing.md * 2),
    ),
  );

  await Get.dialog<void>(
    Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xs),
      clipBehavior: Clip.antiAlias,
      backgroundColor: AppColors.mainCanvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.editor),
      ),
      child: SizedBox(
        width: width.toDouble(),
        height: height.toDouble(),
        child: const Column(
          children: [
            _EditorHeader(),
            Expanded(child: _EditorBody()),
          ],
        ),
      ),
    ),
    barrierDismissible: false,
    barrierColor: AppColors.dialogScrim,
  );
}

class _EditorHeader extends GetView<LegislationController> {
  const _EditorHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final identity = Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadii.field),
                ),
                child: const Icon(
                  Icons.policy_outlined,
                  color: AppColors.primaryDark,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.isEditing
                            ? 'Edit Legislation'
                            : 'New Legislation',
                        style: AppTextStyles.heading(fontSize: 21),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        controller.isEditing
                            ? 'Review and update this statutory policy.'
                            : 'Create a statutory policy for your workforce.',
                        style: AppTextStyles.listCount,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
          final actions = Obx(
            () => Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : () => Get.back<void>(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textHint,
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : () async {
                          final saved = await controller.saveLegislation();
                          if (saved) Get.back<void>();
                        },
                  child: controller.isSaving.value
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Legislation'),
                ),
              ],
            ),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: AppSpacing.xs),
                actions,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.md),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _EditorBody extends GetView<LegislationController> {
  const _EditorBody();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.legislationEditorContentWidth,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PolicyOverview(),
                SizedBox(height: AppSpacing.xl),
                _SectionHeading(),
                SizedBox(height: AppSpacing.md),
                _EntitlementGrid(),
                SizedBox(height: AppSpacing.md),
                _SocialSecurityCard(),
                SizedBox(height: AppSpacing.md),
                _IncomeTaxCard(),
                SizedBox(height: AppSpacing.lg),
                _FooterNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicyOverview extends GetView<LegislationController> {
  const _PolicyOverview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final introduction = const _PolicyIntroduction();
            final name = AppTextFormField(
              label: 'Policy name',
              hintText: 'For example, UAE Legislation',
              controller: controller.name,
              validator: controller.requiredText,
              textCapitalization: TextCapitalization.words,
            );
            const weekend = _WeekendSelector();
            if (constraints.maxWidth < 880) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  introduction,
                  const SizedBox(height: AppSpacing.lg),
                  name,
                  const SizedBox(height: AppSpacing.lg),
                  weekend,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(flex: 3, child: _PolicyIntroduction()),
                const SizedBox(width: AppSpacing.lg),
                Expanded(flex: 4, child: name),
                const SizedBox(width: AppSpacing.lg),
                const Expanded(flex: 6, child: _WeekendSelector()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PolicyIntroduction extends StatelessWidget {
  const _PolicyIntroduction();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadii.field),
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: AppColors.primaryDark,
            size: 21,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Policy details', style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'General information and the standard weekly schedule.',
                style: AppTextStyles.listCount.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekendSelector extends GetView<LegislationController> {
  const _WeekendSelector();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSizes.labelLeftPadding),
          child: Text('Weekend days', style: AppTextStyles.fieldLabel),
        ),
        const SizedBox(height: AppSpacing.xs),
        Obx(
          () => Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: LegislationController.weekDays.map((day) {
              final selected = controller.selectedWeekendDays.contains(day);
              return Semantics(
                button: true,
                selected: selected,
                label: day,
                child: InkWell(
                  onTap: () => controller.toggleWeekendDay(day),
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    height: 38,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryLight
                          : AppColors.surface,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.borderStrong,
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.field),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 16,
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.iconMuted,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          day.substring(0, 3),
                          style: AppTextStyles.checkboxLabel.copyWith(
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATUTORY RULES',
                style: AppTextStyles.badge.copyWith(
                  color: AppColors.primaryDark,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Employment entitlements',
                style: AppTextStyles.heading(fontSize: 20),
              ),
            ],
          ),
        ),
        Text('7 policy areas', style: AppTextStyles.listCount),
      ],
    );
  }
}

class _EntitlementGrid extends GetView<LegislationController> {
  const _EntitlementGrid();

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _PolicyCard(
        icon: Icons.medical_services_outlined,
        title: 'Sick Leave',
        description: 'Annual medical leave entitlement',
        child: _ResponsiveFields(
          children: [
            _NumberField(
              label: 'Paid days',
              textController: controller.paidSickLeaveDays,
              integer: true,
            ),
            _NumberField(
              label: 'Half-paid days',
              textController: controller.halfPaidSickLeaveDays,
              integer: true,
            ),
            _NumberField(
              label: 'Unpaid days',
              textController: controller.unpaidSickLeaveDays,
              integer: true,
            ),
          ],
        ),
      ),
      _PolicyCard(
        icon: Icons.family_restroom_outlined,
        title: 'Family Leave',
        description: 'Maternity, paternity, and compassionate leave',
        child: _ResponsiveFields(
          children: [
            _NumberField(
              label: 'Maternity paid days',
              textController: controller.maternityLeaveDays,
              integer: true,
            ),
            _NumberField(
              label: 'Paternity paid days',
              textController: controller.paternityLeaveDays,
              integer: true,
            ),
            _NumberField(
              label: 'Compassionate paid days',
              textController: controller.compassionateLeaveDays,
              integer: true,
            ),
          ],
        ),
      ),
      _PolicyCard(
        icon: Icons.schedule_outlined,
        title: 'Overtime',
        description: 'Working hours used for overtime calculations',
        child: _ResponsiveFields(
          children: [
            _NumberField(
              label: 'Normal working hours',
              textController: controller.normalOvertimeHours,
            ),
            _NumberField(
              label: 'Holiday working hours',
              textController: controller.holidayOvertimeHours,
            ),
          ],
        ),
      ),
      _PolicyCard(
        icon: Icons.workspace_premium_outlined,
        title: 'Gratuity',
        description: 'End-of-service days per completed year',
        child: _ResponsiveFields(
          children: [
            _NumberField(
              label: 'First 5 years',
              textController: controller.gratuityFirstFiveYears,
              integer: true,
            ),
            _NumberField(
              label: 'After 5 years',
              textController: controller.gratuityAfterFiveYears,
              integer: true,
            ),
          ],
        ),
      ),
      _PolicyCard(
        icon: Icons.receipt_long_outlined,
        title: 'Service Tax',
        description: 'Flat tax applied to eligible earnings',
        child: _NumberField(
          label: 'Service tax percentage',
          textController: controller.serviceTaxPercentage,
          suffix: '%',
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        final columns = constraints.maxWidth >= 820 ? 2 : 1;
        final width = columns == 2
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.contentCard,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.softSurface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadii.field),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primaryDark),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.sectionTitle),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(description, style: AppTextStyles.listCount),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
        ],
      ),
    );
  }
}

class _SocialSecurityCard extends GetView<LegislationController> {
  const _SocialSecurityCard();

  @override
  Widget build(BuildContext context) {
    return _PolicyCard(
      icon: Icons.percent_rounded,
      title: 'Social Security',
      description: 'Employee, employer, and dated ceiling configuration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DynamicSectionHeader(
            title: 'Ceiling lines',
            description:
                'Add a separate effective period for every ceiling amount.',
            actionLabel: 'Add new line',
            onPressed: controller.addSocialSecurityCeiling,
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => Column(
              children: controller.socialSecurityCeilings.asMap().entries.map((
                entry,
              ) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _SocialSecurityLine(
                    index: entry.key,
                    line: entry.value,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialSecurityLine extends GetView<LegislationController> {
  const _SocialSecurityLine({required this.index, required this.line});

  final int index;
  final SocialSecurityCeilingFields line;

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      _NumberField(
        label: 'Employee percentage',
        textController: line.employeePercentage,
        suffix: '%',
      ),
      _NumberField(
        label: 'Employer percentage',
        textController: line.employerPercentage,
        suffix: '%',
      ),
      _NumberField(label: 'Ceiling', textController: line.ceiling),
      _DateField(label: 'Start date', textController: line.startDate),
      _DateField(
        label: 'End date',
        textController: line.endDate,
        hintText: 'No end date',
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.softSurface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final lineNumber = Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadii.field),
            ),
            child: Text(
              '${index + 1}',
              style: AppTextStyles.badge.copyWith(color: AppColors.primaryDark),
            ),
          );
          final remove = IconButton(
            tooltip: 'Remove ceiling line',
            onPressed: () => controller.removeSocialSecurityCeiling(index),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.error,
              hoverColor: AppColors.dangerBackground,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
          );
          if (constraints.maxWidth < 980) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [lineNumber, const Spacer(), remove]),
                const SizedBox(height: AppSpacing.xs),
                _ResponsiveFields(children: fields),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: lineNumber,
              ),
              const SizedBox(width: AppSpacing.sm),
              for (var i = 0; i < fields.length; i++) ...[
                Expanded(child: fields[i]),
                if (i < fields.length - 1) const SizedBox(width: AppSpacing.sm),
              ],
              remove,
            ],
          );
        },
      ),
    );
  }
}

class _IncomeTaxCard extends GetView<LegislationController> {
  const _IncomeTaxCard();

  @override
  Widget build(BuildContext context) {
    return _PolicyCard(
      icon: Icons.account_balance_outlined,
      title: 'Income Tax',
      description: 'Fallback values and progressive income tax brackets',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResponsiveFields(
            children: [
              _NumberField(
                label: 'Fallback percentage',
                textController: controller.incomeTaxPercentage,
                suffix: '%',
              ),
              _NumberField(
                label: 'Fallback ceiling',
                textController: controller.incomeTaxCeiling,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Divider(),
          ),
          _DynamicSectionHeader(
            title: 'Tax brackets',
            description:
                'Progressive rates are applied from the lowest band upward.',
            actionLabel: 'Add bracket',
            onPressed: controller.addIncomeTaxBracket,
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => Column(
              children: controller.incomeTaxBrackets.asMap().entries.map((
                entry,
              ) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _TaxBracketLine(
                    index: entry.key,
                    bracket: entry.value,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxBracketLine extends GetView<LegislationController> {
  const _TaxBracketLine({required this.index, required this.bracket});

  final int index;
  final IncomeTaxBracketFields bracket;

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      _NumberField(label: 'From', textController: bracket.fromAmount),
      _NumberField(
        label: 'To',
        textController: bracket.toAmount,
        hintText: 'No limit',
      ),
      _NumberField(
        label: 'Percentage',
        textController: bracket.percentage,
        suffix: '%',
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.softSurface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final remove = IconButton(
            tooltip: 'Remove tax bracket',
            onPressed: () => controller.removeIncomeTaxBracket(index),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.error,
              hoverColor: AppColors.dangerBackground,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
          );
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ResponsiveFields(children: fields),
                Align(alignment: Alignment.centerRight, child: remove),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                Expanded(child: fields[i]),
                if (i < fields.length - 1) const SizedBox(width: AppSpacing.sm),
              ],
              remove,
            ],
          );
        },
      ),
    );
  }
}

class _DynamicSectionHeader extends StatelessWidget {
  const _DynamicSectionHeader({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.xxs),
            Text(description, style: AppTextStyles.listCount),
          ],
        );
        final action = TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(actionLabel),
        );
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copy,
              const SizedBox(height: AppSpacing.xs),
              action,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: copy),
            const SizedBox(width: AppSpacing.md),
            action,
          ],
        );
      },
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final maxColumns = constraints.maxWidth >= 560
            ? 3
            : constraints.maxWidth >= 340
            ? 2
            : 1;
        final columns = math.min(children.length, maxColumns);
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.textController,
    this.integer = false,
    this.suffix,
    this.hintText = '0',
  });

  final String label;
  final TextEditingController textController;
  final bool integer;
  final String? suffix;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: label,
      hintText: hintText,
      controller: textController,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      validator: integer
          ? Get.find<LegislationController>().integerValue
          : Get.find<LegislationController>().decimalValue,
      suffixIcon: suffix == null
          ? null
          : SizedBox(
              width: 38,
              child: Center(
                child: Text(
                  suffix!,
                  style: AppTextStyles.fieldLabel.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.textController,
    this.hintText = 'DD-MM-YYYY',
  });

  final String label;
  final TextEditingController textController;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return AppDateFormField(
      label: label,
      hintText: hintText,
      controller: textController,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      helpText: 'Select effective date',
      parseDate: parseLegislationDate,
      formatDate: formatLegislationDate,
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: AppColors.iconMuted,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Changes are applied after the legislation is saved.',
            style: AppTextStyles.listCount,
          ),
        ),
      ],
    );
  }
}
