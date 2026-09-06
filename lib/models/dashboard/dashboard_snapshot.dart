import '../employees/employee_model.dart';
import '../payroll/payroll_run_model.dart';
import '../payroll/public_holiday_model.dart';
import '../../routes/app_routes.dart';

DateTime dashboardDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

class DashboardMonth {
  const DashboardMonth(this.date, this.hires);
  final DateTime date;
  final int hires;
}

class DashboardDepartment {
  const DashboardDepartment(this.name, this.count);
  final String name;
  final int count;
}

/// Derived only from the current company's authorized summary responses.
/// A null section means unavailable; an empty list means a successful empty result.
class DashboardSnapshot {
  DashboardSnapshot({
    required this.loadedAt,
    required Set<String> allowedRoutes,
    List<EmployeeSummary>? employees,
    List<PayrollRunSummary>? payrollRuns,
    List<PublicHolidayModel>? holidays,
    Map<String, String> errors = const {},
  }) : allowedRoutes = Set.unmodifiable(allowedRoutes),
       employees = employees == null ? null : List.unmodifiable(employees),
       payrollRuns = payrollRuns == null
           ? null
           : List.unmodifiable(payrollRuns),
       holidays = holidays == null ? null : List.unmodifiable(holidays),
       errors = Map.unmodifiable(errors);

  final DateTime loadedAt;
  final Set<String> allowedRoutes;
  final List<EmployeeSummary>? employees;
  final List<PayrollRunSummary>? payrollRuns;
  final List<PublicHolidayModel>? holidays;
  final Map<String, String> errors;

  DateTime get today => dashboardDay(loadedAt);
  bool canOpen(String route) =>
      allowedRoutes.contains(AppRoutes.normalizeMenuRoute(route));

  List<EmployeeSummary> get activeEmployees =>
      (employees ?? <EmployeeSummary>[])
          .where((employee) {
            final hired = employee.hireDate;
            final ended = employee.endDate;
            return hired != null &&
                !dashboardDay(hired).isAfter(today) &&
                (ended == null || !dashboardDay(ended).isBefore(today));
          })
          .toList(growable: false);

  List<EmployeeSummary> get recentStarters {
    final result = (employees ?? <EmployeeSummary>[])
        .where(
          (employee) =>
              employee.hireDate != null &&
              !dashboardDay(employee.hireDate!).isAfter(today),
        )
        .toList();
    result.sort((a, b) => b.hireDate!.compareTo(a.hireDate!));
    return result.take(5).toList(growable: false);
  }

  List<DashboardMonth> get hiringMonths => List.generate(6, (index) {
    final start = DateTime(today.year, today.month - 5 + index);
    final end = DateTime(start.year, start.month + 1);
    final count = (employees ?? <EmployeeSummary>[]).where((employee) {
      final hired = employee.hireDate;
      if (hired == null) return false;
      final date = dashboardDay(hired);
      return !date.isBefore(start) &&
          date.isBefore(end) &&
          !date.isAfter(today);
    }).length;
    return DashboardMonth(start, count);
  }, growable: false);

  int get joinedThisMonth => hiringMonths.last.hires;

  List<DashboardDepartment> get departments {
    final counts = <String, int>{};
    final names = <String, String>{};
    for (final employee in activeEmployees) {
      final name = employee.departmentName.trim();
      final key = employee.departmentId.isNotEmpty
          ? employee.departmentId
          : name;
      counts[key] = (counts[key] ?? 0) + 1;
      names[key] = name.isEmpty ? 'Unassigned' : name;
    }
    final result = counts.entries
        .map((entry) => DashboardDepartment(names[entry.key]!, entry.value))
        .toList();
    result.sort((a, b) {
      final order = b.count.compareTo(a.count);
      return order == 0 ? a.name.compareTo(b.name) : order;
    });
    if (result.length <= 5) return result;
    return [
      ...result.take(4),
      DashboardDepartment(
        'Other departments',
        result.skip(4).fold(0, (sum, item) => sum + item.count),
      ),
    ];
  }

  List<PublicHolidayModel> get upcomingHolidays {
    final result = (holidays ?? <PublicHolidayModel>[])
        .where((holiday) => !dashboardDay(holiday.date).isBefore(today))
        .toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  int get holidaysNext90Days => upcomingHolidays
      .where(
        (holiday) => dashboardDay(
          holiday.date,
        ).isBefore(DateTime(today.year, today.month, today.day + 90)),
      )
      .length;
}
