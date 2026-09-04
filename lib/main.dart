import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'consts.dart';
import 'controllers/auth_controllers/loading_screen_controller.dart';
import 'controllers/auth_controllers/login_screen_controller.dart';
import 'controllers/payroll_controllers/leave_types_controller.dart';
import 'controllers/main_controllers/main_screen_controller.dart';
import 'controllers/payroll_controllers/payroll_elements_controller.dart';
import 'controllers/payroll_controllers/payroll_controller.dart';
import 'controllers/payroll_controllers/balances_controller.dart';
import 'controllers/payroll_controllers/loan_and_advances_types_controller.dart';
import 'controllers/payroll_controllers/payroll_runs_controller.dart';
import 'controllers/payroll_controllers/public_holidays_controller.dart';
import 'controllers/payroll_controllers/legislation_controller.dart';
import 'controllers/employee_controllers/employees_controller.dart';
import 'controllers/user_controllers/users_controller.dart';
import 'routes/app_routes.dart';
import 'screens/auth/loading_screens.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'services/authenticated_api_service.dart';
import 'services/auth_session_service.dart';
import 'services/hr_access_service.dart';
import 'widgets/employees/employee_workspace_dialog.dart';

void main() {
  runApp(const MyApp());
}

Bindings _mainBinding() {
  return BindingsBuilder(() {
    Get.lazyPut(MainScreenController.new);
    Get.lazyPut(PayrollElementsController.new, fenix: true);
    Get.lazyPut(LeaveTypesController.new, fenix: true);
    Get.lazyPut(PayrollController.new, fenix: true);
    Get.lazyPut(BalancesController.new, fenix: true);
    Get.lazyPut(LoanAndAdvancesTypesController.new, fenix: true);
    Get.lazyPut(PayrollRunsController.new, fenix: true);
    Get.lazyPut(PublicHolidaysController.new, fenix: true);
    Get.lazyPut(LegislationController.new, fenix: true);
    Get.lazyPut(EmployeesController.new, fenix: true);
    Get.lazyPut(UsersController.new, fenix: true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DataHub AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialBinding: BindingsBuilder(() {
        Get.put(AuthSessionService(), permanent: true);
        Get.put(AuthenticatedApiService(), permanent: true);
        Get.put(HrAccessService(), permanent: true);
      }),
      initialRoute: AppRoutes.loading,
      defaultTransition: Transition.fadeIn,
      getPages: [
        GetPage(
          name: AppRoutes.loading,
          page: () => const LoadingScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(LoadingScreenController.new);
          }),
        ),
        GetPage(
          name: AppRoutes.login,
          page: () => const LoginScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(LoginScreenController.new);
          }),
        ),
        GetPage(
          name: AppRoutes.main,
          page: () => const MainScreen(),
          binding: _mainBinding(),
        ),
        GetPage(
          name: AppRoutes.employeeWorkspace,
          page: () => const EmployeeWorkspaceRoute(),
          binding: _mainBinding(),
          fullscreenDialog: true,
          opaque: false,
          transition: Transition.noTransition,
        ),
        GetPage(
          name: AppRoutes.workspaceScreen,
          page: () => MainScreen(
            screenRouteName: AppRoutes.menuRouteForScreenSlug(
              Get.parameters['screen'],
            ),
          ),
          binding: _mainBinding(),
        ),
      ],
    );
  }
}
