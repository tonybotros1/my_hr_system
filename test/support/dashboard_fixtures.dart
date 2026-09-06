import 'package:get/get.dart';
import 'package:my_hr_system/controllers/main_controllers/main_screen_controller.dart';
import 'package:my_hr_system/models/company/company_identity_model.dart';
import 'package:my_hr_system/models/navigation/navigation_item_model.dart';
import 'package:my_hr_system/services/authenticated_api_service.dart';
import 'package:my_hr_system/services/hr_access_service.dart';

final dashboardTestDate = DateTime(2026, 9, 5, 9, 30);

class DashboardAccessFixture extends HrAccessService {
  DashboardAccessFixture({
    this.routes = const ['/employees', '/payrollruns', '/publicholidays'],
  });
  List<String> routes;
  bool hasHr = true;
  @override
  Future<HrWorkspaceAccess> load({bool forceRefresh = false}) async =>
      HrWorkspaceAccess(
        hasHrResponsibility: hasHr,
        isAdmin: false,
        navigationItems: routes
            .map(
              (route) => NavigationItemModel(
                id: route,
                name: route,
                routeName: route,
                isMenu: false,
                children: const [],
              ),
            )
            .toList(),
      );
}

class DashboardApiFixture extends AuthenticatedApiService {
  final calls = <String>[];
  bool failEmployees = false;
  bool malformedEmployees = false;
  bool empty = false;
  final employeeRows = <Map<String, dynamic>>[];

  DashboardApiFixture() {
    const names = [
      'Sofia Bennett',
      'Omar Hassan',
      'Amelia Brooks',
      'Oliver Chen',
      'Maya Patel',
      'Lucas Martin',
      'Isabella Reed',
      'Adam Cooper',
      'Nora Wilson',
      'Ethan Clarke',
    ];
    const departments = [
      'Engineering',
      'Operations',
      'Sales & marketing',
      'Finance',
      'People & culture',
    ];
    const counts = [3, 5, 2, 4, 7, 3];
    for (var month = 0; month < counts.length; month++) {
      for (var day = 1; day <= counts[month]; day++) {
        final index = employeeRows.length;
        employeeRows.add({
          '_id': 'sample-$index',
          'full_name': names[index % names.length],
          'department': 'department-${index % 5}',
          'department_name': departments[index % 5],
          'hire_date': DateTime(2026, month + 4, day).toIso8601String(),
        });
      }
    }
  }

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    calls.add(path);
    if (path == '/employees/get_all_employees') {
      if (failEmployees) {
        throw const ApiRequestException('Unavailable', statusCode: 503);
      }
      if (malformedEmployees) return {'employees': 'invalid'};
      return {'employees': empty ? [] : employeeRows};
    }
    if (path == '/payroll_runs/get_all_payroll_runs') {
      return {
        'payroll_runs': empty
            ? []
            : List.generate(
                4,
                (index) => {
                  '_id': 'run-$index',
                  'payroll_name': 'Monthly payroll',
                  'run_number': '${104 - index}',
                  'period_name':
                      '2026-${(8 - index).toString().padLeft(2, '0')}',
                  'description': 'Sample payroll',
                  'payment_number': '',
                },
              ),
      };
    }
    throw StateError('Unexpected GET $path');
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    calls.add(path);
    if (path != '/public_holidays/get_all_holidays' ||
        body == null ||
        body.isNotEmpty) {
      throw StateError('Unexpected dashboard POST');
    }
    return {
      'holidays': empty
          ? []
          : [
              {
                '_id': 'holiday-1',
                'name': 'Company foundation day',
                'date': '2026-09-18',
                'legislation': 'sample',
              },
              {
                '_id': 'holiday-2',
                'name': 'National celebration',
                'date': '2026-10-05',
                'legislation': 'sample',
              },
              {
                '_id': 'holiday-3',
                'name': 'Year-end holiday',
                'date': '2026-12-25',
                'legislation': 'sample',
              },
            ],
    };
  }
}

class DashboardShellFixture extends MainScreenController {
  @override
  Future<void> loadShellData() async {
    company.value = const CompanyIdentityModel(
      userId: 'sample',
      userName: 'Alex Morgan',
      email: 'alex@example.com',
      companyName: 'Meridian Group · Sample data',
      logoUrl: '',
    );
    navigationItems.assignAll(
      HrAccessPolicy.supportedScreens.map(
        (screen) => NavigationItemModel(
          id: screen.routeName,
          name: screen.name,
          routeName: screen.routeName,
          isMenu: false,
          children: const [],
        ),
      ),
    );
    allowedScreenRoutes.addAll(['settings', 'dashboard']);
    isLoading.value = false;
  }
}
