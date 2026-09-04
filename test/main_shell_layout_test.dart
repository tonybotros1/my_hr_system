import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main shell keeps logout in sidebar and removes the top bar', () {
    final mainScreen = File(
      'lib/screens/main/main_screen.dart',
    ).readAsStringSync();
    final sidebar = File(
      'lib/widgets/main_shell/main_sidebar.dart',
    ).readAsStringSync();

    expect(mainScreen, isNot(contains('AppSizes.shellTopBarHeight')));
    expect(mainScreen, contains('Positioned.fill'));
    expect(mainScreen, contains('_SelectedScreen(routeName: activeRouteName)'));
    expect(mainScreen, isNot(contains("const Text('Sign out')")));

    final navigationIndex = sidebar.indexOf('_NavigationBody(');
    final footerIndex = sidebar.indexOf('const _SidebarFooter()');
    expect(navigationIndex, greaterThanOrEqualTo(0));
    expect(footerIndex, greaterThan(navigationIndex));
    expect(sidebar, contains('controller.requestLogout'));
    expect(sidebar, contains("'Sign out'"));
  });

  test('list screens center titles and keep create actions in filters', () {
    const screens = <String, ({String filterClass, String? newLabel})>{
      'lib/screens/employees/employees_screen.dart': (
        filterClass: 'class _EmployeeFilters',
        newLabel: 'New Employee',
      ),
      'lib/screens/payroll/payroll_elements_screen.dart': (
        filterClass: 'class _SearchToolbar',
        newLabel: 'New Element',
      ),
      'lib/screens/payroll/leave_types_screen.dart': (
        filterClass: 'class _SearchToolbar',
        newLabel: 'New Type',
      ),
      'lib/screens/payroll/payroll_screen.dart': (
        filterClass: 'class _SearchToolbar',
        newLabel: 'New Payroll',
      ),
      'lib/screens/payroll/balances_screen.dart': (
        filterClass: 'class _SearchToolbar',
        newLabel: 'New Balance',
      ),
      'lib/screens/payroll/loan_and_advances_types_screen.dart': (
        filterClass: 'class _SearchToolbar',
        newLabel: 'New Type',
      ),
      'lib/screens/payroll/payroll_runs_screen.dart': (
        filterClass: 'class _SearchToolbar',
        newLabel: 'New Payroll',
      ),
      'lib/screens/payroll/legislation_screen.dart': (
        filterClass: 'class _FilterCard',
        newLabel: 'New Legislation',
      ),
      'lib/screens/payroll/public_holidays_screen.dart': (
        filterClass: 'class _HolidayFilters',
        newLabel: null,
      ),
    };

    for (final entry in screens.entries) {
      final source = File(entry.key).readAsStringSync();
      final headerStart = source.indexOf('class _PageHeader');
      final filterStart = source.indexOf(entry.value.filterClass);

      expect(headerStart, greaterThanOrEqualTo(0), reason: entry.key);
      expect(filterStart, greaterThan(headerStart), reason: entry.key);
      expect(
        source.substring(headerStart, filterStart),
        contains('textAlign: TextAlign.center'),
        reason: entry.key,
      );

      final newLabel = entry.value.newLabel;
      if (newLabel != null) {
        final actionIndex = source.indexOf("Text('$newLabel')");
        expect(actionIndex, greaterThan(filterStart), reason: entry.key);
      }
    }
  });
}
