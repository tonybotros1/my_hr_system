import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../consts.dart';
import '../../models/dashboard/dashboard_snapshot.dart';
import '../../models/payroll/public_holiday_model.dart';

const dashboardMonthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const dashboardWeekdays = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
String dashboardDateLabel(DateTime date) =>
    '${date.day} ${dashboardMonthNames[date.month - 1].substring(0, 3)} ${date.year}';

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    required this.title,
    required this.caption,
    required this.child,
    this.trailing,
    super.key,
  });
  final String title;
  final String caption;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border.withValues(alpha: .75)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x04000000),
          blurRadius: 18,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.pageHeading.copyWith(
                      fontSize: 16,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    caption,
                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
        const SizedBox(height: 22),
        child,
      ],
    ),
  );
}

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.height = 130,
    super.key,
  });
  final String message;
  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: AppColors.iconMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    this.onTap,
    super.key,
  });
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.fieldLabel.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              value,
              style: AppTextStyles.pageHeading.copyWith(
                fontSize: 34,
                letterSpacing: -1.3,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 11),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class DashboardHiringChart extends StatelessWidget {
  const DashboardHiringChart({required this.months, super.key});
  final List<DashboardMonth> months;

  @override
  Widget build(BuildContext context) {
    final maxCount = months.fold<int>(
      1,
      (value, month) => math.max(value, month.hires),
    );
    final total = months.fold<int>(0, (value, month) => value + month.hires);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            Text(
              '$total',
              style: AppTextStyles.pageHeading.copyWith(fontSize: 29),
            ),
            Text(
              'starters in the last 6 months',
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: Stack(
            children: [
              Positioned.fill(
                bottom: 23,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (_) => const Divider(height: 1, color: AppColors.divider),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < months.length; i++)
                    Expanded(
                      child: Tooltip(
                        message:
                            '${dashboardMonthNames[months[i].date.month - 1]} ${months[i].date.year}: ${months[i].hires} starters',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${months[i].hires}',
                                  maxLines: 1,
                                  style: AppTextStyles.fieldLabel.copyWith(
                                    fontSize: 11,
                                    color: i == months.length - 1
                                        ? AppColors.primaryDark
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Container(
                                height: math.max(
                                  3,
                                  105 * months[i].hires / maxCount,
                                ),
                                constraints: const BoxConstraints(maxWidth: 45),
                                decoration: BoxDecoration(
                                  color: i == months.length - 1
                                      ? AppColors.primary
                                      : AppColors.primary.withValues(alpha: .2),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(7),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  dashboardMonthNames[months[i].date.month - 1]
                                      .substring(0, 3),
                                  maxLines: 1,
                                  style: AppTextStyles.bodyMuted.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DashboardDepartments extends StatelessWidget {
  const DashboardDepartments({
    required this.departments,
    required this.total,
    super.key,
  });
  final List<DashboardDepartment> departments;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < departments.length; i++)
        Padding(
          padding: EdgeInsets.only(
            bottom: i == departments.length - 1 ? 0 : 18,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      departments[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.fieldLabel.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${departments[i].count}',
                    style: AppTextStyles.fieldLabel,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 35,
                    child: Text(
                      '${(departments[i].count * 100 / total).round()}%',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: departments[i].count / total,
                  minHeight: 7,
                  backgroundColor: AppColors.primaryLight,
                  color: Color.lerp(
                    AppColors.primaryDark,
                    AppColors.primary.withValues(alpha: .4),
                    i / 5,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class DashboardCalendar extends StatelessWidget {
  const DashboardCalendar({
    required this.month,
    required this.today,
    required this.holidays,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    super.key,
  });
  final DateTime month;
  final DateTime today;
  final List<PublicHolidayModel> holidays;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final count = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final cells = ((offset + count) / 7).ceil() * 7;
    final holidayDays = <int, List<String>>{};
    for (final holiday in holidays) {
      if (holiday.date.year == month.year &&
          holiday.date.month == month.month) {
        holidayDays.putIfAbsent(holiday.date.day, () => []).add(holiday.name);
      }
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${dashboardMonthNames[month.month - 1]} ${month.year}',
                style: AppTextStyles.fieldLabel.copyWith(fontSize: 14),
              ),
            ),
            TextButton(onPressed: onToday, child: const Text('Today')),
            IconButton(
              tooltip: 'Previous month',
              onPressed: onPrevious,
              constraints: const BoxConstraints.tightFor(width: 30, height: 32),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_left_rounded, size: 19),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: onNext,
              constraints: const BoxConstraints.tightFor(width: 30, height: 32),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_right_rounded, size: 19),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            children: [
              for (var index = 0; index < cells; index++)
                SizedBox(
                  width: constraints.maxWidth / 7,
                  height: 36,
                  child: index < offset || index >= offset + count
                      ? null
                      : Builder(
                          builder: (context) {
                            final day = index - offset + 1;
                            final date = DateTime(month.year, month.month, day);
                            final isToday = date == dashboardDay(today);
                            final names = holidayDays[day] ?? [];
                            return Tooltip(
                              message: names.isEmpty
                                  ? dashboardDateLabel(date)
                                  : names.join('\n'),
                              child: Center(
                                child: Container(
                                  width: 31,
                                  height: 31,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? AppColors.primaryDark
                                        : names.isNotEmpty
                                        ? AppColors.primaryLight
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$day',
                                        style: AppTextStyles.fieldLabel
                                            .copyWith(
                                              fontSize: 11,
                                              fontWeight:
                                                  isToday || names.isNotEmpty
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              color: isToday
                                                  ? AppColors.surface
                                                  : AppColors.textPrimary,
                                            ),
                                      ),
                                      if (names.isNotEmpty)
                                        Container(
                                          width: 3,
                                          height: 3,
                                          margin: const EdgeInsets.only(top: 1),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isToday
                                                ? AppColors.surface
                                                : AppColors.primary,
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
            ],
          ),
        ),
      ],
    );
  }
}

/// Quiet background detail; never used to represent dashboard data.
class DashboardHeroArtwork extends CustomPainter {
  DashboardHeroArtwork(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width * .85, size.height * 1.05);
    for (final radius in [80.0, 130.0, 180.0, 230.0]) {
      canvas.drawCircle(center, radius, paint);
    }
    canvas.drawCircle(
      center - const Offset(120, 115),
      4,
      Paint()..color = color.withValues(alpha: .4),
    );
  }

  @override
  bool shouldRepaint(DashboardHeroArtwork oldDelegate) =>
      color != oldDelegate.color;
}
