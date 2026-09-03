import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/employees/employee_model.dart';
import '../../services/authenticated_api_service.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';

class EmployeesController extends GetxController {
  EmployeesController({AuthenticatedApiService? api}) : _apiOverride = api;

  final AuthenticatedApiService? _apiOverride;
  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();

  final employees = <EmployeeSummary>[].obs;
  final selectedEmployee = Rxn<EmployeeDetails>();
  final leaves = <EmployeeRecord>[].obs;
  final contacts = <EmployeeRecord>[].obs;
  final payrollElements = <EmployeeRecord>[].obs;
  final assignmentBalances = <EmployeeRecord>[].obs;
  final attachments = <EmployeeAttachment>[].obs;
  final isLoading = false.obs;
  final isLoadingDetails = false.obs;
  final isSaving = false.obs;
  final isDeleting = ''.obs;
  final isUtilityLoading = false.obs;
  final isLoadingPeriod = false.obs;
  final isLoadingAttachments = false.obs;
  final isSavingAttachment = false.obs;
  final selectedType = 'ALL'.obs;
  final selectedContactTab = EmployeeRecordKind.address.obs;
  final selectedAssignmentTab = EmployeeRecordKind.address.obs;
  final selectedPeriod = ''.obs;

  final employeeNameFilter = TextEditingController();
  final employerFilter = TextEditingController();
  final departmentFilter = TextEditingController();
  final jobTitleFilter = TextEditingController();
  final locationFilter = TextEditingController();
  final employerFilterId = ''.obs;
  final departmentFilterId = ''.obs;
  final jobTitleFilterId = ''.obs;
  final locationFilterId = ''.obs;

  final fullName = TextEditingController();
  final countryOfBirth = TextEditingController();
  final placeOfBirth = TextEditingController();
  final dateOfBirth = TextEditingController();
  final gender = TextEditingController();
  final maritalStatus = TextEditingController();
  final legislation = TextEditingController();
  final employer = TextEditingController();
  final department = TextEditingController();
  final jobTitle = TextEditingController();
  final location = TextEditingController();
  final reportingManager = TextEditingController();
  final payroll = TextEditingController();
  final hireDate = TextEditingController();
  final endDate = TextEditingController();

  final countryOfBirthId = ''.obs;
  final genderId = ''.obs;
  final maritalStatusId = ''.obs;
  final legislationId = ''.obs;
  final employerId = ''.obs;
  final departmentId = ''.obs;
  final jobTitleId = ''.obs;
  final locationId = ''.obs;
  final reportingManagerId = ''.obs;
  final payrollId = ''.obs;
  final imageBytes = Rxn<List<int>>();
  final imageName = ''.obs;

  final Map<String, Map<String, dynamic>> _lookupCache = {};

  String get currentEmployeeId => selectedEmployee.value?.id ?? '';
  bool get isEditing => currentEmployeeId.isNotEmpty;
  String get computedPersonType => deriveEmployeeType(
    hireDate: parseDateInput(hireDate.text),
    endDate: parseDateInput(endDate.text),
  );

  @override
  void onInit() {
    super.onInit();
    selectedPeriod.value = _periodText(DateTime.now());
    unawaited(loadEmployees());
  }

  @override
  void onClose() {
    for (final controller in [
      employeeNameFilter,
      employerFilter,
      departmentFilter,
      jobTitleFilter,
      locationFilter,
      fullName,
      countryOfBirth,
      placeOfBirth,
      dateOfBirth,
      gender,
      maritalStatus,
      legislation,
      employer,
      department,
      jobTitle,
      location,
      reportingManager,
      payroll,
      hireDate,
      endDate,
    ]) {
      controller.dispose();
    }
    super.onClose();
  }

  Future<void> loadEmployees({bool filtered = false}) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final response = filtered || _hasFilters
          ? await _api.postJson(
              '/employees/search_engine_for_employees',
              body: _filterBody,
            )
          : await _api.getJson('/employees/get_all_employees');
      employees.assignAll(_summaryList(response['employees']));
    } on SessionExpiredException {
      Get.offAllNamed('/loginScreen');
    } on ApiRequestException catch (error) {
      await _showError('Could not load employees', error.message);
    } catch (_) {
      await _showError(
        'Could not load employees',
        'The server returned invalid employee data.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> loadEmployee(String id) async {
    if (id.isEmpty || isLoadingDetails.value) return false;
    isLoadingDetails.value = true;
    try {
      final response = await _api.getJson(
        '/employees/get_employee_details_dor_editing/$id',
      );
      final raw = response['details'];
      if (raw is! Map) throw const FormatException();
      final details = EmployeeDetails.fromJson(Map<String, dynamic>.from(raw));
      selectedEmployee.value = details;
      payrollElements.assignAll(details.payrollElements);
      assignmentBalances.assignAll(details.assignmentBalances);
      _populateEditor(details);
      await setPeriod(selectedPeriod.value);
      return true;
    } on ApiRequestException catch (error) {
      await _showError('Could not open employee', error.message);
    } catch (_) {
      await _showError(
        'Could not open employee',
        'The server returned invalid employee details.',
      );
    } finally {
      isLoadingDetails.value = false;
    }
    return false;
  }

  void beginNewEmployee() {
    selectedEmployee.value = null;
    payrollElements.clear();
    assignmentBalances.clear();
    attachments.clear();
    leaves.clear();
    contacts.clear();
    _clearEditor();
  }

  Future<bool> saveEmployee(GlobalKey<FormState> formKey) async {
    if (isSaving.value || formKey.currentState?.validate() != true) {
      return false;
    }
    if (legislationId.value.isEmpty || payrollId.value.isEmpty) {
      await _showError(
        'Complete required fields',
        'Please select both Legislation and Payroll.',
      );
      return false;
    }
    isSaving.value = true;
    try {
      final path = isEditing
          ? '/employees/update_employee/$currentEmployeeId'
          : '/employees/create_employee';
      final response = await _api.multipartJson(
        isEditing ? 'PATCH' : 'POST',
        path,
        fields: _employeeFields,
        fileField: 'person_image',
        fileBytes: imageBytes.value,
        fileName: imageName.value.isEmpty ? 'employee.png' : imageName.value,
      );
      final raw = response['employee'];
      if (raw is Map) {
        final details = EmployeeDetails.fromJson(
          Map<String, dynamic>.from(raw),
        );
        selectedEmployee.value = details;
        payrollElements.assignAll(details.payrollElements);
        assignmentBalances.assignAll(details.assignmentBalances);
        _populateEditor(details);
      } else {
        final id = employeeString(response['employee_id']);
        if (id.isNotEmpty) await loadEmployee(id);
      }
      await loadEmployees(filtered: _hasFilters);
      imageBytes.value = null;
      imageName.value = '';
      return true;
    } on ApiRequestException catch (error) {
      await _showError('Could not save employee', error.message);
    } catch (_) {
      await _showError(
        'Could not save employee',
        'The employee could not be saved. Please try again.',
      );
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  Future<bool> deleteEmployee(String id) async {
    if (id.isEmpty || isDeleting.value.isNotEmpty) return false;
    isDeleting.value = id;
    try {
      await _api.deleteJson('/employees/delete_employee/$id');
      employees.removeWhere((employee) => employee.id == id);
      return true;
    } on ApiRequestException catch (error) {
      await _showError('Could not delete employee', error.message);
    } finally {
      isDeleting.value = '';
    }
    return false;
  }

  Future<void> pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    imageBytes.value = file!.bytes;
    imageName.value = file.name;
  }

  Future<void> setPeriod(String period) async {
    selectedPeriod.value = period;
    if (!isEditing || isLoadingPeriod.value) return;
    isLoadingPeriod.value = true;
    try {
      await Future.wait([
        filterEmployeePayrollElementsByPeriod(period),
        getEmployeeBalances(period),
      ]);
    } finally {
      isLoadingPeriod.value = false;
    }
  }

  Future<void> filterEmployeePayrollElementsByPeriod(String period) async {
    if (!isEditing) return;
    try {
      final response = await _api.postJson(
        '/employees/filter_employee_payrolls_on_period_date/$currentEmployeeId',
        body: {'period': period},
      );
      payrollElements.assignAll(
        EmployeeRecord.list(response['payrolls_elements']),
      );
    } on SessionExpiredException {
      Get.offAllNamed('/loginScreen');
    } on ApiRequestException catch (error) {
      await _showError('Could not load payroll elements', error.message);
    }
  }

  Future<void> getEmployeeBalances(String period) async {
    if (!isEditing) return;
    try {
      final response = await _api.postJson(
        '/employees/get_assignment_balances_depending_on_period/$currentEmployeeId',
        body: {'period_date': period},
      );
      assignmentBalances.assignAll(EmployeeRecord.list(response['balances']));
    } on SessionExpiredException {
      Get.offAllNamed('/loginScreen');
    } on ApiRequestException catch (error) {
      await _showError('Could not load assignment balances', error.message);
    }
  }

  List<String> get availablePeriods {
    final now = DateTime.now();
    final start = parseDateInput(hireDate.text) ?? now;
    final first = DateTime(start.year, start.month);
    final last = DateTime(now.year, now.month);
    final result = <String>[];
    var cursor = last;
    while (!cursor.isBefore(first) && result.length < 240) {
      result.add(_periodText(cursor));
      cursor = DateTime(cursor.year, cursor.month - 1);
    }
    return result.isEmpty ? [_periodText(now)] : result;
  }

  List<EmployeeRecord> recordsFor(EmployeeRecordKind kind) {
    if (kind == EmployeeRecordKind.payrollElement) {
      return payrollElements.toList(growable: false);
    }
    if (kind == EmployeeRecordKind.leave) {
      return leaves.toList(growable: false);
    }
    if (kind == EmployeeRecordKind.contactRelative) {
      return contacts.toList(growable: false);
    }
    return List<EmployeeRecord>.of(
      selectedEmployee.value?.recordsFor(kind) ?? const [],
      growable: false,
    );
  }

  Future<bool> saveRecord(
    EmployeeRecordKind kind,
    Map<String, dynamic> body, {
    String recordId = '',
  }) async {
    if (!isEditing || isSaving.value) return false;
    isSaving.value = true;
    try {
      final endpoint = _endpointFor(kind, recordId: recordId);
      if (recordId.isEmpty) {
        await _api.postJson(endpoint, body: body);
      } else {
        await _api.patchJson(endpoint, body: body);
      }
      if (kind == EmployeeRecordKind.leave) {
        await loadLeaves();
      } else if (kind == EmployeeRecordKind.contactRelative) {
        await loadContacts();
      } else {
        await loadEmployee(currentEmployeeId);
        if (kind == EmployeeRecordKind.payrollElement) {
          await setPeriod(selectedPeriod.value);
        }
      }
      return true;
    } on ApiRequestException catch (error) {
      await _showError('Could not save record', error.message);
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  Future<bool> deleteRecord(
    EmployeeRecordKind kind,
    EmployeeRecord record,
  ) async {
    if (record.id.isEmpty || isDeleting.value.isNotEmpty) return false;
    isDeleting.value = record.id;
    try {
      await _api.deleteJson(_deleteEndpointFor(kind, record.id));
      if (kind == EmployeeRecordKind.leave) {
        leaves.removeWhere((item) => item.id == record.id);
      } else if (kind == EmployeeRecordKind.contactRelative) {
        contacts.removeWhere((item) => item.id == record.id);
      } else {
        await loadEmployee(currentEmployeeId);
      }
      return true;
    } on ApiRequestException catch (error) {
      await _showError('Could not delete record', error.message);
    } finally {
      isDeleting.value = '';
    }
    return false;
  }

  Future<void> loadLeaves() async {
    if (!isEditing) return;
    isUtilityLoading.value = true;
    try {
      final response = await _api.getJson(
        '/employees/get_all_employee_leaves/$currentEmployeeId',
      );
      leaves.assignAll(EmployeeRecord.list(response['all_leaves']));
    } on ApiRequestException catch (error) {
      await _showError('Could not load leaves', error.message);
    } finally {
      isUtilityLoading.value = false;
    }
  }

  Future<void> loadContacts() async {
    if (!isEditing) return;
    isUtilityLoading.value = true;
    try {
      final response = await _api.getJson(
        '/employees/get_employee_contact_and_relative/$currentEmployeeId',
      );
      contacts.assignAll(EmployeeRecord.list(response['contact']));
    } on ApiRequestException catch (error) {
      await _showError('Could not load contacts', error.message);
    } finally {
      isUtilityLoading.value = false;
    }
  }

  Future<void> loadAttachments() async {
    if (!isEditing || isLoadingAttachments.value) return;
    isLoadingAttachments.value = true;
    try {
      final response = await _api.postJson(
        '/attachment/get_all_attachment',
        body: {
          'code': 'EMPLOYEES_ATTACHMENT',
          'document_id': currentEmployeeId,
        },
      );
      attachments.assignAll(EmployeeAttachment.list(response['results']));
    } on ApiRequestException catch (error) {
      await _showError('Could not load attachments', error.message);
    } finally {
      isLoadingAttachments.value = false;
    }
  }

  Future<Map<String, List<int>>> pickAttachmentFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return const {};
    return {
      for (final file in result.files)
        if (file.bytes != null && file.bytes!.isNotEmpty)
          file.name: file.bytes!,
    };
  }

  Future<bool> addAttachment({
    required String name,
    required String typeId,
    required String number,
    required String startDate,
    required String endDate,
    required String note,
    required Map<String, List<int>> files,
  }) async {
    if (!isEditing || isSavingAttachment.value) return false;
    isSavingAttachment.value = true;
    try {
      final response = await _api.multipartJson(
        'POST',
        '/attachment/add_new_attachment',
        fields: {
          'code': 'EMPLOYEES_ATTACHMENT',
          'document_id': currentEmployeeId,
          'name': name.trim(),
          'attachment_type': typeId,
          'number': number.trim(),
          'start_date': _isoDate(startDate),
          'end_date': _isoDate(endDate),
          'note': note.trim(),
        },
        fileField: 'attachments',
        files: files,
      );
      final raw = response['result'];
      if (raw is Map) {
        attachments.add(
          EmployeeAttachment.fromJson(Map<String, dynamic>.from(raw)),
        );
      } else {
        await loadAttachments();
      }
      return true;
    } on ApiRequestException catch (error) {
      await _showError('Could not save attachment', error.message);
    } finally {
      isSavingAttachment.value = false;
    }
    return false;
  }

  Future<bool> deleteAttachment(EmployeeAttachment attachment) async {
    if (attachment.id.isEmpty || isDeleting.value.isNotEmpty) return false;
    isDeleting.value = attachment.id;
    try {
      await _api.deleteJson('/attachment/delete_attachment/${attachment.id}');
      attachments.removeWhere((item) => item.id == attachment.id);
      return true;
    } on ApiRequestException catch (error) {
      await _showError('Could not delete attachment', error.message);
    } finally {
      isDeleting.value = '';
    }
    return false;
  }

  Future<Map<String, dynamic>> listValues(
    String code, {
    bool refresh = false,
  }) => _loadLookup(
    'list:$code',
    '/list_of_values/get_list_values_by_code?code=${Uri.encodeQueryComponent(code)}',
    'values',
    refresh: refresh,
  );

  Future<bool> addListValue(String code, String name) async {
    final valueName = name.trim();
    if (valueName.isEmpty) return false;
    try {
      final listId = await _listIdForCode(code);
      final response = await _api.postJson(
        '/list_of_values/add_new_value/$listId',
        body: {'name': valueName, 'mastered_by_id': ''},
      );
      if (response['list'] is! Map) {
        throw ApiRequestException(
          employeeString(response['message']).isEmpty
              ? 'The server did not return the new value.'
              : employeeString(response['message']),
        );
      }
      _lookupCache.remove('list:$code');
      return true;
    } on SessionExpiredException {
      Get.offAllNamed('/loginScreen');
    } on ApiRequestException catch (error) {
      await _showError('Could not add value', error.message);
    } catch (_) {
      await _showError(
        'Could not add value',
        'The new list value could not be saved.',
      );
    }
    return false;
  }

  Future<bool> updateListValue(String code, String valueId, String name) async {
    final valueName = name.trim();
    if (valueId.isEmpty || valueName.isEmpty) return false;
    try {
      final response = await _api.patchJson(
        '/list_of_values/update_value/$valueId',
        body: {'name': valueName, 'mastered_by_id': ''},
      );
      if (response['value'] is! Map) {
        throw ApiRequestException(
          employeeString(response['message']).isEmpty
              ? 'The server did not return the updated value.'
              : employeeString(response['message']),
        );
      }
      _lookupCache.remove('list:$code');
      return true;
    } on SessionExpiredException {
      Get.offAllNamed('/loginScreen');
    } on ApiRequestException catch (error) {
      await _showError('Could not update value', error.message);
    } catch (_) {
      await _showError(
        'Could not update value',
        'The list value could not be updated.',
      );
    }
    return false;
  }

  Future<bool> deleteListValue(String code, String valueId) async {
    if (valueId.isEmpty) return false;
    try {
      final response = await _api.deleteJson(
        '/list_of_values/delete_value/$valueId',
      );
      final message = employeeString(response['message']);
      if (!message.toLowerCase().contains('success')) {
        throw ApiRequestException(
          message.isEmpty
              ? 'The server did not confirm the deletion.'
              : message,
        );
      }
      _lookupCache.remove('list:$code');
      return true;
    } on SessionExpiredException {
      Get.offAllNamed('/loginScreen');
    } on ApiRequestException catch (error) {
      await _showError('Could not delete value', error.message);
    } catch (_) {
      await _showError(
        'Could not delete value',
        'The list value could not be deleted.',
      );
    }
    return false;
  }

  Future<Map<String, dynamic>> countries() =>
      _loadLookup('countries', '/countries/get_countries', 'countries');

  Future<Map<String, dynamic>> cities(String countryId) => _loadLookup(
    'cities:$countryId',
    '/countries/get_cities/$countryId',
    'cities',
    refresh: true,
  );

  Future<Map<String, dynamic>> legislations() => _loadLookup(
    'legislations',
    '/legislation/get_all_legislations',
    'all_legislations',
  );

  Future<Map<String, dynamic>> payrolls() => _loadLookup(
    'payrolls',
    '/payroll_runs/get_payroll_for_lov',
    'all_payrolls',
  );

  Future<Map<String, dynamic>> payrollElementOptions() => _loadLookup(
    'payroll-elements',
    '/payroll_elements/get_payroll_elements_for_lov',
    'elements',
  );

  Future<Map<String, dynamic>> loanAdvanceTypes() => _loadLookup(
    'loan-types',
    '/loan_and_advances_types/get_all_loan_and_advances_types_for_lov',
    'loan_and_advances_types',
  );

  Future<Map<String, dynamic>> leaveTypes() => _loadLookup(
    'leave-types',
    '/leave_types/get_all_leave_types_for_lov',
    'leave_types',
  );

  Future<Map<String, dynamic>> attachmentTypes() =>
      listValues('ATTACHMENT_TYPES');

  Future<Map<String, dynamic>> healthCardHolders() => _loadLookup(
    'health-holders:$currentEmployeeId',
    '/employees/get_health_card_holders/$currentEmployeeId',
    'holders',
    refresh: true,
  );

  void clearFilters() {
    employeeNameFilter.clear();
    employerFilter.clear();
    departmentFilter.clear();
    jobTitleFilter.clear();
    locationFilter.clear();
    employerFilterId.value = '';
    departmentFilterId.value = '';
    jobTitleFilterId.value = '';
    locationFilterId.value = '';
    selectedType.value = 'ALL';
    unawaited(loadEmployees());
  }

  void setType(String value) {
    selectedType.value = value;
    unawaited(loadEmployees(filtered: true));
  }

  String? requiredText(String? value) =>
      value?.trim().isEmpty ?? true ? 'This field is required.' : null;

  Map<String, dynamic> get _filterBody => {
    if (employeeNameFilter.text.trim().isNotEmpty)
      'name': employeeNameFilter.text.trim(),
    if (employerFilterId.value.isNotEmpty) 'employer': employerFilterId.value,
    if (departmentFilterId.value.isNotEmpty)
      'department': departmentFilterId.value,
    if (jobTitleFilterId.value.isNotEmpty) 'job_title': jobTitleFilterId.value,
    if (locationFilterId.value.isNotEmpty) 'location': locationFilterId.value,
    if (selectedType.value != 'ALL') 'type': selectedType.value,
  };

  bool get _hasFilters => _filterBody.isNotEmpty;

  Map<String, String> get _employeeFields => {
    'full_name': fullName.text.trim(),
    'country_of_birth': countryOfBirthId.value,
    'place_of_birth': placeOfBirth.text.trim(),
    'date_of_birth': _isoDate(dateOfBirth.text),
    'gender': genderId.value,
    'martial_status': maritalStatusId.value,
    'person_type': computedPersonType,
    'legislation': legislationId.value,
    'employer': employerId.value,
    'department': departmentId.value,
    'job_title': jobTitleId.value,
    'location': locationId.value,
    'reporting_manager': reportingManagerId.value,
    'payroll': payrollId.value,
    'hire_date': _isoDate(hireDate.text),
    'end_date': _isoDate(endDate.text),
  };

  Future<Map<String, dynamic>> _loadLookup(
    String cacheKey,
    String path,
    String listKey, {
    bool refresh = false,
  }) async {
    if (!refresh && _lookupCache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_lookupCache[cacheKey]!);
    }
    try {
      final response = await _api.getJson(path);
      final raw = response[listKey];
      if (raw is! List) return {};
      final result = <String, dynamic>{};
      for (final entry in raw.whereType<Map>()) {
        final item = Map<String, dynamic>.from(entry);
        final id = employeeString(item['_id']);
        if (id.isNotEmpty) result[id] = item;
      }
      _lookupCache[cacheKey] = Map<String, dynamic>.from(result);
      return Map<String, dynamic>.from(result);
    } catch (_) {
      return {};
    }
  }

  Future<String> _listIdForCode(String code) async {
    final response = await _api.getJson(
      '/list_of_values/get_list_details_by_code?code=${Uri.encodeQueryComponent(code)}',
    );
    final details = response['list_details'];
    if (details is! Map) {
      throw const ApiRequestException('The list details are unavailable.');
    }
    final id = employeeString(details['_id']);
    if (id.isEmpty) {
      throw const ApiRequestException('The list identifier is missing.');
    }
    return id;
  }

  void _populateEditor(EmployeeDetails employee) {
    fullName.text = employee.fullName;
    countryOfBirth.text = employee.countryOfBirthName;
    countryOfBirthId.value = employee.countryOfBirthId;
    placeOfBirth.text = employee.placeOfBirth;
    dateOfBirth.text = formatDate(employee.dateOfBirth);
    gender.text = employee.genderName;
    genderId.value = employee.genderId;
    maritalStatus.text = employee.maritalStatusName;
    maritalStatusId.value = employee.maritalStatusId;
    legislation.text = employee.legislationName;
    legislationId.value = employee.legislationId;
    employer.text = employee.employerName;
    employerId.value = employee.employerId;
    department.text = employee.departmentName;
    departmentId.value = employee.departmentId;
    jobTitle.text = employee.jobTitleName;
    jobTitleId.value = employee.jobTitleId;
    location.text = employee.locationName;
    locationId.value = employee.locationId;
    reportingManager.text = employee.reportingManagerName;
    reportingManagerId.value = employee.reportingManagerId;
    payroll.text = employee.payrollName;
    payrollId.value = employee.payrollId;
    hireDate.text = formatDate(employee.hireDate);
    endDate.text = formatDate(employee.endDate);
    selectedPeriod.value = _periodText(DateTime.now());
    selectedContactTab.value = EmployeeRecordKind.address;
    selectedAssignmentTab.value = EmployeeRecordKind.address;
    imageBytes.value = null;
    imageName.value = '';
  }

  void _clearEditor() {
    for (final controller in [
      fullName,
      countryOfBirth,
      placeOfBirth,
      dateOfBirth,
      gender,
      maritalStatus,
      legislation,
      employer,
      department,
      jobTitle,
      location,
      reportingManager,
      payroll,
      hireDate,
      endDate,
    ]) {
      controller.clear();
    }
    for (final value in [
      countryOfBirthId,
      genderId,
      maritalStatusId,
      legislationId,
      employerId,
      departmentId,
      jobTitleId,
      locationId,
      reportingManagerId,
      payrollId,
    ]) {
      value.value = '';
    }
    selectedPeriod.value = _periodText(DateTime.now());
    selectedContactTab.value = EmployeeRecordKind.address;
    selectedAssignmentTab.value = EmployeeRecordKind.address;
    imageBytes.value = null;
    imageName.value = '';
  }

  String _endpointFor(EmployeeRecordKind kind, {required String recordId}) {
    final creating = recordId.isEmpty;
    return switch (kind) {
      EmployeeRecordKind.address =>
        creating
            ? '/employees/add_employee_address/$currentEmployeeId'
            : '/employees/update_employee_address/$recordId',
      EmployeeRecordKind.nationality =>
        creating
            ? '/employees/add_employee_nationality/$currentEmployeeId'
            : '/employees/edit_employee_nationality/$recordId',
      EmployeeRecordKind.phone =>
        creating
            ? '/employees/add_employee_phone/$currentEmployeeId'
            : '/employees/edit_employee_phone/$recordId',
      EmployeeRecordKind.socialContact =>
        creating
            ? '/employees/add_employee_email/$currentEmployeeId'
            : '/employees/edit_employee_email/$recordId',
      EmployeeRecordKind.bankAccount =>
        creating
            ? '/employees/add_employee_bank_account/$currentEmployeeId'
            : '/employees/edit_employee_bank_account/$recordId',
      EmployeeRecordKind.healthCard =>
        creating
            ? '/employees/add_employee_health_card/$currentEmployeeId'
            : '/employees/edit_employee_health_card/$recordId',
      EmployeeRecordKind.payrollElement =>
        creating
            ? '/employees/add_new_employee_payroll/$currentEmployeeId'
            : '/employees/update_employee_payroll/$recordId',
      EmployeeRecordKind.loanAdvance =>
        creating
            ? '/employees/add_new_employee_loan_and_advances/$currentEmployeeId'
            : '/employees/update_employee_loan_and_advances/$recordId',
      EmployeeRecordKind.leave =>
        creating
            ? '/employees/add_new_employee_leave/$currentEmployeeId'
            : '/employees/update_employee_leave/$recordId',
      EmployeeRecordKind.contactRelative =>
        creating
            ? '/employees/add_new_employee_contact_and_relative/$currentEmployeeId'
            : '/employees/update_employee_contact_and_relative/$recordId',
    };
  }

  String _deleteEndpointFor(EmployeeRecordKind kind, String id) =>
      switch (kind) {
        EmployeeRecordKind.address => '/employees/delete_employee_address/$id',
        EmployeeRecordKind.nationality =>
          '/employees/delete_employee_nationality/$id',
        EmployeeRecordKind.phone => '/employees/delete_employee_phone/$id',
        EmployeeRecordKind.socialContact =>
          '/employees/delete_employee_email/$id',
        EmployeeRecordKind.bankAccount =>
          '/employees/delete_employee_bank_account/$id',
        EmployeeRecordKind.healthCard =>
          '/employees/delete_employee_health_card/$id',
        EmployeeRecordKind.payrollElement =>
          '/employees/delete_employee_payroll/$id',
        EmployeeRecordKind.loanAdvance =>
          '/employees/delete_employee_loan_and_advances/$id',
        EmployeeRecordKind.leave => '/employees/delete_employee_leave/$id',
        EmployeeRecordKind.contactRelative =>
          '/employees/delete_employee_contact_and_relative/$id',
      };

  List<EmployeeSummary> _summaryList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (entry) => EmployeeSummary.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList(growable: false);
  }

  Future<void> _showError(String title, String message) => showAppAlertDialog(
    title: title,
    message: message,
    kind: AppAlertKind.error,
  );

  static String formatDate(DateTime? value) {
    if (value == null) return '';
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static DateTime? parseDateInput(String value) =>
      DateTime.tryParse(value.trim());

  static String _isoDate(String value) {
    final date = parseDateInput(value);
    return date?.toIso8601String() ?? '';
  }

  static String _periodText(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}';
}
