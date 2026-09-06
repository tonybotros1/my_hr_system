import 'package:get/get.dart';

import '../../models/dashboard/dashboard_snapshot.dart';
import '../../models/employees/employee_model.dart';
import '../../models/payroll/payroll_run_model.dart';
import '../../models/payroll/public_holiday_model.dart';
import '../../models/navigation/navigation_item_model.dart';
import '../../routes/app_routes.dart';
import '../../services/authenticated_api_service.dart';
import '../../services/hr_access_service.dart';

class DashboardController extends GetxController {
  DashboardController({
    AuthenticatedApiService? api,
    HrAccessService? access,
    DateTime Function()? clock,
  }) : _apiOverride = api,
       _accessOverride = access,
       _clock = clock ?? DateTime.now;

  final AuthenticatedApiService? _apiOverride;
  final HrAccessService? _accessOverride;
  final DateTime Function() _clock;
  final snapshot = Rxn<DashboardSnapshot>();
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final calendarMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();
  HrAccessService get _access => _accessOverride ?? Get.find<HrAccessService>();

  Future<void> refreshDashboard() async {
    if (isLoading.value || isClosed) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final access = await _access.load();
      if (!access.hasHrResponsibility) throw const SessionExpiredException();
      final routes = <String>{};
      void collect(Iterable<NavigationItemModel> items) {
        for (final item in items) {
          if (item.canOpen) {
            routes.add(AppRoutes.normalizeMenuRoute(item.routeName));
          }
          collect(item.children);
        }
      }

      collect(access.navigationItems);
      final errors = <String, String>{};
      Future<List<T>?> section<T>(
        String route,
        String path,
        String key,
        T Function(Map<String, dynamic>) parse, {
        bool post = false,
      }) async {
        if (!routes.contains(AppRoutes.normalizeMenuRoute(route))) return null;
        try {
          final response = post
              ? await _api.postJson(path, body: {})
              : await _api.getJson(path);
          final raw = response[key];
          if (raw is! List || raw.any((item) => item is! Map)) {
            throw const FormatException('Invalid dashboard summary');
          }
          return raw
              .map((item) => parse(Map<String, dynamic>.from(item as Map)))
              .toList();
        } on SessionExpiredException {
          rethrow;
        } catch (_) {
          errors[route] =
              'This section could not be loaded. Refresh to try again.';
          return null;
        }
      }

      final results = await Future.wait<Object?>([
        section(
          '/employees',
          '/employees/get_all_employees',
          'employees',
          EmployeeSummary.fromJson,
        ),
        section(
          '/payrollruns',
          '/payroll_runs/get_all_payroll_runs',
          'payroll_runs',
          PayrollRunSummary.fromJson,
        ),
        section(
          '/publicholidays',
          '/public_holidays/get_all_holidays',
          'holidays',
          PublicHolidayModel.fromJson,
          post: true,
        ),
      ]);
      if (isClosed) return;
      final now = _clock();
      if (snapshot.value == null) {
        calendarMonth.value = DateTime(now.year, now.month);
      }
      snapshot.value = DashboardSnapshot(
        loadedAt: now,
        allowedRoutes: routes,
        employees: results[0] as List<EmployeeSummary>?,
        payrollRuns: results[1] as List<PayrollRunSummary>?,
        holidays: results[2] as List<PublicHolidayModel>?,
        errors: errors,
      );
    } on SessionExpiredException {
      snapshot.value = null;
      if (!isClosed) Get.offAllNamed(AppRoutes.login);
    } catch (_) {
      errorMessage.value =
          'We could not refresh your dashboard. Please try again.';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void changeCalendarMonth(int offset) {
    final month = calendarMonth.value;
    calendarMonth.value = DateTime(month.year, month.month + offset);
  }

  void showCurrentMonth() {
    final now = _clock();
    calendarMonth.value = DateTime(now.year, now.month);
  }

  Future<void> openScreen(String route) async {
    if (!(snapshot.value?.canOpen(route) ?? false)) return;
    await Get.toNamed<void>(AppRoutes.screenPathForMenuRoute(route));
    if (!isClosed) await refreshDashboard();
  }
}
