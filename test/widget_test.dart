import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_hr_system/models/company/company_identity_model.dart';
import 'package:my_hr_system/controllers/employee_controllers/employees_controller.dart';
import 'package:my_hr_system/models/employees/employee_model.dart';
import 'package:my_hr_system/models/auth/login_response_model.dart';
import 'package:my_hr_system/models/navigation/navigation_item_model.dart';
import 'package:my_hr_system/models/payroll/leave_type_model.dart';
import 'package:my_hr_system/models/payroll/payroll_element_model.dart';
import 'package:my_hr_system/models/payroll/payroll_model.dart';
import 'package:my_hr_system/models/payroll/balance_model.dart';
import 'package:my_hr_system/models/payroll/loan_advance_type_model.dart';
import 'package:my_hr_system/models/payroll/payroll_run_model.dart';
import 'package:my_hr_system/models/payroll/public_holiday_model.dart';
import 'package:my_hr_system/models/payroll/legislation_model.dart';
import 'package:my_hr_system/routes/app_routes.dart';
import 'package:my_hr_system/services/auth_session_service.dart';
import 'package:my_hr_system/services/authenticated_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('parses the backend login response', () {
    final response = LoginResponseModel.fromJson({
      'user_id': 'user-1',
      'email': 'person@company.com',
      'company_id': 'company-1',
      'role': ['admin', 'hr'],
      'access_token': 'access-token',
      'expires_in': 900,
      'refresh_token': 'refresh-token',
      'session_id': 'session-1',
      'token_type': 'bearer',
    });

    expect(response.userId, 'user-1');
    expect(response.roles, ['admin', 'hr']);
    expect(response.accessToken, 'access-token');
    expect(response.refreshToken, 'refresh-token');
  });

  test('parses company identity details', () {
    final company = CompanyIdentityModel.fromEnvelope({
      'data': {
        '_id': 'user-1',
        'user_name': 'Tony Almasri',
        'email': 'tony@company.com',
        'company_name': 'Acme HR',
        'company_logo': 'https://example.com/logo.png',
      },
    });

    expect(company.displayCompanyName, 'Acme HR');
    expect(company.userInitials, 'TA');
  });

  test('parses the responsibility-based navigation tree', () {
    final navigation = NavigationItemModel.listFromEnvelope({
      'root': [
        {
          '_id': 'menu-1',
          'name': 'Human resources',
          'isMenu': true,
          'children': [
            {
              '_id': 'screen-1',
              'name': 'Employees',
              'isMenu': false,
              'route_name': '/employees',
              'children': [],
            },
          ],
        },
      ],
    });

    expect(navigation, hasLength(1));
    expect(navigation.first.children.single.name, 'Employees');
    expect(navigation.first.children.single.canOpen, isTrue);
  });

  test('maps backend menu routes to website paths and back', () {
    expect(
      AppRoutes.screenPathForMenuRoute('/leave_types'),
      '/mainScreen/leave-types',
    );
    expect(
      AppRoutes.screenPathForMenuRoute('/payrollRuns'),
      '/mainScreen/payroll-runs',
    );
    expect(
      AppRoutes.menuRouteForScreenSlug('loan-and-advances-types'),
      '/loanandadvancestypes',
    );
    expect(
      AppRoutes.isMenuRouteActive('/payroll_runs', '/payrollruns'),
      isTrue,
    );
    expect(
      AppRoutes.screenPathForMenuRoute('/public_holidays'),
      '/mainScreen/public-holidays',
    );
    expect(
      AppRoutes.screenPathForMenuRoute('/legislation'),
      '/mainScreen/legislation',
    );
    expect(
      AppRoutes.screenPathForMenuRoute('/employees'),
      '/mainScreen/employees',
    );
  });

  test('parses employee profile sections and derives the person type', () {
    final employee = EmployeeDetails.fromJson({
      '_id': 'employee-1',
      'full_name': 'Paul Admin',
      'hire_date': '2026-02-01T00:00:00.000Z',
      'end_date': null,
      'employer': 'employer-1',
      'employer_name': 'DataHub AI',
      'department': 'department-1',
      'department_name': 'HR',
      'job_title': 'job-1',
      'job_title_name': 'HR Manager',
      'location': 'location-1',
      'location_name': 'Dubai',
      'country_of_birth': 'country-1',
      'country_of_birth_name': 'Jordan',
      'gender': 'gender-1',
      'gender_name': 'Male',
      'martial_status': 'marital-1',
      'martial_status_name': 'Married',
      'legislation': 'legislation-1',
      'legislation_name': 'UAE Legislation',
      'payroll': 'payroll-1',
      'payroll_name': 'Monthly Payroll',
      'addresses_list': [
        {'_id': 'address-1', 'line': 'Business Bay'},
      ],
      'payrolls_details': [
        {'_id': 'element-1', 'name_value': 'Basic Salary', 'value': 2500},
      ],
      'assignment_balances': [
        {'_id': 'balance-1', 'name': 'Annual Leave', 'balance': '1.83'},
      ],
    });

    expect(employee.personType, 'Employee');
    expect(employee.addresses.single.text('line'), 'Business Bay');
    expect(employee.payrollElements.single.number('value'), 2500);
    expect(employee.assignmentBalances.single.number('balance'), 1.83);
  });

  test('parses employee attachment records and uploaded files', () {
    final attachment = EmployeeAttachment.fromJson({
      '_id': 'attachment-1',
      'name': 'Passport Copy',
      'attachment_type': 'type-1',
      'attachment_type_name': 'Passport',
      'number': 'P-123',
      'start_date': '2022-01-01T00:00:00.000Z',
      'attachments': [
        {
          'file_name': 'passport.pdf',
          'attach_url': 'https://example.com/passport.pdf',
          'resource_type': 'raw',
          'format': 'pdf',
        },
      ],
    });

    expect(attachment.typeName, 'Passport');
    expect(attachment.startDate, DateTime.utc(2022));
    expect(attachment.files.single.name, 'passport.pdf');
  });

  test('parses public holidays without shifting their calendar date', () {
    final holiday = PublicHolidayModel.fromJson({
      '_id': 'holiday-1',
      'name': 'National Day',
      'date': '2026-12-02T00:00:00.000Z',
      'legislation': 'legislation-1',
    });

    expect(holiday.date, DateTime(2026, 12, 2));
    expect(publicHolidayDateKey(holiday.date), '2026-12-02');
    expect(holiday.toRequestJson(), {
      'name': 'National Day',
      'date': '2026-12-02T00:00:00.000Z',
      'legislation': 'legislation-1',
    });
  });

  test('parses legislation rules and creates the backend payload', () {
    final legislation = LegislationModel.fromJson({
      '_id': 'legislation-1',
      'name': 'UAE Legislation',
      'weekend': ['Saturday', 'Sunday'],
      'number_of_paid_days_for_sick_leave': '15',
      'number_of_half_paid_days_for_sick_leave': 30,
      'number_of_unpaid_days_for_sick_leave': 45,
      'number_of_paid_days_for_maternity_leave': 60,
      'number_of_paid_days_for_compassionate_leave': 3,
      'number_of_paid_days_for_paternity_leave': 5,
      'number_of_working_hours_for_overtime_normal': '8.5',
      'number_of_working_hours_for_overtime_holidays': 6,
      'social_security_ceilings': [
        {
          'employee_percentage': 7.5,
          'employer_percentage': 12.5,
          'ceiling': 20000,
          'start_date': '2026-01-01T00:00:00.000Z',
          'end_date': null,
        },
      ],
      'service_tax_percentage': 5,
      'income_tax_percentage': 0,
      'income_tax_ceiling': 0,
      'income_tax_brackets': [
        {'from_amount': 0, 'to_amount': 5000, 'percentage': 5},
      ],
      'gratuity_first_5_years': 21,
      'gratuity_after_5_years': 30,
    });

    expect(legislation.name, 'UAE Legislation');
    expect(legislation.weekend, ['Saturday', 'Sunday']);
    expect(legislation.normalOvertimeHours, 8.5);
    expect(
      legislation.socialSecurityCeilings.single.startDate,
      DateTime(2026, 1, 1),
    );
    final payload = legislation.toRequestJson();
    expect(payload['social_security_employee_percentage'], 7.5);
    expect(
      payload['social_security_ceiling_start_date'],
      '2026-01-01T00:00:00.000Z',
    );
    expect((payload['income_tax_brackets'] as List).single, {
      'from_amount': 0.0,
      'to_amount': 5000.0,
      'percentage': 5.0,
    });
  });

  test('parses payroll element details and based elements', () {
    final element = PayrollElementModel.fromJson({
      '_id': 'element-1',
      'key': 'BASIC SALARY',
      'name': 'Basic Salary',
      'type': 'Earning',
      'priority': '100',
      'function': 'PY_INPUT_VALUE_FF',
      'is_allow_override': true,
      'element_details': [
        {
          '_id': 'based-1',
          'name': 'element-2',
          'name_value': 'Allowance',
          'type': 'Add',
        },
      ],
    });

    expect(element.id, 'element-1');
    expect(element.allowOverride, isTrue);
    expect(element.basedElements.single.elementName, 'Allowance');
    expect(element.toRequestJson()['function'], 'PY_INPUT_VALUE_FF');
  });

  test('parses leave types and their based payroll elements', () {
    final leaveType = LeaveTypeModel.fromJson({
      '_id': 'leave-type-1',
      'name': 'Annual Leave',
      'code': 'AL',
      'type': 'Working Days',
      'based_element': 'element-1',
      'based_element_name': 'Annual Leave Entitlement',
    });

    expect(leaveType.id, 'leave-type-1');
    expect(leaveType.type, 'Working Days');
    expect(leaveType.basedElementName, 'Annual Leave Entitlement');
    expect(leaveType.toRequestJson()['based_element'], 'element-1');
  });

  test('parses payroll details and creates backend request payloads', () {
    final payroll = PayrollModel.fromJson({
      '_id': 'payroll-1',
      'name': 'Monthly Payroll',
      'notes': 'Monthly staff payroll',
      'payment_type': 'type-1',
      'payment_type_name': 'Monthly',
      'details': [
        {
          '_id': 'period-1',
          'period_name': '2026-08-Monthly Payroll',
          'start_date': '2026-08-01T00:00:00',
          'end_date': '2026-08-31T00:00:00',
          'status': 'Active',
        },
      ],
    });

    expect(payroll.paymentTypeName, 'Monthly');
    expect(payroll.periods.single.startDate, DateTime(2026, 8));
    expect(payroll.toRequestJson()['payment_type'], 'type-1');
    expect(payroll.periods.single.toRequestJson()['status'], 'Active');
  });

  test('parses balances and their based payroll elements', () {
    final balance = BalanceModel.fromJson({
      '_id': 'balance-1',
      'name': 'Annual Leave Balance',
      'type': 'Number',
      'balance_dimension': 'Inception to Date',
      'description': 'Annual leave total',
      'show_on_assignment': true,
      'show_on_payroll': '1',
      'show_on_leave': 'yes',
      'element_details': [
        {
          '_id': 'based-1',
          'name': 'element-1',
          'name_value': 'Annual Leave',
          'type': 'Subtract',
        },
      ],
    });

    expect(balance.name, 'Annual Leave Balance');
    expect(balance.showOnPayroll, isTrue);
    expect(balance.basedElements.single.elementName, 'Annual Leave');
    expect(balance.toRequestJson()['balance_dimension'], 'Inception to Date');
    expect(balance.basedElements.single.toRequestJson(), {
      'name': 'element-1',
      'type': 'Subtract',
    });
  });

  test('parses loan and advance types and creates backend payloads', () {
    final type = LoanAdvanceTypeModel.fromJson({
      '_id': 'loan-type-1',
      'name': 'Employee Loan',
      'code': 'LOAN',
      'based_element': 'element-1',
      'based_element_name': 'Loan Deduction',
    });

    expect(type.id, 'loan-type-1');
    expect(type.basedElementName, 'Loan Deduction');
    expect(type.toRequestJson(), {
      'name': 'Employee Loan',
      'code': 'LOAN',
      'based_element': 'element-1',
    });
  });

  test('parses payroll-run details and employee result values', () {
    final details = PayrollRunDetails.fromJson({
      '_id': 'run-1',
      'run_number': 'R-00118',
      'payroll_name': 'Monthly Payroll',
      'period_name': '2026-09-Monthly Payroll',
      'description': 'All Employees',
      'payment_number': 'PP-0001',
      'employees_details': [
        {
          '_id': 'run-employee-1',
          'employee_id': 'employee-1',
          'employee_name': 'Paul Admin',
          'total_payments': '3651.42',
          'total_deductions': 1801.52,
          'net_salary': 1849.90,
          'run_employee_details': [
            {
              '_id': 'result-1',
              'element_name': 'Basic Salary',
              'element_type': 'Earning',
              'payment': 3651.42,
              'deduction': 0,
            },
          ],
          'run_employee_information': [],
        },
      ],
    });

    expect(details.runNumber, 'R-00118');
    expect(details.employees.single.totalPayments, 3651.42);
    expect(
      details.employees.single.payrollElements.single.name,
      'Basic Salary',
    );
    expect(PayrollRunSummary.fromDetails(details).paymentNumber, 'PP-0001');
  });

  test('uploads payslip bytes as an authenticated multipart request', () async {
    SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/payroll_runs/email_payslips/run-1');
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(
        request.headers['Content-Type'],
        startsWith('multipart/form-data;'),
      );
      expect(
        String.fromCharCodes(request.bodyBytes),
        contains('employee-1.pdf'),
      );
      return http.Response(
        '{"sent":1,"skipped":0,"failed":0,"results":[]}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = AuthenticatedApiService(
      httpClient: client,
      session: AuthSessionService(),
    );

    final response = await api.postMultipartBytes(
      '/payroll_runs/email_payslips/run-1',
      fieldName: 'payslips',
      files: {'employee-1.pdf': '%PDF-test'.codeUnits},
    );

    expect(response['sent'], 1);
  });

  test(
    'sends employee form fields and image as authenticated multipart',
    () async {
      SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});
      var method = '';
      var path = '';
      var authorization = '';
      var contentType = '';
      var sentBody = '';
      final client = MockClient((request) async {
        method = request.method;
        path = request.url.path;
        authorization = request.headers['Authorization'] ?? '';
        contentType = request.headers['Content-Type'] ?? '';
        sentBody = String.fromCharCodes(request.bodyBytes);
        return http.Response(
          '{"employee":{"_id":"employee-1","full_name":"Paul Admin"}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = AuthenticatedApiService(
        httpClient: client,
        session: AuthSessionService(),
      );

      final response = await api.multipartJson(
        'PATCH',
        '/employees/update_employee/employee-1',
        fields: {'full_name': 'Paul Admin'},
        fileField: 'person_image',
        fileBytes: [1, 2, 3],
        fileName: 'employee.png',
      );

      expect((response['employee'] as Map)['_id'], 'employee-1');
      expect(method, 'PATCH');
      expect(path, '/employees/update_employee/employee-1');
      expect(authorization, 'Bearer test-token');
      expect(contentType, startsWith('multipart/form-data;'));
      expect(sentBody, contains('name="full_name"'));
      expect(sentBody, contains('Paul Admin'));
      expect(sentBody, contains('name="person_image"'));
      expect(sentBody, contains('employee.png'));
    },
  );

  test('uploads multiple employee attachment files with form fields', () async {
    SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});
    final client = MockClient((request) async {
      final body = String.fromCharCodes(request.bodyBytes);
      expect(request.method, 'POST');
      expect(request.url.path, '/attachment/add_new_attachment');
      expect(body, contains('name="document_id"'));
      expect(body, contains('employee-1'));
      expect(body, contains('name="attachments"'));
      expect(body, contains('passport.pdf'));
      expect(body, contains('visa.png'));
      return http.Response(
        '{"result":{"_id":"attachment-1"}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = AuthenticatedApiService(
      httpClient: client,
      session: AuthSessionService(),
    );

    final response = await api.multipartJson(
      'POST',
      '/attachment/add_new_attachment',
      fields: {'document_id': 'employee-1'},
      fileField: 'attachments',
      files: {
        'passport.pdf': [1, 2, 3],
        'visa.png': [4, 5, 6],
      },
    );

    expect((response['result'] as Map)['_id'], 'attachment-1');
  });

  test('employee dropdown lookups survive mutation between openings', () async {
    SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      expect(request.url.path, '/list_of_values/get_list_values_by_code');
      return http.Response(
        '{"values":[{"_id":"employer-1","name":"DataHub AI"}]}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = AuthenticatedApiService(
      httpClient: client,
      session: AuthSessionService(),
    );
    final controller = EmployeesController(api: api);

    final firstOpening = await controller.listValues('EMPLOYERS');
    firstOpening.clear();
    final secondOpening = await controller.listValues('EMPLOYERS');

    expect(secondOpening, contains('employer-1'));
    expect(requestCount, 1);
  });

  test(
    'employee period filter refreshes payroll elements and balances separately',
    () async {
      SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});
      final requestBodies = <String, Map<String, dynamic>>{};
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        requestBodies[request.url.path] = Map<String, dynamic>.from(
          jsonDecode(request.body) as Map,
        );
        if (request.url.path ==
            '/employees/filter_employee_payrolls_on_period_date/employee-1') {
          return http.Response(
            '{"payrolls_elements":[{"_id":"element-1","name_value":"Basic Salary","value":5000}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path ==
            '/employees/get_assignment_balances_depending_on_period/employee-1') {
          return http.Response(
            '{"balances":[{"_id":"balance-1","name":"Annual Leave","balance":12.5}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });
      final controller = EmployeesController(
        api: AuthenticatedApiService(
          httpClient: client,
          session: AuthSessionService(),
        ),
      );
      controller.selectedEmployee.value = EmployeeDetails.fromJson({
        '_id': 'employee-1',
        'full_name': 'Paul Admin',
        'hire_date': '2026-01-01T00:00:00.000Z',
      });
      controller.hireDate.text = '2026-01-01';

      await controller.setPeriod('2026-06');

      expect(controller.selectedPeriod.value, '2026-06');
      expect(
        controller.payrollElements.single.text('name_value'),
        'Basic Salary',
      );
      expect(controller.assignmentBalances.single.number('balance'), 12.5);
      expect(
        requestBodies['/employees/filter_employee_payrolls_on_period_date/employee-1'],
        {'period': '2026-06'},
      );
      expect(
        requestBodies['/employees/get_assignment_balances_depending_on_period/employee-1'],
        {'period_date': '2026-06'},
      );
      expect(controller.availablePeriods, contains('2026-06'));
      expect(controller.isLoadingPeriod.value, isFalse);
    },
  );

  testWidgets('employee period filter rebuilds the visible payroll rows', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});
    final client = MockClient((request) async {
      final body = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
      if (request.url.path ==
          '/employees/filter_employee_payrolls_on_period_date/employee-1') {
        final period = body['period'] as String;
        return http.Response(
          '{"payrolls_elements":[{"_id":"$period","name_value":"$period payroll"}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path ==
          '/employees/get_assignment_balances_depending_on_period/employee-1') {
        return http.Response(
          '{"balances":[]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not found', 404);
    });
    final controller = EmployeesController(
      api: AuthenticatedApiService(
        httpClient: client,
        session: AuthSessionService(),
      ),
    );
    controller.selectedEmployee.value = EmployeeDetails.fromJson({
      '_id': 'employee-1',
      'full_name': 'Paul Admin',
      'hire_date': '2026-01-01T00:00:00.000Z',
    });
    controller.payrollElements.assignAll([
      const EmployeeRecord({'_id': 'initial', 'name_value': 'Initial payroll'}),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Obx(
          () => _PayrollRowsProbe(
            records: controller.recordsFor(EmployeeRecordKind.payrollElement),
          ),
        ),
      ),
    );
    expect(find.text('Initial payroll'), findsOneWidget);

    await controller.setPeriod('2026-04');
    await tester.pumpAndSettle();
    expect(find.text('2026-04 payroll'), findsOneWidget);
    expect(find.text('Initial payroll'), findsNothing);

    await controller.setPeriod('2026-05');
    await tester.pumpAndSettle();
    expect(find.text('2026-05 payroll'), findsOneWidget);
    expect(find.text('2026-04 payroll'), findsNothing);
  });

  test('employee employment values are added through list-values API', () async {
    SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});
    var valuesRequestCount = 0;
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-token');
      if (request.url.path == '/list_of_values/get_list_values_by_code') {
        valuesRequestCount++;
        expect(request.url.queryParameters['code'], 'EMPLOYERS');
        final name = valuesRequestCount == 1
            ? 'Existing Employer'
            : 'New Employer';
        return http.Response(
          '{"values":[{"_id":"employer-$valuesRequestCount","name":"$name"}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/list_of_values/get_list_details_by_code') {
        expect(request.method, 'GET');
        expect(request.url.queryParameters['code'], 'EMPLOYERS');
        return http.Response(
          '{"list_details":{"_id":"employers-list"}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/list_of_values/add_new_value/employers-list') {
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {
          'name': 'New Employer',
          'mastered_by_id': '',
        });
        return http.Response(
          '{"message":"Value added successfully!","list":{"_id":"employer-2","name":"New Employer"}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not found', 404);
    });
    final controller = EmployeesController(
      api: AuthenticatedApiService(
        httpClient: client,
        session: AuthSessionService(),
      ),
    );

    final firstOpening = await controller.listValues('EMPLOYERS');
    final saved = await controller.addListValue('EMPLOYERS', 'New Employer');
    final secondOpening = await controller.listValues('EMPLOYERS');

    expect(firstOpening['employer-1']['name'], 'Existing Employer');
    expect(saved, isTrue);
    expect(secondOpening['employer-2']['name'], 'New Employer');
    expect(valuesRequestCount, 2);
  });

  test(
    'loads leave payroll elements from the authenticated LOV endpoint',
    () async {
      SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/leave_types/get_leave_payroll_elements_for_lov',
        );
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          '{"elements":[{"_id":"element-1","name":"Annual Leave Entitlement"}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = AuthenticatedApiService(
        httpClient: client,
        session: AuthSessionService(),
      );

      final response = await api.getJson(
        '/leave_types/get_leave_payroll_elements_for_lov',
      );
      final options = (response['elements'] as List)
          .whereType<Map>()
          .map(
            (item) => LeavePayrollElementOption.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      expect(options.single.id, 'element-1');
      expect(options.single.name, 'Annual Leave Entitlement');
    },
  );

  test('accepts a null body from successful write requests', () async {
    SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});
    final client = MockClient(
      (_) async => http.Response(
        'null',
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    final api = AuthenticatedApiService(
      httpClient: client,
      session: AuthSessionService(),
    );

    expect(await api.postJson('/post-test'), isEmpty);
    expect(await api.patchJson('/patch-test'), isEmpty);
    expect(await api.deleteJson('/delete-test'), isEmpty);
  });
}

class _PayrollRowsProbe extends StatelessWidget {
  const _PayrollRowsProbe({required this.records});

  final List<EmployeeRecord> records;

  @override
  Widget build(BuildContext context) {
    return Text(records.map((record) => record.text('name_value')).join(','));
  }
}
