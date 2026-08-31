import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../models/company/company_identity_model.dart';
import '../../models/navigation/navigation_item_model.dart';
import '../../routes/app_routes.dart';
import '../../screens/payroll/leave_types_screen.dart';
import '../../screens/payroll/payroll_elements_screen.dart';
import '../../screens/payroll/payroll_screen.dart';
import '../../screens/payroll/balances_screen.dart';
import '../../screens/payroll/loan_and_advances_types_screen.dart';
import '../../screens/payroll/payroll_runs_screen.dart';
import '../../screens/payroll/public_holidays_screen.dart';
import '../../screens/payroll/legislation_screen.dart';
import '../../screens/employees/employees_screen.dart';
import '../../services/authenticated_api_service.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';

class MainScreenController extends GetxController {
  MainScreenController({AuthenticatedApiService? api}) : _apiOverride = api;

  final AuthenticatedApiService? _apiOverride;
  final company = Rxn<CompanyIdentityModel>();
  final navigationItems = <NavigationItemModel>[].obs;
  final isLoading = true.obs;
  final isLoggingOut = false.obs;
  final errorMessage = RxnString();
  final sidebarOverride = RxnBool();
  final sidebarWidth = AppSizes.sidebarWidth.obs;
  final isResizingSidebar = false.obs;

  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();

  @override
  void onInit() {
    super.onInit();
    unawaited(loadShellData());
  }

  bool sidebarIsOpen({required bool compact}) {
    return sidebarOverride.value ?? !compact;
  }

  void toggleSidebar({required bool compact}) {
    sidebarOverride.value = !sidebarIsOpen(compact: compact);
  }

  void closeSidebar() {
    sidebarOverride.value = false;
  }

  void startSidebarResize() {
    isResizingSidebar.value = true;
  }

  void resizeSidebar(double horizontalDelta) {
    sidebarWidth.value = (sidebarWidth.value + horizontalDelta)
        .clamp(AppSizes.sidebarMinWidth, AppSizes.sidebarMaxWidth)
        .toDouble();
  }

  void finishSidebarResize() {
    isResizingSidebar.value = false;
  }

  Future<void> selectItem(
    NavigationItemModel item, {
    required bool compact,
  }) async {
    if (!item.canOpen) return;
    if (compact) closeSidebar();
    final destination = AppRoutes.screenPathForMenuRoute(item.routeName!);
    final currentPath = Uri.tryParse(Get.currentRoute)?.path;
    if (currentPath == destination) return;
    await Get.toNamed<void>(destination);
  }

  // This function gets the screen based on the route name
  // and displays it on the right side of the main screen.
  Widget getScreenFromRoute(String? routeName) {
    switch (routeName) {
      case '/defination':
        return const PayrollElementsScreen();
      case '/leavetypes':
        return const LeaveTypesScreen();
      case '/payroll':
        return const PayrollScreen();
      case '/balances':
        return const BalancesScreen();
      case '/loanandadvancestypes':
        return const LoanAndAdvancesTypesScreen();
      case '/payrollruns':
        return const PayrollRunsScreen();
      case '/publicholidays':
        return const PublicHolidaysScreen();
      case '/legislation':
        return const LegislationScreen();
      case '/employees':
        return const EmployeesScreen();

      default:
        return const Center(child: Text('Screen not found'));
    }
  }

  Future<void> loadShellData() async {
    if (isClosed) return;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final responses = await Future.wait([
        _api.getJson('/companies/get_user_and_company_details'),
        _api.getJson('/menus/get_user_menu_tree'),
      ]);
      company.value = CompanyIdentityModel.fromEnvelope(responses[0]);
      navigationItems.assignAll(
        NavigationItemModel.listFromEnvelope(responses[1]),
      );
    } on SessionExpiredException {
      await _openLogin();
      return;
    } on ApiRequestException catch (error) {
      errorMessage.value = error.message;
    } on FormatException {
      errorMessage.value = 'The server returned invalid workspace data.';
    } catch (_) {
      errorMessage.value = 'The workspace could not be loaded.';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> requestLogout() async {
    if (isLoggingOut.value) return;
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to continue.',
      confirmLabel: 'Sign out',
    );
    if (confirmed) await logout();
  }

  Future<void> logout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;
    try {
      await _api.logout();
    } finally {
      isLoggingOut.value = false;
      await _openLogin();
    }
  }

  Future<void> _openLogin() async {
    if (!isClosed) Get.offAllNamed(AppRoutes.login);
  }
}
