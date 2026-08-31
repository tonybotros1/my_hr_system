import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/payroll/public_holiday_model.dart';

class PublicHolidayMonthCard extends StatelessWidget {
  const PublicHolidayMonthCard({
    required this.year,
    required this.monthName,
    required this.weekdayNames,
    required this.days,
    required this.holidayFor,
    required this.onDaySelected,
    super.key,
  });

  final int year;
  final String monthName;
  final List<String> weekdayNames;
  final List<DateTime?> days;
  final PublicHolidayModel? Function(DateTime date) holidayFor;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.section),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      monthName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading(fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.segmentBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$year',
                      style: AppTextStyles.tableHeader.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: weekdayNames
                    .map(
                      (weekday) => Expanded(
                        child: Center(
                          child: Text(
                            weekday,
                            style: AppTextStyles.tableHeader.copyWith(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: days.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                  ),
                  itemBuilder: (context, index) {
                    final date = days[index];
                    if (date == null) return const SizedBox.shrink();
                    final holiday = holidayFor(date);
                    return _CalendarDay(
                      date: date,
                      holiday: holiday,
                      onPressed: () => onDaySelected(date),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.holiday,
    required this.onPressed,
  });

  final DateTime date;
  final PublicHolidayModel? holiday;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isHoliday = holiday != null;
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final label = isHoliday
        ? '${holiday!.name}, ${formatPublicHolidayDate(date)}'
        : 'Add holiday on ${formatPublicHolidayDate(date)}';
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: isHoliday ? AppColors.primaryLight : AppColors.softSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: BorderSide(
              color: isToday
                  ? AppColors.warning
                  : isHoliday
                  ? AppColors.borderStrong
                  : AppColors.border,
              width: isToday ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            hoverColor: AppColors.primaryLight,
            child: Stack(
              children: [
                Positioned(
                  left: 7,
                  top: 5,
                  child: Text(
                    '${date.day}',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isHoliday
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isHoliday)
                  const Positioned(
                    right: 6,
                    bottom: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: 6),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
