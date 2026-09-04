import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/public_holidays_controller.dart';
import '../../widgets/drop_down_menu.dart';
import '../../widgets/form_fields/app_text_form_field.dart';
import '../../widgets/public_holidays/public_holiday_editor_dialog.dart';
import '../../widgets/public_holidays/public_holiday_month_card.dart';

class PublicHolidaysScreen extends GetView<PublicHolidaysController> {
  const PublicHolidaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < AppSizes.payrollCompactBreakpoint;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? AppSpacing.md : AppSpacing.xxl,
            compact ? AppSpacing.md : 30,
            compact ? AppSpacing.md : AppSpacing.xxl,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PageHeader(),
              const SizedBox(height: AppSpacing.lg),
              const _HolidayFilters(),
              const SizedBox(height: AppSpacing.md),
              const Expanded(child: _CalendarGrid()),
            ],
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Public Holidays',
          textAlign: TextAlign.center,
          style: AppTextStyles.pageHeading,
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(dimension: 8),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('Public holiday', style: AppTextStyles.listCount),
            ],
          ),
        ),
      ],
    );
  }
}

class _HolidayFilters extends GetView<PublicHolidaysController> {
  const _HolidayFilters();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 820) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 180, child: _YearField()),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(child: _LegislationField()),
                  const SizedBox(width: AppSpacing.sm),
                  const SizedBox(width: 94, child: _FindButton()),
                  const SizedBox(width: AppSpacing.sm),
                  const SizedBox(width: 94, child: _ClearButton()),
                ],
              );
            }
            final singleColumn = constraints.maxWidth < 540;
            final fieldWidth = singleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - AppSpacing.sm) / 2;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(width: fieldWidth, child: const _YearField()),
                SizedBox(width: fieldWidth, child: const _LegislationField()),
                SizedBox(width: fieldWidth, child: const _FindButton()),
                SizedBox(width: fieldWidth, child: const _ClearButton()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _YearField extends GetView<PublicHolidaysController> {
  const _YearField();

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Year',
      hintText: '${DateTime.now().year}',
      controller: controller.yearController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (_) => controller.findHolidays(),
    );
  }
}

class _LegislationField extends GetView<PublicHolidaysController> {
  const _LegislationField();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CustomDropdown(
        key: ValueKey(controller.selectedLegislationId.value),
        width: double.infinity,
        hintText: 'Legislation',
        textcontroller: controller.selectedLegislationName,
        showedSelectedName: 'name',
        items: controller.legislationDropdownItems,
        onOpen: controller.getLegislationsForDropdown,
        onChanged: (key, _) => controller.selectLegislation(key),
        onDelete: controller.clearLegislation,
      ),
    );
  }
}

class _FindButton extends GetView<PublicHolidaysController> {
  const _FindButton();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: AppSizes.inputMinHeight,
        child: FilledButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.findHolidays,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.primaryDark,
            elevation: 0,
          ),
          child: controller.isLoading.value
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Find'),
        ),
      ),
    );
  }
}

class _ClearButton extends GetView<PublicHolidaysController> {
  const _ClearButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.inputMinHeight,
      child: OutlinedButton(
        onPressed: controller.clearFilters,
        child: const Text('Clear'),
      ),
    );
  }
}

class _CalendarGrid extends GetView<PublicHolidaysController> {
  const _CalendarGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final columns = _columnCount(constraints.maxWidth);
          return Stack(
            children: [
              GridView.builder(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                itemCount: PublicHolidaysController.monthNames.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: _monthAspectRatio(columns),
                ),
                itemBuilder: (context, index) {
                  final month = index + 1;
                  return PublicHolidayMonthCard(
                    year: controller.selectedYear.value,
                    monthName: PublicHolidaysController.monthNames[index],
                    weekdayNames: PublicHolidaysController.weekdayNames,
                    days: controller.daysForMonth(month),
                    holidayFor: controller.holidayFor,
                    onDaySelected: (date) => _openEditor(context, date),
                  );
                },
              ),
              if (controller.isLoading.value)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Color(0x33FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
            ],
          );
        });
      },
    );
  }

  int _columnCount(double width) {
    if (width >= AppSizes.publicHolidayFourColumnBreakpoint) return 4;
    if (width >= AppSizes.publicHolidayThreeColumnBreakpoint) return 3;
    if (width >= AppSizes.publicHolidayTwoColumnBreakpoint) return 2;
    return 1;
  }

  double _monthAspectRatio(int columns) {
    return switch (columns) {
      4 => 0.88,
      3 => 0.92,
      2 => 1.05,
      _ => 1.22,
    };
  }

  Future<void> _openEditor(BuildContext context, DateTime date) async {
    if ((controller.selectedLegislationId.value ?? '').isEmpty) {
      await controller.showError(
        'Select a legislation before adding or editing a holiday.',
      );
      return;
    }
    if (!context.mounted) return;
    await showPublicHolidayEditorDialog(
      context,
      date: date,
      holiday: controller.holidayFor(date),
    );
  }
}
