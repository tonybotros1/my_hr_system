import 'package:get/get.dart';

import '../models/navigation/navigation_item_model.dart';
import '../routes/app_routes.dart';
import 'authenticated_api_service.dart';

class HrWorkspaceAccess {
  const HrWorkspaceAccess({
    required this.hasHrResponsibility,
    required this.isAdmin,
    required this.navigationItems,
  });

  final bool hasHrResponsibility;
  final bool isAdmin;
  final List<NavigationItemModel> navigationItems;

  bool canOpenRoute(String? routeName) {
    final normalized = AppRoutes.normalizeMenuRoute(routeName);
    if (normalized.isEmpty) return false;
    return _containsRoute(navigationItems, normalized);
  }

  static bool _containsRoute(
    Iterable<NavigationItemModel> items,
    String normalized,
  ) {
    for (final item in items) {
      if (AppRoutes.normalizeMenuRoute(item.routeName) == normalized ||
          _containsRoute(item.children, normalized)) {
        return true;
      }
    }
    return false;
  }
}

class HrScreenDefinition {
  const HrScreenDefinition({required this.name, required this.routeName});

  final String name;
  final String routeName;
}

class HrAccessService extends GetxService {
  HrAccessService({AuthenticatedApiService? api}) : _apiOverride = api;

  final AuthenticatedApiService? _apiOverride;
  HrWorkspaceAccess? _cachedAccess;
  final currentAccess = Rxn<HrWorkspaceAccess>();

  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();

  Future<HrWorkspaceAccess> load({bool forceRefresh = false}) async {
    final cached = _cachedAccess;
    if (!forceRefresh && cached != null) return cached;

    final responses = await Future.wait([
      _api.getJson('/menus/get_user_menu_tree'),
      _api.getJson('/companies/get_current_company_details'),
    ]);
    final access = HrAccessPolicy.fromResponses(
      menuResponse: responses[0],
      companyResponse: responses[1],
    );
    _cachedAccess = access;
    currentAccess.value = access;
    return access;
  }

  void clearCache() {
    _cachedAccess = null;
    currentAccess.value = null;
  }
}

class HrAccessPolicy {
  HrAccessPolicy._();

  static const supportedScreens = <HrScreenDefinition>[
    HrScreenDefinition(name: 'Legislation', routeName: '/legislation'),
    HrScreenDefinition(name: 'Payroll Elements', routeName: '/defination'),
    HrScreenDefinition(name: 'Employees', routeName: '/employees'),
    HrScreenDefinition(name: 'Public Holidays', routeName: '/publicholidays'),
    HrScreenDefinition(name: 'Leave Types', routeName: '/leavetypes'),
    HrScreenDefinition(name: 'Payroll', routeName: '/payroll'),
    HrScreenDefinition(name: 'Payroll Runs', routeName: '/payrollruns'),
    HrScreenDefinition(name: 'Balances', routeName: '/balances'),
    HrScreenDefinition(
      name: 'Loan and Advances Types',
      routeName: '/loanandadvancestypes',
    ),
  ];

  static final Map<String, HrScreenDefinition> _screenByRoute = {
    for (final screen in supportedScreens)
      AppRoutes.normalizeMenuRoute(screen.routeName): screen,
  };

  static HrWorkspaceAccess fromResponses({
    required Map<String, dynamic> menuResponse,
    required Map<String, dynamic> companyResponse,
  }) {
    final roots = NavigationItemModel.listFromEnvelope(menuResponse);
    final hrRoots = roots.where((item) => _isHrResponsibility(item.name));
    final isAdmin = _readAdmin(companyResponse);
    final allowedScreens = _readAllowedScreens(companyResponse);
    final navigation = <NavigationItemModel>[];
    final addedRoutes = <String>{};

    for (final root in hrRoots) {
      for (final item in _flattenScreens(root.children)) {
        final normalized = AppRoutes.normalizeMenuRoute(item.routeName);
        if (allowedScreens != null && !allowedScreens.contains(normalized)) {
          continue;
        }
        if (!addedRoutes.add(normalized)) continue;
        final definition = _screenByRoute[normalized]!;
        navigation.add(
          item.copyWith(
            name: definition.name,
            routeName: definition.routeName,
            children: const <NavigationItemModel>[],
          ),
        );
      }
    }
    if (isAdmin && hrRoots.isNotEmpty) {
      navigation.add(
        const NavigationItemModel(
          id: 'hr-admin-screens',
          name: "Admin's Screens",
          isMenu: true,
          children: <NavigationItemModel>[
            NavigationItemModel(
              id: 'hr-admin-users',
              name: 'Users',
              isMenu: false,
              routeName: '/users',
              children: <NavigationItemModel>[],
            ),
          ],
        ),
      );
    }

    return HrWorkspaceAccess(
      hasHrResponsibility: hrRoots.isNotEmpty,
      isAdmin: isAdmin,
      navigationItems: List.unmodifiable(navigation),
    );
  }

  static Iterable<NavigationItemModel> _flattenScreens(
    Iterable<NavigationItemModel> items,
  ) sync* {
    for (final item in items) {
      final normalized = AppRoutes.normalizeMenuRoute(item.routeName);
      if (_screenByRoute.containsKey(normalized)) {
        yield item;
      }
      yield* _flattenScreens(item.children);
    }
  }

  static bool _isHrResponsibility(String name) {
    final normalized = _normalize(name);
    return normalized == 'hr' ||
        normalized == 'humanresource' ||
        normalized == 'humanresources' ||
        normalized == 'humanresourcemanagement';
  }

  static bool _readAdmin(Map<String, dynamic> response) {
    final rawCompany = response['company_details'];
    if (rawCompany is! Map) return false;
    final value = rawCompany['is_admin'];
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  static Set<String>? _readAllowedScreens(Map<String, dynamic> response) {
    final rawCompany = response['company_details'];
    if (rawCompany is! Map || !rawCompany.containsKey('hr_screen_access')) {
      return null;
    }
    final rawAccess = rawCompany['hr_screen_access'];
    if (rawAccess == null) return null;
    if (rawAccess is! List) return null;
    return rawAccess
        .map((route) => AppRoutes.normalizeMenuRoute(route.toString()))
        .where(_screenByRoute.containsKey)
        .toSet();
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  }
}
