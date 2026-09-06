@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_hr_system/consts.dart';
import 'package:my_hr_system/controllers/dashboard_controllers/dashboard_controller.dart';
import 'package:my_hr_system/controllers/main_controllers/main_screen_controller.dart';
import 'package:my_hr_system/models/dashboard/dashboard_snapshot.dart';
import 'package:my_hr_system/models/employees/employee_model.dart';
import 'package:my_hr_system/models/payroll/public_holiday_model.dart';
import 'package:my_hr_system/models/settings/app_color_palette.dart';
import 'package:my_hr_system/screens/dashboard/dashboard_screen.dart';
import 'package:my_hr_system/services/theme_controller.dart';
import 'package:my_hr_system/widgets/dashboard/dashboard_widgets.dart';
import 'support/dashboard_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    AppColors.applyPalette(AppColorPalettes.dataHub);
  });
  tearDown(() {
    Get.reset();
    AppColors.applyPalette(AppColorPalettes.dataHub);
  });

  test(
    'headcount and monthly hires respect future starts and contract end dates',
    () {
      final data = DashboardSnapshot(
        loadedAt: dashboardTestDate,
        allowedRoutes: {'employees'},
        employees: [
          {
            '_id': 'active',
            'hire_date': '2026-09-01',
            'department_name': 'Operations',
          },
          {'_id': 'future', 'hire_date': '2026-09-06'},
          {'_id': 'ended', 'hire_date': '2025-01-01', 'end_date': '2026-09-04'},
          {
            '_id': 'ends-today',
            'hire_date': '2026-08-01',
            'end_date': '2026-09-05',
          },
          {'_id': 'applicant'},
        ].map(EmployeeSummary.fromJson).toList(),
      );
      expect(data.activeEmployees.map((item) => item.id), [
        'active',
        'ends-today',
      ]);
      expect(data.joinedThisMonth, 1);
      expect(data.hiringMonths.map((item) => item.hires), [0, 0, 0, 0, 1, 1]);
      expect(data.departments.fold<int>(0, (sum, item) => sum + item.count), 2);
      expect(
        data.recentStarters.map((item) => item.id),
        isNot(contains('future')),
      );
    },
  );

  test(
    'holiday summaries include today and cross the year boundary correctly',
    () {
      final data = DashboardSnapshot(
        loadedAt: DateTime(2026, 12, 31),
        allowedRoutes: {'publicholidays'},
        holidays: [
          {'_id': 'past', 'name': 'Past', 'date': '2026-12-30'},
          {'_id': 'today', 'name': 'Today', 'date': '2026-12-31'},
          {'_id': 'new-year', 'name': 'New year', 'date': '2027-01-01'},
          {'_id': 'later', 'name': 'Later', 'date': '2027-07-01'},
        ].map(PublicHolidayModel.fromJson).toList(),
      );
      expect(data.holidaysNext90Days, 2);
      expect(data.upcomingHolidays.first.id, 'today');
      expect(data.hiringMonths.first.date, DateTime(2026, 7));
    },
  );

  test(
    'controller skips endpoints for screens the user cannot access',
    () async {
      final api = DashboardApiFixture();
      final access = DashboardAccessFixture(routes: ['/publicholidays']);
      final controller = DashboardController(
        api: api,
        access: access,
        clock: () => dashboardTestDate,
      );
      await controller.refreshDashboard();
      expect(api.calls, ['/public_holidays/get_all_holidays']);
      expect(controller.snapshot.value!.employees, isNull);
      expect(controller.snapshot.value!.canOpen('/employees'), isFalse);
      expect(controller.snapshot.value!.holidaysNext90Days, 2);
      access.routes = [];
      api.calls.clear();
      await controller.refreshDashboard();
      expect(api.calls, isEmpty);
      expect(controller.snapshot.value!.holidays, isNull);
    },
  );

  test(
    'one unavailable section preserves successful data and can recover',
    () async {
      final api = DashboardApiFixture()..failEmployees = true;
      final controller = DashboardController(
        api: api,
        access: DashboardAccessFixture(),
        clock: () => dashboardTestDate,
      );
      await controller.refreshDashboard();
      expect(controller.snapshot.value!.employees, isNull);
      expect(controller.snapshot.value!.errors, contains('/employees'));
      expect(controller.snapshot.value!.payrollRuns, hasLength(4));
      api.failEmployees = false;
      await controller.refreshDashboard();
      expect(controller.snapshot.value!.employees, hasLength(24));
      expect(controller.snapshot.value!.errors, isEmpty);
      api.malformedEmployees = true;
      await controller.refreshDashboard();
      expect(controller.snapshot.value!.employees, isNull);
      expect(controller.snapshot.value!.errors, contains('/employees'));
    },
  );

  for (final width in [1440.0, 900.0, 390.0, 320.0]) {
    testWidgets(
      'dashboard renders, refreshes and changes theme at width $width',
      (tester) async {
        final originalErrorHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          // Browser tests otherwise hide framework overflow diagnostics.
          // ignore: avoid_print
          print(details.toString());
          originalErrorHandler?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalErrorHandler);
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = DashboardApiFixture();
        final controller = DashboardController(
          api: api,
          access: DashboardAccessFixture(),
          clock: () => dashboardTestDate,
        );
        Get.put(controller);
        Get.put<MainScreenController>(DashboardShellFixture());
        final theme = Get.put(ThemeController());
        await tester.pumpWidget(
          GetMaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: DashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Good morning, Alex.'), findsOneWidget);
        expect(find.byType(DashboardMetricCard), findsNWidgets(4));
        if (width == 1440) {
          await tester.ensureVisible(find.byTooltip('Next month'));
          await tester.tap(find.byTooltip('Next month'));
          await tester.pumpAndSettle();
          expect(controller.calendarMonth.value, DateTime(2026, 10));
          await tester.tap(find.byTooltip('Previous month'));
          await tester.pumpAndSettle();
          expect(controller.calendarMonth.value, DateTime(2026, 9));
        }
        final headcount = find.ancestor(
          of: find.text('Active employees'),
          matching: find.byType(DashboardMetricCard),
        );
        expect(
          find.descendant(of: headcount, matching: find.text('24')),
          findsOneWidget,
        );
        await theme.selectPalette(AppColorPalettes.ocean.id);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final hero = tester.widget<CustomPaint>(
          find.byWidgetPredicate(
            (widget) =>
                widget is CustomPaint && widget.painter is DashboardHeroArtwork,
          ),
        );
        expect(hero.painter, isA<DashboardHeroArtwork>());
        api.employeeRows.clear();
        await controller.refreshDashboard();
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: headcount, matching: find.text('0')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'empty and restricted dashboards do not expose forbidden shortcuts',
    (tester) async {
      final api = DashboardApiFixture()..empty = true;
      Get.put(
        DashboardController(
          api: api,
          access: DashboardAccessFixture(routes: []),
          clock: () => dashboardTestDate,
        ),
      );
      Get.put<MainScreenController>(DashboardShellFixture());
      Get.put(ThemeController());
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.calls, isEmpty);
      expect(find.byType(DashboardMetricCard), findsNothing);
      expect(find.text('Employee directory'), findsNothing);
      expect(find.text('Manage users'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dashboard shortcut navigates and refreshes after browser-style back',
    (tester) async {
      final api = DashboardApiFixture();
      Get.put(
        DashboardController(
          api: api,
          access: DashboardAccessFixture(),
          clock: () => dashboardTestDate,
        ),
      );
      final shell = Get.put<MainScreenController>(DashboardShellFixture());
      Get.put(ThemeController());
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: shell.getScreenFromRoute(null)),
          getPages: [
            GetPage(
              name: '/mainScreen/employees',
              page: () => const Scaffold(body: Text('Employee destination')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
      await tester.tap(find.text('Employee directory'));
      await tester.pumpAndSettle();
      expect(find.text('Employee destination'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(
        api.calls
            .where((path) => path == '/employees/get_all_employees')
            .length,
        2,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
