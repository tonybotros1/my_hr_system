import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'consts.dart';
import 'controllers/auth_controllers/loading_screen_controller.dart';
import 'controllers/auth_controllers/login_screen_controller.dart';
import 'controllers/payroll_controllers/leave_types_controller.dart';
import 'controllers/main_controllers/main_screen_controller.dart';
import 'controllers/dashboard_controllers/dashboard_controller.dart';
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
import 'services/theme_controller.dart';
import 'widgets/employees/employee_record_dialog.dart';
import 'widgets/employees/employee_workspace_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inter and Roboto Mono ship in assets/google_fonts/, so google_fonts must
  // never fall back to downloading them from fonts.gstatic.com at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  await ThemeController.restoreSavedPalette();
  runApp(MyApp(startupLocation: AppRoutes.startupLocation(Uri.base)));
  // The large Unicode fallback fonts are registered after the first frame so
  // they no longer delay startup. Text re-lays out automatically once loaded.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(AppFonts.loadDeferredFallbackFonts());
  });
}

Bindings _mainBinding() {
  return BindingsBuilder(() {
    Get.lazyPut(MainScreenController.new);
    Get.lazyPut(DashboardController.new, fenix: true);
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
  const MyApp({this.startupLocation, super.key});

  /// Captured before Flutter replaces the browser fragment with the loading
  /// route, allowing refreshed and newly opened tabs to restore their screen.
  final String? startupLocation;

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
        Get.put(ThemeController(), permanent: true);
      }),
      initialRoute: AppRoutes.loading,
      defaultTransition: Transition.fadeIn,
      getPages: [
        GetPage(
          name: AppRoutes.loading,
          page: () => const LoadingScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(
              () => LoadingScreenController(startupLocation: startupLocation),
            );
          }),
        ),
        GetPage(
          name: AppRoutes.login,
          page: () => const LoginScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(LoginScreenController.new);
          }),
        ),
        // Workspace screens switch without the default 300 ms fade: the
        // previous page stays on screen (and keeps painting) for the whole
        // fade, so on the web every sidebar click paid for two full pages.
        GetPage(
          name: AppRoutes.main,
          page: () => const MainScreen(),
          binding: _mainBinding(),
          transition: Transition.noTransition,
          transitionDuration: Duration.zero,
        ),
        GetPage(
          name: AppRoutes.employeeWorkspace,
          page: () => const EmployeeWorkspaceRoute(),
          binding: _mainBinding(),
          fullscreenDialog: true,
          opaque: false,
          transition: Transition.fadeIn,
        ),
        GetPage<bool>(
          name: AppRoutes.employeeRecordEditor,
          page: () => const EmployeeRecordDialogRoute(),
          fullscreenDialog: true,
          opaque: false,
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: AppRoutes.workspaceScreen,
          page: () => MainScreen(
            screenRouteName: AppRoutes.menuRouteForScreenSlug(
              Get.parameters['screen'],
            ),
          ),
          binding: _mainBinding(),
          transition: Transition.noTransition,
          transitionDuration: Duration.zero,
        ),
      ],
    );
  }
}
