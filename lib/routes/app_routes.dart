class AppRoutes {
  AppRoutes._();

  static const loading = '/';
  static const login = '/loginScreen';
  static const main = '/mainScreen';
  static const employees = '$main/employees';
  static const employeeWorkspace = '$main/employees/editor';
  static const employeeRecordEditor = '$employeeWorkspace/record';
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
    'dashboard': 'dashboard',
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

  static String navigationPathForMenuRoute(String routeName) {
    return normalizeMenuRoute(routeName) == 'dashboard'
        ? main
        : screenPathForMenuRoute(routeName);
  }

  static String screenTitleForMenuRoute(String? routeName) {
    return switch (normalizeMenuRoute(routeName)) {
      '' || 'dashboard' => 'Dashboard',
      'defination' => 'Payroll Elements',
      'leavetypes' => 'Leave Types',
      'payroll' => 'Payroll',
      'balances' => 'Balances',
      'loanandadvancestypes' => 'Loan and Advances Types',
      'payrollruns' => 'Payroll Runs',
      'publicholidays' => 'Public Holidays',
      'legislation' => 'Legislation',
      'employees' => 'Employees',
      'users' => 'Users',
      'settings' => 'Settings',
      _ => 'DataHub AI',
    };
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

  /// Returns a safe application location from either Flutter's hash URL or a
  /// path-based URL. Unknown paths are intentionally ignored.
  static String? startupLocation(Uri browserUri) {
    final fragment = browserUri.fragment.trim();
    final rawLocation = fragment.isNotEmpty
        ? (fragment.startsWith('/') ? fragment : '/$fragment')
        : browserUri.replace(fragment: '').toString();
    final candidate = Uri.tryParse(rawLocation);
    if (candidate == null) return null;

    if (candidate.path == main) return main;

    if (candidate.path == employeeWorkspace) {
      final employeeId = candidate.queryParameters['employeeId']?.trim() ?? '';
      return Uri(
        path: employeeWorkspace,
        queryParameters: employeeId.isEmpty
            ? null
            : <String, String>{'employeeId': employeeId},
      ).toString();
    }

    // A refreshed child editor safely restores its employee workspace. The
    // record dialog itself needs runtime arguments that are intentionally not
    // stored in the URL.
    if (candidate.path == employeeRecordEditor) {
      final employeeId = candidate.queryParameters['employeeId']?.trim() ?? '';
      return Uri(
        path: employeeWorkspace,
        queryParameters: employeeId.isEmpty
            ? null
            : <String, String>{'employeeId': employeeId},
      ).toString();
    }

    final segments = candidate.pathSegments;
    if (segments.length != 2 || segments.first != 'mainScreen') return null;
    final slug = segments.last.toLowerCase();
    if (!_screenSlugs.values.contains(slug)) return null;
    return Uri(path: '$main/$slug').toString();
  }

  /// Backward-compatible helper retained for employee editor deep-link tests.
  static String? employeeWorkspaceDeepLink(Uri browserUri) {
    final location = startupLocation(browserUri);
    return Uri.tryParse(location ?? '')?.path == employeeWorkspace
        ? location
        : null;
  }
}
