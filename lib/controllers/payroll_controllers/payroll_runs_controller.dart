import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../models/payroll/payroll_run_model.dart';
import '../../routes/app_routes.dart';
import '../../services/authenticated_api_service.dart';
import '../../services/payroll_run_document_service.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';

class PayrollRunsController extends GetxController {
  PayrollRunsController({
    AuthenticatedApiService? api,
    PayrollRunDocumentService? documents,
  }) : _apiOverride = api,
       _documents = documents ?? const PayrollRunDocumentService();

  final AuthenticatedApiService? _apiOverride;
  final PayrollRunDocumentService _documents;
  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();

  final runNumberFilter = TextEditingController();
  final periodNameFilter = TextEditingController();
  final employeeSearch = TextEditingController();
  final elementSearch = TextEditingController();
  final createFormKey = GlobalKey<FormState>();

  final allRuns = <PayrollRunSummary>[].obs;
  final filteredRuns = <PayrollRunSummary>[].obs;
  final payrollOptions = <PayrollRunLovOption>[].obs;
  final periodOptions = <PayrollRunLovOption>[].obs;
  final employeeOptions = <PayrollRunLovOption>[].obs;
  final elementOptions = <PayrollRunLovOption>[].obs;
  final companyDetails = <String, dynamic>{}.obs;

  final selectedFilterPayrollId = RxnString();
  final selectedPayrollId = RxnString();
  final selectedPeriodId = RxnString();
  final selectedEmployeeId = RxnString();
  final selectedElementId = RxnString();
  final selectedDetails = Rxn<PayrollRunDetails>();
  final selectedEmployee = Rxn<PayrollRunEmployee>();
  final employeeQuery = ''.obs;
  final elementQuery = ''.obs;

  final isLoading = false.obs;
  final isLoadingDetails = false.obs;
  final isLoadingOptions = false.obs;
  final isCreating = false.obs;
  final isRollingBack = false.obs;
  final isExporting = false.obs;
  final isEmailing = false.obs;
  final printingEmployeeId = ''.obs;
  final listError = RxnString();
  final currentPage = 0.obs;
  final pageSize = 1.obs;

  bool _payrollOptionsLoaded = false;
  bool _periodOptionsLoaded = false;
  bool _employeeOptionsLoaded = false;
  bool _elementOptionsLoaded = false;
  int? _scheduledPageSize;

  @override
  void onInit() {
    super.onInit();
    unawaited(fetchPayrollRuns());
  }

  List<PayrollRunSummary> get visibleRuns {
    final start = currentPage.value * pageSize.value;
    if (start >= filteredRuns.length) return const [];
    final end = (start + pageSize.value).clamp(0, filteredRuns.length).toInt();
    return filteredRuns.sublist(start, end);
  }

  int get totalPages =>
      filteredRuns.isEmpty ? 1 : (filteredRuns.length / pageSize.value).ceil();

  int get rowStart =>
      filteredRuns.isEmpty ? 0 : currentPage.value * pageSize.value + 1;

  int get rowEnd => ((currentPage.value + 1) * pageSize.value)
      .clamp(0, filteredRuns.length)
      .toInt();

  bool get canGoPrevious => currentPage.value > 0;
  bool get canGoNext => currentPage.value + 1 < totalPages;

  List<PayrollRunEmployee> get visibleEmployees {
    final employees = selectedDetails.value?.employees ?? const [];
    final query = employeeQuery.value.trim().toLowerCase();
    if (query.isEmpty) return employees;
    return employees
        .where(
          (employee) =>
              employee.employeeName.toLowerCase().contains(query) ||
              employee.employeeNumber.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  List<PayrollRunElement> get visibleElements {
    final elements = selectedEmployee.value?.payrollElements ?? const [];
    final query = elementQuery.value.trim().toLowerCase();
    if (query.isEmpty) return elements;
    return elements
        .where((element) => element.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  List<PayrollRunElement> get visibleInformationElements =>
      selectedEmployee.value?.informationElements ?? const [];

  Map<String, dynamic> get payrollDropdownItems =>
      _dropdownItems(payrollOptions, 'name');

  Map<String, dynamic> get periodDropdownItems =>
      _dropdownItems(periodOptions, 'period_name');

  Map<String, dynamic> get employeeDropdownItems =>
      _dropdownItems(employeeOptions, 'full_name');

  Map<String, dynamic> get elementDropdownItems =>
      _dropdownItems(elementOptions, 'name');

  String payrollName(String? id) => _optionName(payrollOptions, id);
  String periodName(String? id) => _optionName(periodOptions, id);
  String employeeName(String? id) => _optionName(employeeOptions, id);
  String elementName(String? id) => _optionName(elementOptions, id);

  Map<String, dynamic> _dropdownItems(
    Iterable<PayrollRunLovOption> options,
    String labelKey,
  ) {
    return {
      for (final option in options)
        option.id: {'_id': option.id, labelKey: option.label},
    };
  }

  String _optionName(Iterable<PayrollRunLovOption> options, String? id) {
    if (id == null || id.isEmpty) return '';
    for (final option in options) {
      if (option.id == id) return option.label;
    }
    return '';
  }

  void schedulePageSize(int rows) {
    final normalizedRows = rows < 1 ? 1 : rows;
    if (normalizedRows == pageSize.value ||
        normalizedRows == _scheduledPageSize) {
      return;
    }
    _scheduledPageSize = normalizedRows;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scheduledRows = _scheduledPageSize;
      _scheduledPageSize = null;
      if (isClosed ||
          scheduledRows == null ||
          scheduledRows == pageSize.value) {
        return;
      }
      final firstVisibleIndex = currentPage.value * pageSize.value;
      pageSize.value = scheduledRows;
      currentPage.value = filteredRuns.isEmpty
          ? 0
          : (firstVisibleIndex ~/ scheduledRows)
                .clamp(0, totalPages - 1)
                .toInt();
    });
  }

  Future<void> fetchPayrollRuns() async {
    if (isLoading.value) return;
    isLoading.value = true;
    listError.value = null;
    try {
      final response = await _api.getJson('/payroll_runs/get_all_payroll_runs');
      final rawRuns = response['payroll_runs'];
      if (rawRuns is! List) throw const FormatException('Missing payroll runs');
      allRuns.assignAll(
        rawRuns.whereType<Map>().map(
          (item) => PayrollRunSummary.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
      applyFilters();
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      listError.value = error.message;
    } on FormatException {
      listError.value = 'The server returned invalid payroll-run data.';
    } catch (_) {
      listError.value = 'Payroll runs could not be loaded.';
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    final runQuery = runNumberFilter.text.trim().toLowerCase();
    final periodQuery = periodNameFilter.text.trim().toLowerCase();
    final payrollFilter = payrollName(
      selectedFilterPayrollId.value,
    ).toLowerCase();
    filteredRuns.assignAll(
      allRuns.where((run) {
        return (runQuery.isEmpty ||
                run.runNumber.toLowerCase().contains(runQuery)) &&
            (periodQuery.isEmpty ||
                run.periodName.toLowerCase().contains(periodQuery)) &&
            (payrollFilter.isEmpty ||
                run.payrollName.toLowerCase() == payrollFilter);
      }),
    );
    currentPage.value = 0;
  }

  Future<void> clearFilters() async {
    runNumberFilter.clear();
    periodNameFilter.clear();
    selectedFilterPayrollId.value = null;
    await fetchPayrollRuns();
  }

  Future<Map<String, dynamic>> getPayrollsForDropdown() async {
    final loaded = await loadPayrollOptions(forceRefresh: true);
    return loaded ? payrollDropdownItems : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getPeriodsForDropdown() async {
    final payrollId = selectedPayrollId.value;
    if (payrollId == null || payrollId.isEmpty) return {};
    final loaded = await loadPeriodOptions(forceRefresh: true);
    return loaded ? periodDropdownItems : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getEmployeesForDropdown() async {
    final payrollId = selectedPayrollId.value;
    if (payrollId == null || payrollId.isEmpty) return {};
    final loaded = await loadEmployeeOptions(forceRefresh: true);
    return loaded ? employeeDropdownItems : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getElementsForDropdown() async {
    final loaded = await loadElementOptions(forceRefresh: true);
    return loaded ? elementDropdownItems : <String, dynamic>{};
  }

  Future<bool> loadPayrollOptions({bool forceRefresh = false}) async {
    if (_payrollOptionsLoaded && !forceRefresh) return true;
    final loaded = await _loadOptions(
      path: '/payroll_runs/get_payroll_for_lov',
      listKey: 'all_payrolls',
      labelKey: 'name',
      target: payrollOptions,
      errorLabel: 'payroll names',
    );
    if (loaded) _payrollOptionsLoaded = true;
    return loaded;
  }

  Future<bool> loadPeriodOptions({bool forceRefresh = false}) async {
    final payrollId = selectedPayrollId.value ?? '';
    if (payrollId.isEmpty) return false;
    if (_periodOptionsLoaded && !forceRefresh) return true;
    final loaded = await _loadOptions(
      path: '/payroll_runs/get_payroll_periods_for_lov/$payrollId',
      listKey: 'all_periods',
      labelKey: 'period_name',
      target: periodOptions,
      errorLabel: 'payroll periods',
    );
    if (loaded) _periodOptionsLoaded = true;
    return loaded;
  }

  Future<bool> loadEmployeeOptions({bool forceRefresh = false}) async {
    final payrollId = selectedPayrollId.value ?? '';
    if (payrollId.isEmpty) return false;
    if (_employeeOptionsLoaded && !forceRefresh) return true;
    final loaded = await _loadOptions(
      path: '/payroll_runs/get_all_employees_for_payroll_runs_lov/$payrollId',
      listKey: 'all_employees',
      labelKey: 'full_name',
      target: employeeOptions,
      errorLabel: 'employees',
    );
    if (loaded) _employeeOptionsLoaded = true;
    return loaded;
  }

  Future<bool> loadElementOptions({bool forceRefresh = false}) async {
    if (_elementOptionsLoaded && !forceRefresh) return true;
    final loaded = await _loadOptions(
      path: '/payroll_elements/get_payroll_elements_for_lov',
      listKey: 'elements',
      labelKey: 'name',
      target: elementOptions,
      errorLabel: 'payroll elements',
    );
    if (loaded) _elementOptionsLoaded = true;
    return loaded;
  }

  Future<bool> _loadOptions({
    required String path,
    required String listKey,
    required String labelKey,
    required RxList<PayrollRunLovOption> target,
    required String errorLabel,
  }) async {
    while (!isClosed && isLoadingOptions.value) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    if (isClosed) return false;
    isLoadingOptions.value = true;
    try {
      final response = await _api.getJson(path);
      final rawOptions = response[listKey];
      if (rawOptions is! List) throw const FormatException('Missing options');
      target.assignAll(
        rawOptions
            .whereType<Map>()
            .map(
              (item) => PayrollRunLovOption.fromJson(
                Map<String, dynamic>.from(item),
                labelKey: labelKey,
              ),
            )
            .where((option) => option.id.isNotEmpty),
      );
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The $errorLabel could not be loaded.');
    } finally {
      isLoadingOptions.value = false;
    }
    return false;
  }

  Future<bool> prepareNewRun() async {
    createFormKey.currentState?.reset();
    selectedPayrollId.value = null;
    selectedPeriodId.value = null;
    selectedEmployeeId.value = null;
    selectedElementId.value = null;
    periodOptions.clear();
    employeeOptions.clear();
    _periodOptionsLoaded = false;
    _employeeOptionsLoaded = false;

    final loaded = await loadPayrollOptions();
    if (!loaded) return false;
    if (payrollOptions.isEmpty) {
      await showError('No payroll definitions are available.');
      return false;
    }
    selectedPayrollId.value = payrollOptions.first.id;
    final periodsLoaded = await loadPeriodOptions();
    if (!periodsLoaded) return false;
    if (periodOptions.isEmpty) {
      await showError('The selected payroll has no active periods.');
      return false;
    }
    selectedPeriodId.value = periodOptions.first.id;
    return true;
  }

  Future<void> selectPayroll(String id) async {
    if (selectedPayrollId.value == id) return;
    selectedPayrollId.value = id;
    selectedPeriodId.value = null;
    selectedEmployeeId.value = null;
    periodOptions.clear();
    employeeOptions.clear();
    _periodOptionsLoaded = false;
    _employeeOptionsLoaded = false;
    final loaded = await loadPeriodOptions(forceRefresh: true);
    if (loaded && periodOptions.isNotEmpty) {
      selectedPeriodId.value = periodOptions.first.id;
    }
  }

  Future<bool> createPayrollRun() async {
    if (isCreating.value ||
        !(createFormKey.currentState?.validate() ?? false)) {
      return false;
    }
    final payrollId = selectedPayrollId.value ?? '';
    final periodId = selectedPeriodId.value ?? '';
    if (payrollId.isEmpty || periodId.isEmpty) return false;

    isCreating.value = true;
    try {
      final body = <String, dynamic>{
        'payroll_id': payrollId,
        'period_id': periodId,
      };
      final employeeId = selectedEmployeeId.value ?? '';
      final elementId = selectedElementId.value ?? '';
      if (employeeId.isNotEmpty) body['employee_id'] = employeeId;
      if (elementId.isNotEmpty) body['element_id'] = elementId;

      final response = await _api.postJson(
        '/payroll_runs/payroll_run',
        body: body,
      );
      final rawRun = response['added_run'];
      if (rawRun is! Map) throw const FormatException('Missing added run');
      final details = PayrollRunDetails.fromJson(
        Map<String, dynamic>.from(rawRun),
      );
      allRuns.insert(0, PayrollRunSummary.fromDetails(details));
      applyFilters();
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server returned invalid payroll-run data.');
    } catch (_) {
      await showError('The payroll run could not be created.');
    } finally {
      isCreating.value = false;
    }
    return false;
  }

  Future<bool> openRunDetails(PayrollRunSummary summary) async {
    if (isLoadingDetails.value) return false;
    isLoadingDetails.value = true;
    try {
      final response = await _api.getJson(
        '/payroll_runs/get_payroll_runs_details/${summary.id}',
      );
      final rawDetails = response['payroll_runs_details'];
      if (rawDetails is! Map) {
        throw const FormatException('Missing payroll run details');
      }
      final details = PayrollRunDetails.fromJson(
        Map<String, dynamic>.from(rawDetails),
      );
      selectedDetails.value = details;
      selectedEmployee.value = details.employees.isEmpty
          ? null
          : details.employees.first;
      employeeSearch.clear();
      elementSearch.clear();
      employeeQuery.value = '';
      elementQuery.value = '';
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The payroll run details could not be loaded.');
    } finally {
      isLoadingDetails.value = false;
    }
    return false;
  }

  void clearRunDetails() {
    selectedDetails.value = null;
    selectedEmployee.value = null;
    employeeSearch.clear();
    elementSearch.clear();
    employeeQuery.value = '';
    elementQuery.value = '';
  }

  void selectRunEmployee(PayrollRunEmployee employee) {
    selectedEmployee.value = employee;
    elementSearch.clear();
    elementQuery.value = '';
  }

  void updateEmployeeSearch(String value) => employeeQuery.value = value;
  void updateElementSearch(String value) => elementQuery.value = value;

  Future<void> printPayslip(PayrollRunEmployee employee) async {
    final run = selectedDetails.value;
    if (run == null || printingEmployeeId.value.isNotEmpty) return;
    printingEmployeeId.value = employee.employeeId;
    try {
      await _ensureCompanyDetails();
      final bytes = await _documents.buildPayslip(
        run: run,
        employee: employee,
        company: companyDetails,
      );
      await Printing.layoutPdf(onLayout: (PdfPageFormat _) async => bytes);
    } catch (_) {
      await showError('The payslip could not be generated.');
    } finally {
      printingEmployeeId.value = '';
    }
  }

  Future<void> exportBankPayments() async {
    final currentRun = selectedDetails.value;
    if (currentRun == null || isExporting.value) return;
    final payable = currentRun.employees
        .where((employee) => employee.netSalary > 0)
        .toList();
    if (payable.isEmpty) {
      await showError('No positive net salary is available to export.');
      return;
    }

    isExporting.value = true;
    try {
      final response = await _api.patchJson(
        '/payroll_runs/prepare_bank_export/${currentRun.id}',
      );
      final rawDetails = response['payroll_runs_details'];
      if (rawDetails is! Map) throw const FormatException('Missing details');
      final prepared = PayrollRunDetails.fromJson(
        Map<String, dynamic>.from(rawDetails),
      );
      selectedDetails.value = prepared;
      _syncRunSummary(prepared);
      await _ensureCompanyDetails();
      final payableEmployees = prepared.employees
          .where((employee) => employee.netSalary > 0)
          .toList();
      final csv = _documents.buildBankCsv(
        run: prepared,
        employees: payableEmployees,
        company: companyDetails,
      );
      _documents.downloadBankCsv(csv, prepared);
      final missing = payableEmployees
          .where((employee) => !_documents.hasBankDetails(employee))
          .length;
      await showAppAlertDialog(
        title: 'Bank export created',
        message: missing == 0
            ? 'All payable employees include bank details.'
            : '$missing employee rows are missing bank details.',
        kind: AppAlertKind.success,
      );
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The bank payment file could not be exported.');
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> emailPayslips(List<PayrollRunEmployee> employees) async {
    final run = selectedDetails.value;
    if (run == null || employees.isEmpty || isEmailing.value) return;
    if (employees.any((employee) => employee.employeeId.isEmpty)) {
      await showError('One or more selected employee IDs are missing.');
      return;
    }

    isEmailing.value = true;
    try {
      await _ensureCompanyDetails();
      final files = <String, List<int>>{};
      for (final employee in employees) {
        files['${employee.employeeId}.pdf'] = await _documents.buildPayslip(
          run: run,
          employee: employee,
          company: companyDetails,
        );
      }
      final response = await _api.postMultipartBytes(
        '/payroll_runs/email_payslips/${run.id}',
        fieldName: 'payslips',
        files: files,
      );
      final sent = response['sent'] ?? 0;
      final skipped = response['skipped'] ?? 0;
      final failed = response['failed'] ?? 0;
      final rawResults = response['results'];
      final issues = rawResults is List
          ? rawResults
                .whereType<Map>()
                .where((item) => item['status']?.toString() != 'sent')
                .take(5)
                .map(
                  (item) =>
                      '${item['employee_name'] ?? 'Employee'}: ${item['reason'] ?? item['status']}',
                )
                .join('\n')
          : '';
      await showAppAlertDialog(
        title: 'Payslip email results',
        message:
            'Sent: $sent   Skipped: $skipped   Failed: $failed${issues.isEmpty ? '' : '\n\n$issues'}',
        kind: failed == 0 ? AppAlertKind.success : AppAlertKind.info,
      );
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The payslips could not be emailed.');
    } finally {
      isEmailing.value = false;
    }
  }

  Future<bool> rollbackCurrentRun() async {
    final run = selectedDetails.value;
    if (run == null || isRollingBack.value) return false;
    isRollingBack.value = true;
    try {
      await _api.deleteJson('/payroll_runs/rollback_payroll_run/${run.id}');
      allRuns.removeWhere((item) => item.id == run.id);
      applyFilters();
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The payroll run could not be rolled back.');
    } finally {
      isRollingBack.value = false;
    }
    return false;
  }

  void _syncRunSummary(PayrollRunDetails details) {
    final index = allRuns.indexWhere((run) => run.id == details.id);
    if (index == -1) return;
    allRuns[index] = PayrollRunSummary.fromDetails(details);
    applyFilters();
  }

  Future<void> _ensureCompanyDetails() async {
    if (companyDetails.isNotEmpty) return;
    final response = await _api.getJson(
      '/companies/get_current_company_details',
    );
    final rawCompany = response['company_details'];
    if (rawCompany is! Map) {
      throw const FormatException('Missing company details');
    }
    companyDetails.assignAll(Map<String, dynamic>.from(rawCompany));
  }

  String? requiredSelection(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required.'
        : null;
  }

  Future<void> showError(String message) {
    return showAppAlertDialog(
      title: 'Could not complete the request',
      message: message,
      kind: AppAlertKind.error,
    );
  }

  void nextPage() {
    if (canGoNext) currentPage.value++;
  }

  void previousPage() {
    if (canGoPrevious) currentPage.value--;
  }

  void _openLogin() => Get.offAllNamed(AppRoutes.login);

  @override
  void onClose() {
    runNumberFilter.dispose();
    periodNameFilter.dispose();
    employeeSearch.dispose();
    elementSearch.dispose();
    super.onClose();
  }
}
