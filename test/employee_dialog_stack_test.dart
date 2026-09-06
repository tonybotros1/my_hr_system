import 'dart:convert';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_hr_system/consts.dart';
import 'package:my_hr_system/controllers/employee_controllers/employees_controller.dart';
import 'package:my_hr_system/models/employees/employee_model.dart';
import 'package:my_hr_system/models/navigation/navigation_item_model.dart';
import 'package:my_hr_system/routes/app_routes.dart';
import 'package:my_hr_system/services/hr_access_service.dart';
import 'package:my_hr_system/widgets/employees/employee_documents_dialog.dart';
import 'package:my_hr_system/widgets/employees/employee_lookup_values_dialog.dart';
import 'package:my_hr_system/widgets/employees/employee_record_dialog.dart';
import 'package:my_hr_system/widgets/employees/employee_workspace_dialog.dart';
import 'package:my_hr_system/widgets/drop_down_menu.dart';
import 'package:my_hr_system/widgets/form_fields/app_date_form_field.dart';
import 'package:my_hr_system/widgets/form_fields/app_text_form_field.dart';

class _EmployeesControllerStub extends EmployeesController {
  @override
  Future<void> loadEmployees({bool filtered = false}) async {}

  @override
  Future<void> loadAttachments() async {
    attachments.assignAll([
      const EmployeeAttachment(
        id: 'attachment-1',
        name: 'Passport',
        typeId: 'type-1',
        typeName: 'Identity document',
        number: 'P123456',
        note: 'Employee passport',
        files: [
          EmployeeAttachmentFile(
            name: 'passport.pdf',
            url: 'https://example.com/passport.pdf',
            resourceType: 'raw',
            format: 'pdf',
          ),
        ],
      ),
    ]);
  }

  var leaveCalculationCalls = 0;
  String calculatedLeaveTypeId = '';
  DateTime? calculatedStartDate;
  DateTime? calculatedEndDate;

  @override
  Future<Map<String, dynamic>> leaveTypes() async => {
    'leave-type-1': {'_id': 'leave-type-1', 'name': 'Annual leave'},
  };

  @override
  Future<int?> calculateLeaveDays({
    required String leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    leaveCalculationCalls++;
    calculatedLeaveTypeId = leaveTypeId;
    calculatedStartDate = startDate;
    calculatedEndDate = endDate;
    return 4;
  }

  @override
  Future<Map<String, dynamic>> listValues(
    String code, {
    bool refresh = false,
  }) async => {
    'employer-1': {'_id': 'employer-1', 'name': 'DataHub AI'},
  };

  @override
  Future<Map<String, List<int>>> pickAttachmentFiles() async => {
    'employee.png': base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
    'contract.pdf': [37, 80, 68, 70],
    'too-large.zip': _SizedByteList(
      AppLimits.employeeAttachmentMaxFileBytes + 1,
    ),
  };
}

class _SizedByteList extends ListBase<int> {
  _SizedByteList(this._length);

  final int _length;

  @override
  int get length => _length;

  @override
  set length(int value) => throw UnsupportedError('Fixed test list');

  @override
  int operator [](int index) => 0;

  @override
  void operator []=(int index, int value) =>
      throw UnsupportedError('Read-only test list');
}

class _ReloadEmployeesControllerStub extends _EmployeesControllerStub {
  String restoredEmployeeId = '';

  @override
  Future<bool> loadEmployee(String id) async {
    restoredEmployeeId = id;
    selectedEmployee.value = EmployeeDetails.fromJson({
      '_id': id,
      'full_name': 'Restored Employee',
      'hire_date': '2026-01-01T00:00:00.000Z',
    });
    fullName.text = 'Restored Employee';
    return true;
  }
}

class _ReloadHrAccessService extends HrAccessService {
  var loadCalls = 0;

  @override
  Future<HrWorkspaceAccess> load({bool forceRefresh = false}) async {
    loadCalls++;
    const access = HrWorkspaceAccess(
      hasHrResponsibility: true,
      isAdmin: false,
      navigationItems: [
        NavigationItemModel(
          id: 'employees',
          name: 'Employees',
          isMenu: false,
          routeName: '/employees',
          children: [],
        ),
      ],
    );
    currentAccess.value = access;
    return access;
  }
}

void main() {
  tearDown(Get.reset);

  testWidgets('browser-style back closes the employee workspace route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Get.put<EmployeesController>(_EmployeesControllerStub());
    Get.put<HrAccessService>(_ReloadHrAccessService());

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/employee-list',
        getPages: [
          GetPage(
            name: '/employee-list',
            page: () => Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () {
                    Get.find<EmployeesController>().beginNewEmployee();
                    showEmployeeWorkspaceDialog(context);
                  },
                  child: const Text('Open employee'),
                ),
              ),
            ),
          ),
          GetPage(
            name: AppRoutes.employeeWorkspace,
            page: () => const EmployeeWorkspaceRoute(),
            fullscreenDialog: true,
            opaque: false,
            transition: Transition.fadeIn,
          ),
        ],
      ),
    );

    await tester.tap(find.text('Open employee'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.employeeWorkspace);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byTooltip('Close employee workspace'), findsOneWidget);
    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(dialog.insetPadding, const EdgeInsets.all(AppSpacing.sm));
    expect(dialog.shape, isA<RoundedRectangleBorder>());
    expect(
      tester.getSize(find.byKey(const ValueKey('employee-workspace-surface'))),
      const Size(1176, 776),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(Get.currentRoute, '/employee-list');
    expect(find.text('Open employee'), findsOneWidget);
    expect(find.byTooltip('Close employee workspace'), findsNothing);
  });

  testWidgets(
    'employee editor autofocuses and follows the requested Tab order',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Get.put<EmployeesController>(_EmployeesControllerStub());
      Get.put<HrAccessService>(_ReloadHrAccessService());

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.employeeWorkspace,
          getPages: [
            GetPage(
              name: AppRoutes.employeeWorkspace,
              page: () => const EmployeeWorkspaceRoute(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      AppTextFormField textField(String label) =>
          tester.widget<AppTextFormField>(
            find.byWidgetPredicate(
              (widget) => widget is AppTextFormField && widget.label == label,
            ),
          );
      CustomDropdown dropdown(String label) => tester.widget<CustomDropdown>(
        find.byWidgetPredicate(
          (widget) => widget is CustomDropdown && widget.hintText == label,
        ),
      );
      AppDateFormField dateField(String label) =>
          tester.widget<AppDateFormField>(
            find.byWidgetPredicate(
              (widget) => widget is AppDateFormField && widget.label == label,
            ),
          );

      final requestedOrder = <FocusNode>[
        textField('Full Name').focusNode!,
        dropdown('Country of Birth').focusNode!,
        textField('Place of Birth').focusNode!,
        dateField('Date of Birth').focusNode!,
        dropdown('Gender').focusNode!,
        dropdown('Marital Status').focusNode!,
        dropdown('Legislation *').focusNode!,
        dropdown('Employer').focusNode!,
        dropdown('Department').focusNode!,
        dropdown('Job Title').focusNode!,
        dropdown('Location').focusNode!,
        dropdown('Reporting Manager').focusNode!,
        dropdown('Payroll *').focusNode!,
        dateField('Hire Date').focusNode!,
        dateField('End Date').focusNode!,
      ];

      expect(requestedOrder.first.hasFocus, isTrue);
      for (var index = 1; index < requestedOrder.length; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          requestedOrder[index].hasFocus,
          isTrue,
          reason: 'Tab should focus ${requestedOrder[index].debugLabel}',
        );
      }

      dropdown('Country of Birth').focusNode!.requestFocus();
      await tester.pump();
      final dropdownContainers = tester.widgetList<Container>(
        find.descendant(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is CustomDropdown &&
                widget.hintText == 'Country of Birth',
          ),
          matching: find.byType(Container),
        ),
      );
      final focusedBorder = dropdownContainers
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.border)
          .whereType<Border>()
          .where(
            (border) =>
                border.top.color == AppColors.primary &&
                border.top.width == 1.3,
          );
      expect(focusedBorder, isNotEmpty);
    },
  );

  testWidgets('repeated open requests keep one employee workspace route', (
    tester,
  ) async {
    Get.put<EmployeesController>(_EmployeesControllerStub());
    Get.put<HrAccessService>(_ReloadHrAccessService());

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/employee-list',
        getPages: [
          GetPage(
            name: '/employee-list',
            page: () => Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () {
                    showEmployeeWorkspaceDialog(context);
                    showEmployeeWorkspaceDialog(context);
                  },
                  child: const Text('Open employee twice'),
                ),
              ),
            ),
          ),
          GetPage(
            name: AppRoutes.employeeWorkspace,
            page: () => const EmployeeWorkspaceRoute(),
            fullscreenDialog: true,
            opaque: false,
            transition: Transition.fadeIn,
          ),
        ],
      ),
    );

    await tester.tap(find.text('Open employee twice'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(Get.currentRoute, AppRoutes.employeeWorkspace);
    expect(find.byType(EmployeeWorkspaceRoute), findsOneWidget);
    expect(find.byType(Form), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(Get.currentRoute, '/employee-list');
  });

  testWidgets('a refreshed employee edit route restores access and employee', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = _ReloadEmployeesControllerStub();
    final accessService = _ReloadHrAccessService();
    Get.put<EmployeesController>(controller);
    Get.put<HrAccessService>(accessService);

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '${AppRoutes.employeeWorkspace}?employeeId=employee-42',
        getPages: [
          GetPage(
            name: AppRoutes.employeeWorkspace,
            page: () => const EmployeeWorkspaceRoute(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(accessService.loadCalls, 1);
    expect(controller.restoredEmployeeId, 'employee-42');
    expect(
      find.byKey(const ValueKey('employee-workspace-loading')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('employee-workspace-surface')),
      findsOneWidget,
    );
    expect(find.text('Restored Employee'), findsOneWidget);
  });

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
    expect(find.text('01-01-2026'), findsNothing);
    final endDateEditor = find.byWidgetPredicate(
      (widget) =>
          widget is EditableText && widget.controller.text == '31-12-2026',
    );
    final editable = tester.state<EditableTextState>(endDateEditor).widget;
    editable.focusNode.requestFocus();
    editable.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: editable.controller.text.length,
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(find.text('31-12-2026'), findsNothing);
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

  testWidgets('leave editor is compact and keeps dates on one row', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = _EmployeesControllerStub();
    Get.put<EmployeesController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showEmployeeRecordDialog(
                context,
                kind: EmployeeRecordKind.leave,
                record: const EmployeeRecord({
                  '_id': 'leave-1',
                  'leave_type': 'leave-type-old',
                  'leave_type_name': 'Old leave type',
                  'start_date': '2026-09-01T00:00:00.000',
                  'end_date': '2026-09-04T00:00:00.000',
                  'number_of_days': 2,
                  'status': 'New',
                }),
              ),
              child: const Text('Open leave'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open leave'));
    await tester.pumpAndSettle();

    final dialogSize = tester.getSize(
      find.byKey(const ValueKey('employee-record-dialog-content')),
    );
    expect(dialogSize.width, lessThanOrEqualTo(700));

    final leaveTypeY = tester.getTopLeft(find.text('Leave type').first).dy;
    final startDateY = tester.getTopLeft(find.text('Start date').first).dy;
    final endDateY = tester.getTopLeft(find.text('End date').first).dy;
    final numberOfDaysY = tester
        .getTopLeft(find.text('Number of days').first)
        .dy;
    final noteY = tester.getTopLeft(find.text('Note').first).dy;

    expect(leaveTypeY, lessThan(startDateY));
    expect(startDateY, closeTo(endDateY, 0.1));
    expect(startDateY, closeTo(numberOfDaysY, 0.1));
    expect(noteY, greaterThan(startDateY));

    final numberField = tester.widget<AppTextFormField>(
      find.byKey(const ValueKey('employee-record-number_of_days')),
    );
    expect(numberField.enabled, isFalse);
    expect(numberField.fillColor, AppColors.softSurface);
    final renderedNumberField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('employee-record-number_of_days')),
        matching: find.byType(TextField),
      ),
    );
    expect(renderedNumberField.enabled, isFalse);

    final startDateField = tester.widget<AppDateFormField>(
      find.byKey(const ValueKey('employee-record-start_date-date')),
    );
    final endDateField = tester.widget<AppDateFormField>(
      find.byKey(const ValueKey('employee-record-end_date-date')),
    );
    expect(startDateField.onChanged, isNotNull);
    expect(endDateField.onChanged, isNotNull);

    await tester.tap(find.text('Leave type').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annual leave'));
    await tester.pumpAndSettle();

    expect(controller.leaveCalculationCalls, 1);
    expect(controller.calculatedLeaveTypeId, 'leave-type-1');
    expect(controller.calculatedStartDate, DateTime(2026, 9, 1));
    expect(controller.calculatedEndDate, DateTime(2026, 9, 4));
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const ValueKey('employee-record-number_of_days')),
              matching: find.byType(TextField),
            ),
          )
          .controller
          ?.text,
      '4',
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  }, skip: kIsWeb);

  testWidgets('payroll element editor is 500 pixels and one column', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Get.put<EmployeesController>(_EmployeesControllerStub());

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showEmployeeRecordDialog(
                context,
                kind: EmployeeRecordKind.payrollElement,
              ),
              child: const Text('Open payroll element'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open payroll element'));
    await tester.pumpAndSettle();

    final dialogSize = tester.getSize(
      find.byKey(const ValueKey('employee-record-dialog-content')),
    );
    expect(dialogSize.width, closeTo(500, 0.1));

    final payrollElementY = tester.getTopLeft(find.text('Payroll element')).dy;
    final valueY = tester.getTopLeft(find.text('Value')).dy;
    final startDateY = tester.getTopLeft(find.text('Start date')).dy;
    final endDateY = tester.getTopLeft(find.text('End date')).dy;
    final noteY = tester.getTopLeft(find.text('Note')).dy;
    expect(payrollElementY, lessThan(valueY));
    expect(valueY, lessThan(startDateY));
    expect(startDateY, lessThan(endDateY));
    expect(endDateY, lessThan(noteY));

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  }, skip: kIsWeb);

  testWidgets('loan and advance editor is 500 pixels and one column', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Get.put<EmployeesController>(_EmployeesControllerStub());

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showEmployeeRecordDialog(
                context,
                kind: EmployeeRecordKind.loanAdvance,
              ),
              child: const Text('Open loan and advance'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open loan and advance'));
    await tester.pumpAndSettle();

    final dialogSize = tester.getSize(
      find.byKey(const ValueKey('employee-record-dialog-content')),
    );
    expect(dialogSize.width, closeTo(500, 0.1));

    final fieldLabels = [
      'Loan / advance type',
      'Total amount',
      'Monthly installment',
      'Deduction date',
      'Note',
    ];
    final fieldPositions = fieldLabels
        .map((label) => tester.getTopLeft(find.text(label).first).dy)
        .toList(growable: false);
    for (var index = 1; index < fieldPositions.length; index++) {
      expect(fieldPositions[index], greaterThan(fieldPositions[index - 1]));
    }

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  }, skip: kIsWeb);

  testWidgets('contact editor is compact and uses the requested field rows', (
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
                kind: EmployeeRecordKind.contactRelative,
              ),
              child: const Text('Open contact'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open contact'));
    await tester.pumpAndSettle();

    final dialogSize = tester.getSize(
      find.byKey(const ValueKey('employee-record-dialog-content')),
    );
    expect(dialogSize.width, lessThanOrEqualTo(700));

    final fullNameY = tester.getTopLeft(find.text('Full name').first).dy;
    final relationshipY = tester.getTopLeft(find.text('Relationship').first).dy;
    final genderY = tester.getTopLeft(find.text('Gender').first).dy;
    final dateOfBirthY = tester.getTopLeft(find.text('Date of birth').first).dy;
    final nationalityY = tester.getTopLeft(find.text('Nationality').first).dy;
    final phoneY = tester.getTopLeft(find.text('Phone number').first).dy;
    final emailY = tester.getTopLeft(find.text('Email address').first).dy;
    final noteY = tester.getTopLeft(find.text('Note').first).dy;

    expect(fullNameY, lessThan(relationshipY));
    expect(relationshipY, closeTo(genderY, 0.1));
    expect(dateOfBirthY, closeTo(nationalityY, 0.1));
    expect(dateOfBirthY, greaterThan(relationshipY));
    expect(phoneY, closeTo(emailY, 0.1));
    expect(phoneY, greaterThan(dateOfBirthY));
    expect(noteY, greaterThan(phoneY));
    expect(find.text('Emergency contact'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  }, skip: kIsWeb);

  testWidgets('document table opens files in a themed file list', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Get.put<EmployeesController>(_EmployeesControllerStub());

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showEmployeeDocumentsDialog(context),
              child: const Text('Open documents'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open documents'));
    await tester.pumpAndSettle();

    expect(find.text('Document of Record'), findsOneWidget);
    expect(find.text('passport.pdf'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Open'), findsOneWidget);

    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Open'))
        .onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Files'), findsOneWidget);
    expect(find.text('Images'), findsOneWidget);
    expect(find.text('Other Files'), findsOneWidget);
    expect(find.text('passport.pdf'), findsOneWidget);
    expect(find.text('PDF file'), findsOneWidget);

    await tester.tap(find.byTooltip('Close files'));
    await tester.pumpAndSettle();
    expect(find.text('Files'), findsNothing);
    expect(find.text('Document of Record'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
  }, skip: kIsWeb);

  testWidgets('new document record uses two columns and previews files', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Get.put<EmployeesController>(_EmployeesControllerStub());

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showEmployeeDocumentsDialog(context),
              child: const Text('Open documents'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open documents'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Record'));
    await tester.pumpAndSettle();

    final detailsTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('employee-attachment-details-column')),
    );
    final uploadTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('employee-attachment-upload-column')),
    );
    expect(uploadTopLeft.dx, greaterThan(detailsTopLeft.dx));

    final nameY = tester.getTopLeft(find.text('Name')).dy;
    final typeY = tester.getTopLeft(find.text('Type')).dy;
    final numberY = tester.getTopLeft(find.text('Number')).dy;
    final startDateY = tester.getTopLeft(find.text('Start Date')).dy;
    final endDateY = tester.getTopLeft(find.text('End Date')).dy;
    final notesY = tester.getTopLeft(find.text('Notes')).dy;
    expect(nameY, lessThan(typeY));
    expect(typeY, closeTo(numberY, 0.1));
    expect(startDateY, closeTo(endDateY, 0.1));
    expect(startDateY, greaterThan(typeY));
    expect(notesY, greaterThan(startDateY));
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('employee-attachment-notes-field')),
          )
          .height,
      greaterThan(180),
    );

    await tester.tap(find.text('Choose files'));
    await tester.pumpAndSettle();
    expect(find.text('File too large'), findsOneWidget);
    expect(find.textContaining('50 MB or smaller'), findsOneWidget);
    expect(find.text('too-large.zip'), findsNothing);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('employee.png'), findsOneWidget);
    expect(find.text('contract.pdf'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Remove contract.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('contract.pdf'), findsNothing);
    expect(find.text('employee.png'), findsOneWidget);
  }, skip: kIsWeb);
}
