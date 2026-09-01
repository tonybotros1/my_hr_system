import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_hr_system/controllers/employee_controllers/employees_controller.dart';
import 'package:my_hr_system/models/employees/employee_model.dart';
import 'package:my_hr_system/widgets/employees/employee_lookup_values_dialog.dart';
import 'package:my_hr_system/widgets/employees/employee_record_dialog.dart';

class _EmployeesControllerStub extends EmployeesController {
  @override
  Future<void> loadEmployees({bool filtered = false}) async {}

  @override
  Future<Map<String, dynamic>> listValues(
    String code, {
    bool refresh = false,
  }) async => {
    'employer-1': {'_id': 'employer-1', 'name': 'DataHub AI'},
  };
}

void main() {
  tearDown(Get.reset);

  testWidgets('closing a nested employee editor keeps its parent dialog open', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = _EmployeesControllerStub();

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showEmployeeLookupValuesDialog(
                  context,
                  controller: controller,
                  code: 'EMPLOYERS',
                  title: 'Employers',
                  singularTitle: 'Employer',
                ),
                child: const Text('Open utility'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open utility'));
    await tester.pumpAndSettle();
    expect(find.text('Employers'), findsOneWidget);

    for (var opening = 0; opening < 2; opening++) {
      await tester.tap(find.text('New Value'));
      await tester.pumpAndSettle();
      expect(find.text('New Employer'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('New Employer'), findsNothing);
      expect(find.text('Employers'), findsOneWidget);
      expect(find.text('New Value'), findsOneWidget);
    }

    // Browser tests intentionally leave the root dialog open: closing it
    // navigates the browser test harness back by one synthetic history entry.
    if (kIsWeb) return;

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Employers'), findsNothing);
    expect(find.text('Open utility'), findsOneWidget);
  });

  testWidgets('address editor is compact and orders its fields vertically', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Get.put<EmployeesController>(_EmployeesControllerStub());

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showEmployeeRecordDialog(
                context,
                kind: EmployeeRecordKind.address,
              ),
              child: const Text('Open address'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open address'));
    await tester.pumpAndSettle();

    expect(find.text('New Address'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('employee-record-dialog-content')))
          .width,
      lessThanOrEqualTo(560),
    );
    expect(
      tester.getTopLeft(find.text('Country')).dy,
      lessThan(tester.getTopLeft(find.text('City')).dy),
    );
    expect(
      tester.getTopLeft(find.text('City')).dy,
      lessThan(tester.getTopLeft(find.text('Address')).dy),
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('New Address'), findsNothing);
  }, skip: kIsWeb);

  testWidgets('employee record dialogs fit content and use requested grids', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Get.put<EmployeesController>(_EmployeesControllerStub());

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () => showEmployeeRecordDialog(
                    context,
                    kind: EmployeeRecordKind.nationality,
                    record: const EmployeeRecord({
                      '_id': 'nationality-1',
                      'nationality': 'country-1',
                      'nationality_name': 'Lebanese',
                      'start_date': '2026-01-01',
                      'end_date': '2026-12-31',
                    }),
                  ),
                  child: const Text('Open nationality'),
                ),
                TextButton(
                  onPressed: () => showEmployeeRecordDialog(
                    context,
                    kind: EmployeeRecordKind.bankAccount,
                  ),
                  child: const Text('Open bank'),
                ),
                TextButton(
                  onPressed: () => showEmployeeRecordDialog(
                    context,
                    kind: EmployeeRecordKind.healthCard,
                  ),
                  child: const Text('Open health card'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open nationality'));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('employee-record-dialog-content')))
          .height,
      lessThan(270),
    );
    expect(find.byTooltip('Clear Start date'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear Start date'));
    await tester.pump();
    expect(find.text('2026-01-01'), findsNothing);
    final endDateEditor = find.byWidgetPredicate(
      (widget) =>
          widget is EditableText && widget.controller.text == '2026-12-31',
    );
    tester
        .state<EditableTextState>(endDateEditor)
        .widget
        .focusNode
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(find.text('2026-12-31'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open bank'));
    await tester.pumpAndSettle();
    final bankLabels = ['Bank name', 'Account number', 'IBAN', 'SWIFT code'];
    final bankY = bankLabels
        .map((label) => tester.getTopLeft(find.text(label).first).dy)
        .toList(growable: false);
    for (var index = 1; index < bankY.length; index++) {
      expect(bankY[index], greaterThan(bankY[index - 1]));
    }
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open health card'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Health card type').first).dy,
      tester.getTopLeft(find.text('Card holder').first).dy,
    );
    expect(
      tester.getTopLeft(find.text('Card number').first).dy,
      tester.getTopLeft(find.text('Insurance company').first).dy,
    );
    expect(
      tester.getTopLeft(find.text('Issue date').first).dy,
      tester.getTopLeft(find.text('Expiry date').first).dy,
    );
    expect(
      tester.getTopLeft(find.text('Cost').first).dy,
      tester.getTopLeft(find.text('Employee contribution').first).dy,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  }, skip: kIsWeb);
}
