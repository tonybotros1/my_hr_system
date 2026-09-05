class AppRoutes {
  AppRoutes._();

  static const loading = '/';
  static const login = '/loginScreen';
  static const main = '/mainScreen';
  static const employeeWorkspace = '$main/employees/editor';
  static const settings = '$main/settings';
  static const workspaceScreen = '$main/:screen';
  static const home = main;

  static const _screenSlugs = <String, String>{
    'defination': 'payroll-elements',
    'leavetypes': 'leave-types',
    'payroll': 'payroll',
    'balances': 'balances',
    'loanandadvancestypes': 'loan-and-advances-types',
    'payrollruns': 'payroll-runs',
    'publicholidays': 'public-holidays',
    'legislation': 'legislation',
    'employees': 'employees',
    'users': 'users',
    'settings': 'settings',
  };

  static String normalizeMenuRoute(String? routeName) {
    return routeName
            ?.trim()
            .replaceAll('/', '')
            .replaceAll('_', '')
            .replaceAll('-', '')
            .toLowerCase() ??
        '';
  }

  static String screenPathForMenuRoute(String routeName) {
    final normalized = normalizeMenuRoute(routeName);
    final slug = _screenSlugs[normalized] ?? normalized;
    return slug.isEmpty ? main : '$main/$slug';
  }

  static String? menuRouteForScreenSlug(String? screenSlug) {
    final slug = screenSlug?.trim().toLowerCase() ?? '';
    if (slug.isEmpty) return null;
    for (final entry in _screenSlugs.entries) {
      if (entry.value == slug) return '/${entry.key}';
    }
    final normalized = normalizeMenuRoute(slug);
    return normalized.isEmpty ? null : '/$normalized';
  }

  static bool isMenuRouteActive(String? menuRoute, String? activeRoute) {
    final normalizedMenuRoute = normalizeMenuRoute(menuRoute);
    return normalizedMenuRoute.isNotEmpty &&
        normalizedMenuRoute == normalizeMenuRoute(activeRoute);
  }
}
