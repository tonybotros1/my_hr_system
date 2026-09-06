import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_hr_system/controllers/auth_controllers/loading_screen_controller.dart';
import 'package:my_hr_system/models/navigation/navigation_item_model.dart';
import 'package:my_hr_system/routes/app_routes.dart';
import 'package:my_hr_system/services/auth_session_service.dart';
import 'package:my_hr_system/services/hr_access_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AllowedEmployeeAccess extends HrAccessService {
  @override
  Future<HrWorkspaceAccess> load({bool forceRefresh = false}) async {
    const access = HrWorkspaceAccess(
      hasHrResponsibility: true,
      isAdmin: false,
      navigationItems: [
        NavigationItemModel(
          id: 'employees',
          name: 'Employees',
          isMenu: false,
          routeName: '/employees',
          children: [],
        ),
      ],
    );
    currentAccess.value = access;
    return access;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  testWidgets('loading route restores a refreshed employee edit deep link', (
    tester,
  ) async {
    await _pumpStartup(
      tester,
      startup: '${AppRoutes.employeeWorkspace}?employeeId=employee-42',
    );

    expect(find.text('Employee editor employee-42'), findsOneWidget);
    expect(Get.currentRoute, contains(AppRoutes.employeeWorkspace));
  });

  testWidgets('loading route restores a refreshed new employee dialog', (
    tester,
  ) async {
    await _pumpStartup(tester, startup: AppRoutes.employeeWorkspace);

    expect(find.text('Employee editor new'), findsOneWidget);
    expect(Get.currentRoute, AppRoutes.employeeWorkspace);
  });
}

Future<void> _pumpStartup(
  WidgetTester tester, {
  required String startup,
}) async {
  SharedPreferences.setMockInitialValues({
    'userId': 'user-1',
    'accessToken': 'access-token',
  });
  final validationClient = MockClient((request) async {
    expect(request.method, 'GET');
    expect(request.url.path, '/auth/is_user_valid/user-1');
    return http.Response(
      '{"valid":true}',
      200,
      headers: {'content-type': 'application/json'},
    );
  });
  Get.put<AuthSessionService>(AuthSessionService());
  Get.put<HrAccessService>(_AllowedEmployeeAccess());

  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: AppRoutes.loading,
      getPages: [
        GetPage(
          name: AppRoutes.loading,
          page: () => const Scaffold(body: Text('Loading')),
          binding: BindingsBuilder(() {
            Get.put(
              LoadingScreenController(
                httpClient: validationClient,
                startupEmployeeWorkspace: startup,
              ),
            );
          }),
        ),
        GetPage(
          name: AppRoutes.employees,
          page: () => const Scaffold(body: Text('Employees list')),
        ),
        GetPage(
          name: AppRoutes.employeeWorkspace,
          page: () => Scaffold(
            body: Text(
              'Employee editor ${Get.parameters['employeeId'] ?? 'new'}',
            ),
          ),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}
