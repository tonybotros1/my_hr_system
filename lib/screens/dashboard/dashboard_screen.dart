import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/dashboard_controllers/dashboard_controller.dart';
import '../../controllers/main_controllers/main_screen_controller.dart';
import '../../models/dashboard/dashboard_snapshot.dart';
import '../../models/company/company_identity_model.dart';
import '../../routes/app_routes.dart';
import '../../services/hr_access_service.dart';
import '../../services/theme_controller.dart';
import '../../widgets/dashboard/dashboard_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController controller;
  @override
  void initState() {
    super.initState();
    controller = Get.find<DashboardController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(controller.refreshDashboard());
    });
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    // Read observables here, before LayoutBuilder runs its deferred callback.
    final data = controller.snapshot.value;
    final loading = controller.isLoading.value;
    final error = controller.errorMessage.value;
    final month = controller.calendarMonth.value;
    final company = Get.find<MainScreenController>().company.value;
    Get.find<ThemeController>().selectedPaletteId.value;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final wide = constraints.maxWidth >= 980;
        return ColoredBox(
          color: AppColors.mainCanvas,
          child: RefreshIndicator(
            onRefresh: controller.refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 30,
                26,
                compact ? 16 : 30,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Dashboard',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.pageHeading.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 24),
                      _WelcomeBanner(
                        company: company,
                        data: data,
                        compact: compact,
                        onOpen: controller.openScreen,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'WORKSPACE AT A GLANCE',
                              style: AppTextStyles.tableHeader.copyWith(
                                fontSize: 10,
                                letterSpacing: 1.6,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Tooltip(
                            message: data == null
                                ? 'Refresh dashboard'
                                : 'Last updated ${_time(data.loadedAt)}',
                            child: TextButton.icon(
                              onPressed: loading
                                  ? null
                                  : controller.refreshDashboard,
                              icon: loading
                                  ? SizedBox.square(
                                      dimension: 13,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.8,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded, size: 16),
                              label: Text(loading ? 'Refreshing' : 'Refresh'),
                            ),
                          ),
                        ],
                      ),
                      if (error != null ||
                          (data?.errors.isNotEmpty ?? false)) ...[
                        _RefreshNotice(
                          message:
                              error ??
                              'Some information could not be loaded. You can still use the available sections.',
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (data == null) ...[
                        _DashboardLoading(failed: error != null),
                      ] else ...[
                        _SummaryCards(
                          data: data,
                          onOpen: controller.openScreen,
                        ),
                        const SizedBox(height: 20),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: _MainColumn(
                                  data: data,
                                  onOpen: controller.openScreen,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 5,
                                child: _SideColumn(
                                  data: data,
                                  month: month,
                                  controller: controller,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _MainColumn(
                            data: data,
                            onOpen: controller.openScreen,
                          ),
                          const SizedBox(height: 20),
                          _SideColumn(
                            data: data,
                            month: month,
                            controller: controller,
                          ),
                        ],
                        const SizedBox(height: 20),
                        _QuickLinks(data: data, onOpen: controller.openScreen),
                        const SizedBox(height: 20),
                        Text(
                          'Workspace overview  •  Refreshed ${_time(data.loadedAt)}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.footer,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  });
}

String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.company,
    required this.data,
    required this.compact,
    required this.onOpen,
  });
  final CompanyIdentityModel? company;
  final DashboardSnapshot? data;
  final bool compact;
  final Future<void> Function(String) onOpen;

  @override
  Widget build(BuildContext context) {
    final now = data?.loadedAt ?? DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final name =
        company?.userName.trim().split(RegExp(r'\s+')).firstOrNull ?? '';
    final route = (data?.canOpen('/employees') ?? false)
        ? '/employees'
        : (data?.canOpen('/payrollruns') ?? false)
        ? '/payrollruns'
        : null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [AppColors.sidebarBackground, AppColors.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: DashboardHeroArtwork(Colors.white.withValues(alpha: .1)),
        child: Padding(
          padding: EdgeInsets.all(compact ? 24 : 30),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (company?.displayCompanyName ?? 'YOUR WORKSPACE')
                          .toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: Colors.white.withValues(alpha: .65),
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      '$greeting${name.isEmpty ? '' : ', $name'}.',
                      style: AppTextStyles.pageHeading.copyWith(
                        fontSize: compact ? 25 : 31,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your people, your priorities. All in one place.',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: .75),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (route != null)
                      TextButton.icon(
                        onPressed: () => unawaited(onOpen(route)),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .12),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_outward_rounded, size: 15),
                        label: Text(
                          route == '/employees'
                              ? 'Employee directory'
                              : 'Open payroll runs',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    if (compact)
                      Text(
                        '${dashboardWeekdays[now.weekday - 1]}, ${dashboardDateLabel(now)}',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: .6),
                        ),
                      ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 30),
                Container(
                  width: 155,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 17,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .07),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .14),
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dashboardWeekdays[now.weekday - 1].toUpperCase(),
                        style: AppTextStyles.fieldLabel.copyWith(
                          color: Colors.white.withValues(alpha: .7),
                          fontSize: 9,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        now.day.toString().padLeft(2, '0'),
                        style: AppTextStyles.pageHeading.copyWith(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${dashboardMonthNames[now.month - 1]} ${now.year}',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: .7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.data, required this.onOpen});
  final DashboardSnapshot data;
  final Future<void> Function(String) onOpen;
  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (data.canOpen('/employees')) ...[
        DashboardMetricCard(
          label: 'Active employees',
          value: data.employees == null
              ? '—'
              : '${data.activeEmployees.length}',
          detail: data.employees == null
              ? 'Temporarily unavailable'
              : 'Employed as of today',
          icon: Icons.people_outline_rounded,
          onTap: () => unawaited(onOpen('/employees')),
        ),
        DashboardMetricCard(
          label: 'New starters',
          value: data.employees == null ? '—' : '${data.joinedThisMonth}',
          detail:
              'Joined in ${dashboardMonthNames[data.today.month - 1]} so far',
          icon: Icons.person_add_alt_1_outlined,
          onTap: () => unawaited(onOpen('/employees')),
        ),
      ],
      if (data.canOpen('/payrollruns'))
        DashboardMetricCard(
          label: 'Payroll runs',
          value: data.payrollRuns == null ? '—' : '${data.payrollRuns!.length}',
          detail: 'All recorded payroll runs',
          icon: Icons.receipt_long_outlined,
          onTap: () => unawaited(onOpen('/payrollruns')),
        ),
      if (data.canOpen('/publicholidays'))
        DashboardMetricCard(
          label: 'Upcoming holidays',
          value: data.holidays == null ? '—' : '${data.holidaysNext90Days}',
          detail: 'Within the next 90 days',
          icon: Icons.event_available_outlined,
          onTap: () => unawaited(onOpen('/publicholidays')),
        ),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 880
            ? cards.length
            : constraints.maxWidth >= 500
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({required this.data, required this.onOpen});
  final DashboardSnapshot data;
  final Future<void> Function(String) onOpen;
  Widget _link(String label, String route) => TextButton(
    onPressed: () => unawaited(onOpen(route)),
    child: Text(label, style: AppTextStyles.link.copyWith(fontSize: 11)),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (data.canOpen('/employees')) ...[
        DashboardPanel(
          title: 'Hiring overview',
          caption: 'A six-month look at your new starters',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${data.today.year}',
              style: AppTextStyles.link.copyWith(fontSize: 11),
            ),
          ),
          child: data.employees == null
              ? DashboardEmptyState(message: data.errors['/employees']!)
              : DashboardHiringChart(months: data.hiringMonths),
        ),
        const SizedBox(height: 20),
      ],
      if (data.canOpen('/payrollruns')) ...[
        DashboardPanel(
          title: 'Payroll activity',
          caption: 'Latest payroll periods recorded in your company',
          trailing: _link('View all ↗', '/payrollruns'),
          child: data.payrollRuns == null
              ? DashboardEmptyState(message: data.errors['/payrollruns']!)
              : data.payrollRuns!.isEmpty
              ? const DashboardEmptyState(
                  message:
                      'No payroll runs yet. Your recorded runs will appear here.',
                  icon: Icons.receipt_long_outlined,
                )
              : Column(
                  children: [
                    for (final (index, run)
                        in data.payrollRuns!.take(4).indexed)
                      Column(
                        children: [
                          if (index > 0)
                            const Divider(height: 25, color: AppColors.divider),
                          InkWell(
                            onTap: () => unawaited(onOpen('/payrollruns')),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      color: AppColors.primaryDark,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          run.payrollName.isEmpty
                                              ? 'Payroll run'
                                              : run.payrollName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.fieldLabel,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Run ${run.runNumber.isEmpty ? '—' : run.runNumber}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodyMuted
                                              .copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      run.periodName.isEmpty
                                          ? 'No period'
                                          : run.periodName,
                                      textAlign: TextAlign.right,
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 17,
                                    color: AppColors.iconMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
      ],
      if (data.canOpen('/employees'))
        DashboardPanel(
          title: 'Recent starters',
          caption: 'The latest people to join your company',
          trailing: _link('Directory ↗', '/employees'),
          child: data.employees == null
              ? DashboardEmptyState(message: data.errors['/employees']!)
              : data.recentStarters.isEmpty
              ? const DashboardEmptyState(
                  message: 'Employees with a hire date will appear here.',
                  icon: Icons.person_add_alt_1_outlined,
                )
              : Column(
                  children: [
                    for (final (index, employee) in data.recentStarters.indexed)
                      Column(
                        children: [
                          if (index > 0)
                            const Divider(height: 22, color: AppColors.divider),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  employee.fullName.isEmpty
                                      ? '?'
                                      : employee.fullName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                  style: AppTextStyles.fieldLabel.copyWith(
                                    color: AppColors.primaryDark,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      employee.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.fieldLabel,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      employee.departmentName.isEmpty
                                          ? 'Department not assigned'
                                          : employee.departmentName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodyMuted.copyWith(
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                dashboardDateLabel(employee.hireDate!),
                                style: AppTextStyles.bodyMuted.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      if (!data.canOpen('/employees') && !data.canOpen('/payrollruns'))
        const DashboardPanel(
          title: 'Welcome to your workspace',
          caption: 'Everything you have access to, in one place',
          child: DashboardEmptyState(
            message:
                'Use the shortcuts below or the sidebar to open your available HR screens.',
            icon: Icons.space_dashboard_outlined,
          ),
        ),
    ],
  );
}

class _SideColumn extends StatelessWidget {
  const _SideColumn({
    required this.data,
    required this.month,
    required this.controller,
  });
  final DashboardSnapshot data;
  final DateTime month;
  final DashboardController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (data.canOpen('/employees')) ...[
        DashboardPanel(
          title: 'Your workforce',
          caption: 'Active employees by department',
          child: data.employees == null
              ? DashboardEmptyState(message: data.errors['/employees']!)
              : data.activeEmployees.isEmpty
              ? const DashboardEmptyState(
                  message: 'No active employees to display yet.',
                  icon: Icons.groups_outlined,
                )
              : DashboardDepartments(
                  departments: data.departments,
                  total: data.activeEmployees.length,
                ),
        ),
        const SizedBox(height: 20),
      ],
      DashboardPanel(
        title: 'On the calendar',
        caption: data.canOpen('/publicholidays')
            ? 'Public holidays across your company’s legislations'
            : 'A little space to plan ahead',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardCalendar(
              month: month,
              today: data.today,
              holidays: data.holidays ?? [],
              onPrevious: () => controller.changeCalendarMonth(-1),
              onNext: () => controller.changeCalendarMonth(1),
              onToday: controller.showCurrentMonth,
            ),
            if (data.canOpen('/publicholidays')) ...[
              const Divider(height: 32, color: AppColors.divider),
              Text(
                'COMING UP',
                style: AppTextStyles.tableHeader.copyWith(
                  fontSize: 9,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              if (data.holidays == null)
                Text(
                  data.errors['/publicholidays']!,
                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                )
              else if (data.upcomingHolidays.isEmpty)
                Text(
                  'No upcoming public holidays have been added.',
                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                )
              else
                for (final holiday in data.upcomingHolidays.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                dashboardMonthNames[holiday.date.month - 1]
                                    .substring(0, 3)
                                    .toUpperCase(),
                                style: AppTextStyles.fieldLabel.copyWith(
                                  fontSize: 8,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              Text(
                                '${holiday.date.day}',
                                style: AppTextStyles.pageHeading.copyWith(
                                  fontSize: 19,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                holiday.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.fieldLabel,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dashboardDateLabel(holiday.date),
                                style: AppTextStyles.bodyMuted.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () =>
                      unawaited(controller.openScreen('/publicholidays')),
                  child: const Text('Open public holidays ↗'),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks({required this.data, required this.onOpen});
  final DashboardSnapshot data;
  final Future<void> Function(String) onOpen;
  @override
  Widget build(BuildContext context) {
    final links = HrAccessPolicy.supportedScreens.where(
      (screen) => data.canOpen(screen.routeName),
    );
    return DashboardPanel(
      title: 'Make your next move',
      caption: 'Shortcuts to your available screens',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final link in links)
            OutlinedButton.icon(
              onPressed: () => unawaited(onOpen(link.routeName)),
              label: Text(link.name, style: const TextStyle(fontSize: 12)),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_outward_rounded, size: 14),
            ),
          if (data.canOpen('/users'))
            OutlinedButton.icon(
              onPressed: () => unawaited(onOpen('/users')),
              label: const Text('Manage users', style: TextStyle(fontSize: 12)),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_outward_rounded, size: 14),
            ),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed<void>(AppRoutes.settings),
            label: const Text(
              'Customize workspace',
              style: TextStyle(fontSize: 12),
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.palette_outlined, size: 14),
          ),
        ],
      ),
    );
  }
}

class _RefreshNotice extends StatelessWidget {
  const _RefreshNotice({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: AppColors.warning,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading({required this.failed});
  final bool failed;
  @override
  Widget build(BuildContext context) => Container(
    height: 280,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!failed)
            SizedBox.square(
              dimension: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            failed
                ? 'Use Refresh to try again.'
                : 'Bringing your workspace together…',
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    ),
  );
}
