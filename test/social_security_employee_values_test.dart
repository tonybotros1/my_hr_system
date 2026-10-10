import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_hr_system/controllers/payroll_controllers/legislation_controller.dart';
import 'package:my_hr_system/models/payroll/social_security_employee_value_model.dart';
import 'package:my_hr_system/services/auth_session_service.dart';
import 'package:my_hr_system/services/authenticated_api_service.dart';
import 'package:my_hr_system/widgets/legislation/social_security_employee_values_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses and searches an employee social security value', () {
    final value = SocialSecurityEmployeeValueModel.fromJson({
      '_id': 'assignment-1',
      'employee_id': 'employee-1',
      'employee_name': 'Eman Mohammad Jaradat',
      'employee_number': 'PE-0012',
      'social_security_registration_number': 'SS-123',
      'payroll_element_name': 'Social Security Employee',
      'value': 3612,
      'has_override': true,
      'start_date': '2024-04-01T00:00:00Z',
      'end_date': null,
    });

    expect(value.employeeName, 'Eman Mohammad Jaradat');
    expect(value.value, 3612);
    expect(value.hasOverride, isTrue);
    expect(value.startDate, DateTime(2024, 4, 1));
    expect(value.endDate, isNull);
    expect(value.matches('PE-0012'), isTrue);
    expect(value.matches('3612'), isTrue);
    expect(value.matches('not found'), isFalse);
  });

  test(
    'loads social security employee values for the edited legislation',
    () async {
      SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/legislation/legislation-1/social_security_employee_values',
        );
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          '{"employee_values":[{"_id":"assignment-2","employee_id":"employee-2","employee_name":"Ahmad Default","employee_number":"PE-0001","social_security_registration_number":"SS-100","payroll_element_name":"Social Security Employee","value":null,"has_override":false,"start_date":"2024-04-01T00:00:00Z","end_date":null},{"_id":"assignment-1","employee_id":"employee-1","employee_name":"Eman Jaradat","employee_number":"PE-0012","social_security_registration_number":"SS-123","payroll_element_name":"Social Security Employee","value":3612,"has_override":true,"start_date":"2024-04-01T00:00:00Z","end_date":null}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final controller = LegislationController(
        api: AuthenticatedApiService(
          httpClient: client,
          session: AuthSessionService(),
        ),
      );
      addTearDown(controller.dispose);
      controller.currentLegislationId.value = 'legislation-1';

      await controller.fetchSocialSecurityEmployeeValues();

      expect(controller.socialSecurityEmployeeValues, hasLength(2));
      expect(
        controller.socialSecurityEmployeeValues.first.employeeName,
        'Eman Jaradat',
      );
      expect(controller.socialSecurityEmployeeValues.first.value, 3612);
      expect(controller.socialSecurityEmployeeValues.last.hasOverride, isFalse);
      expect(controller.socialSecurityEmployeeValuesError.value, isNull);
      expect(controller.isLoadingSocialSecurityEmployeeValues.value, isFalse);
    },
  );

  testWidgets('shows the employee value in the mobile-friendly dialog', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});
    var overrideCleared = false;
    final client = MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.path == '/legislation/search_engine_for_legislations') {
        return http.Response(
          '{"legislations_elements":[]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'GET' &&
          request.url.path ==
              '/legislation/legislation-1/social_security_employee_values') {
        return http.Response(
          overrideCleared
              ? '{"employee_values":[{"_id":"assignment-1","employee_id":"employee-1","employee_name":"Eman Jaradat","employee_number":"PE-0012","social_security_registration_number":"SS-123","payroll_element_name":"Social Security Employee","value":null,"has_override":false,"start_date":"2024-04-01T00:00:00Z","end_date":null},{"_id":"assignment-2","employee_id":"employee-2","employee_name":"Ahmad Default","employee_number":"PE-0001","social_security_registration_number":"SS-100","payroll_element_name":"Social Security Employee","value":null,"has_override":false,"start_date":"2024-04-01T00:00:00Z","end_date":null}]}'
              : '{"employee_values":[{"_id":"assignment-2","employee_id":"employee-2","employee_name":"Ahmad Default","employee_number":"PE-0001","social_security_registration_number":"SS-100","payroll_element_name":"Social Security Employee","value":null,"has_override":false,"start_date":"2024-04-01T00:00:00Z","end_date":null},{"_id":"assignment-1","employee_id":"employee-1","employee_name":"Eman Jaradat","employee_number":"PE-0012","social_security_registration_number":"SS-123","payroll_element_name":"Social Security Employee","value":3612,"has_override":true,"start_date":"2024-04-01T00:00:00Z","end_date":null}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'PATCH' &&
          request.url.path ==
              '/legislation/legislation-1/social_security_employee_values/assignment-1/clear_override') {
        overrideCleared = true;
        return http.Response(
          '{"cleared_assignment_id":"assignment-1"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not found', 404);
    });
    final controller = LegislationController(
      api: AuthenticatedApiService(
        httpClient: client,
        session: AuthSessionService(),
      ),
    );
    controller.currentLegislationId.value = 'legislation-1';
    controller.name.text = 'Jordan Legislation';
    Get.testMode = true;
    Get.put(controller);
    addTearDown(Get.reset);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 800));
    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSocialSecurityEmployeeValuesDialog(context),
              child: const Text('Open values'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open values'));
    await tester.pumpAndSettle();

    expect(find.text('Social Security Employee Values'), findsOneWidget);
    expect(find.text('Eman Jaradat'), findsOneWidget);
    expect(find.text('3612'), findsOneWidget);
    expect(find.text('PE-0012'), findsOneWidget);
    expect(
      controller.socialSecurityEmployeeValues
          .map((value) => value.employeeName)
          .toList(),
      ['Eman Jaradat', 'Ahmad Default'],
    );
    final clearButton = find.widgetWithText(OutlinedButton, 'Clear override');
    expect(clearButton, findsOneWidget);

    await tester.ensureVisible(clearButton);
    await tester.pumpAndSettle();
    await tester.tap(clearButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear override'));
    await tester.pumpAndSettle();

    expect(overrideCleared, isTrue);
    expect(find.text('Clear override'), findsNothing);
    expect(find.text('Default'), findsWidgets);
    expect(
      controller.socialSecurityEmployeeValues.every(
        (value) => !value.hasOverride,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
