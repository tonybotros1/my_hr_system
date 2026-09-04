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
import '../../screens/users/users_screen.dart';
import '../../services/authenticated_api_service.dart';
import '../../services/hr_access_service.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';

class MainScreenController extends GetxController {
  MainScreenController({AuthenticatedApiService? api}) : _apiOverride = api;

  final AuthenticatedApiService? _apiOverride;
  final company = Rxn<CompanyIdentityModel>();
  final navigationItems = <NavigationItemModel>[].obs;
  final allowedScreenRoutes = <String>{}.obs;
  final isAdmin = false.obs;
  final isLoading = true.obs;
  final isLoggingOut = false.obs;
  final errorMessage = RxnString();
  final sidebarOverride = RxnBool();
  final sidebarWidth = AppSizes.sidebarWidth.obs;
  final isResizingSidebar = false.obs;

  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();
  HrAccessService get _hrAccess => Get.find<HrAccessService>();

  @override
  void onInit() {
    super.onInit();
    unawaited(loadShellData());
  }

  bool sidebarIsOpen({required bool compact}) {
    return sidebarOverride.value ?? !compact;
  }

  bool canOpenRoute(String? routeName) {
    final normalized = AppRoutes.normalizeMenuRoute(routeName);
    return normalized.isNotEmpty && allowedScreenRoutes.contains(normalized);
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
    final normalizedRoute = AppRoutes.normalizeMenuRoute(routeName);
    if (normalizedRoute.isEmpty) {
      return const Center(child: Text('Screen not found'));
    }
    return Obx(() {
      if (!canOpenRoute(normalizedRoute)) {
        return const _WorkspaceAccessDenied();
      }
      return _screenForRoute('/$normalizedRoute');
    });
  }

  Widget _screenForRoute(String routeName) {
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
      case '/users':
        return isAdmin.value
            ? const UsersScreen()
            : const _WorkspaceAccessDenied();

      default:
        return const Center(child: Text('Screen not found'));
    }
  }

  Future<void> loadShellData() async {
    if (isClosed) return;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final responses = await Future.wait<Object>([
        _api.getJson('/companies/get_user_and_company_details'),
        _hrAccess.load(),
      ]);
      company.value = CompanyIdentityModel.fromEnvelope(
        responses[0] as Map<String, dynamic>,
      );
      final access = responses[1] as HrWorkspaceAccess;
      if (!access.hasHrResponsibility) {
        _hrAccess.clearCache();
        await _api.logout();
        await _openLogin();
        return;
      }
      isAdmin.value = access.isAdmin;
      navigationItems.assignAll(access.navigationItems);
      allowedScreenRoutes.assignAll(_openRoutes(access.navigationItems));
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
      _hrAccess.clearCache();
      await _api.logout();
    } finally {
      isLoggingOut.value = false;
      await _openLogin();
    }
  }

  Future<void> _openLogin() async {
    if (!isClosed) Get.offAllNamed(AppRoutes.login);
  }

  Set<String> _openRoutes(Iterable<NavigationItemModel> items) {
    final routes = <String>{};
    for (final item in items) {
      final normalized = AppRoutes.normalizeMenuRoute(item.routeName);
      if (normalized.isNotEmpty) routes.add(normalized);
      routes.addAll(_openRoutes(item.children));
    }
    return routes;
  }
}

class _WorkspaceAccessDenied extends StatelessWidget {
  const _WorkspaceAccessDenied();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.admin_panel_settings_outlined,
              color: AppColors.iconMuted,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You do not have access to this screen.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}
