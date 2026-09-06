// Local visual QA only. This entry point is never imported by lib/main.dart.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_hr_system/consts.dart';
import 'package:my_hr_system/controllers/dashboard_controllers/dashboard_controller.dart';
import 'package:my_hr_system/controllers/main_controllers/main_screen_controller.dart';
import 'package:my_hr_system/screens/main/main_screen.dart';
import 'package:my_hr_system/services/theme_controller.dart';
import 'dashboard_fixtures.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put<MainScreenController>(DashboardShellFixture());
  Get.put(
    DashboardController(
      api: DashboardApiFixture(),
      access: DashboardAccessFixture(),
      clock: () => dashboardTestDate,
    ),
  );
  Get.put(ThemeController());
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const Banner(
        message: 'SAMPLE DATA',
        location: BannerLocation.topEnd,
        child: MainScreen(),
      ),
    ),
  );
}
