import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/payroll/leave_type_model.dart';
import '../../routes/app_routes.dart';
import '../../services/authenticated_api_service.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';

class LeaveTypesController extends GetxController {
  LeaveTypesController({AuthenticatedApiService? api}) : _apiOverride = api;

  static const dayTypes = ['Calendar Days', 'Working Days'];
  static const listTypes = ['All', ...dayTypes];

  final AuthenticatedApiService? _apiOverride;
  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();

  final nameFilter = TextEditingController();
  final codeFilter = TextEditingController();
  final name = TextEditingController();
  final code = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final leaveTypes = <LeaveTypeModel>[].obs;
  final payrollElementOptions = <LeavePayrollElementOption>[].obs;
  final selectedListType = 'All'.obs;
  final selectedFilterBasedElementId = RxnString();
  final selectedBasedElementId = RxnString();
  final selectedDayType = 'Calendar Days'.obs;
  final currentLeaveTypeId = ''.obs;
  final isLoading = false.obs;
  final isLoadingOptions = false.obs;
  final isSaving = false.obs;
  final listError = RxnString();
  final currentPage = 0.obs;
  final pageSize = 1.obs;

  bool _payrollOptionsLoaded = false;
  int? _scheduledPageSize;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await fetchLeaveTypes();
  }

  List<LeaveTypeModel> get visibleLeaveTypes {
    final start = currentPage.value * pageSize.value;
    if (start >= leaveTypes.length) return const [];
    final end = (start + pageSize.value).clamp(0, leaveTypes.length).toInt();
    return leaveTypes.sublist(start, end);
  }

  int get totalPages =>
      leaveTypes.isEmpty ? 1 : (leaveTypes.length / pageSize.value).ceil();

  int get rowStart =>
      leaveTypes.isEmpty ? 0 : currentPage.value * pageSize.value + 1;

  int get rowEnd => ((currentPage.value + 1) * pageSize.value)
      .clamp(0, leaveTypes.length)
      .toInt();

  bool get canGoPrevious => currentPage.value > 0;

  bool get canGoNext => currentPage.value + 1 < totalPages;

  Map<String, dynamic> get payrollElementDropdownItems => {
    for (final option in payrollElementOptions)
      option.id: {'_id': option.id, 'name': option.name},
  };

  String payrollElementName(String? id) {
    if (id == null || id.isEmpty) return '';
    for (final option in payrollElementOptions) {
      if (option.id == id) return option.name;
    }
    return '';
  }

  Future<Map<String, dynamic>> getLeavePayrollElementsForDropdown() async {
    final loaded = await loadPayrollElementOptions(
      showErrors: false,
      forceRefresh: true,
    );
    return loaded ? payrollElementDropdownItems : <String, dynamic>{};
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
      if (leaveTypes.isEmpty) {
        currentPage.value = 0;
        return;
      }
      currentPage.value = (firstVisibleIndex ~/ scheduledRows)
          .clamp(0, totalPages - 1)
          .toInt();
    });
  }

  Future<void> fetchLeaveTypes() async {
    if (isLoading.value) return;
    isLoading.value = true;
    listError.value = null;
    try {
      final body = <String, dynamic>{};
      final filterName = nameFilter.text.trim();
      final filterCode = codeFilter.text.trim();
      if (filterName.isNotEmpty) body['name'] = filterName;
      if (filterCode.isNotEmpty) body['code'] = filterCode;
      if (selectedListType.value != 'All') {
        body['type'] = selectedListType.value;
      }
      final basedElementId = selectedFilterBasedElementId.value;
      if (basedElementId != null && basedElementId.isNotEmpty) {
        body['based_element'] = basedElementId;
      }

      final response = await _api.postJson(
        '/leave_types/search_engine_for_leave_types',
        body: body,
      );
      final rawLeaveTypes = response['leave_types'];
      if (rawLeaveTypes is! List) {
        throw const FormatException('Missing leave types');
      }
      leaveTypes.assignAll(
        rawLeaveTypes.whereType<Map>().map(
          (item) => LeaveTypeModel.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
      currentPage.value = 0;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      listError.value = error.message;
    } on FormatException {
      listError.value = 'The server returned invalid leave-type data.';
    } catch (_) {
      listError.value = 'Leave types could not be loaded.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> loadPayrollElementOptions({
    bool showErrors = true,
    bool forceRefresh = false,
  }) async {
    if (_payrollOptionsLoaded && !forceRefresh) return true;
    while (!isClosed && isLoadingOptions.value) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    if (_payrollOptionsLoaded && !forceRefresh) return true;
    if (isClosed) return false;
    isLoadingOptions.value = true;
    try {
      final response = await _api.getJson(
        '/leave_types/get_leave_payroll_elements_for_lov',
      );
      final rawOptions = response['elements'];
      if (rawOptions is! List) throw const FormatException('Missing options');
      payrollElementOptions.assignAll(
        rawOptions
            .whereType<Map>()
            .map(
              (item) => LeavePayrollElementOption.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((option) => option.id.isNotEmpty),
      );
      _payrollOptionsLoaded = true;
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      if (showErrors) await showError(error.message);
    } on FormatException {
      if (showErrors) {
        await showError('The server returned invalid based-element options.');
      }
    } catch (_) {
      if (showErrors) {
        await showError('Based-element options could not be loaded.');
      }
    } finally {
      isLoadingOptions.value = false;
    }
    return false;
  }

  Future<bool> prepareNewLeaveType() async {
    final loaded = await loadPayrollElementOptions();
    if (!loaded) return false;
    if (payrollElementOptions.isEmpty) {
      await showError(
        'No indirect payroll elements are available for a leave type.',
      );
      return false;
    }
    currentLeaveTypeId.value = '';
    name.clear();
    code.clear();
    selectedBasedElementId.value = payrollElementOptions.first.id;
    selectedDayType.value = 'Calendar Days';
    return true;
  }

  Future<bool> prepareExistingLeaveType(LeaveTypeModel leaveType) async {
    final loaded = await loadPayrollElementOptions();
    if (!loaded) return false;
    if (leaveType.basedElementId.isNotEmpty &&
        !payrollElementOptions.any(
          (option) => option.id == leaveType.basedElementId,
        )) {
      payrollElementOptions.add(
        LeavePayrollElementOption(
          id: leaveType.basedElementId,
          name: leaveType.basedElementName,
        ),
      );
    }
    currentLeaveTypeId.value = leaveType.id;
    name.text = leaveType.name;
    code.text = leaveType.code;
    selectedBasedElementId.value = leaveType.basedElementId.isEmpty
        ? null
        : leaveType.basedElementId;
    selectedDayType.value = dayTypes.contains(leaveType.type)
        ? leaveType.type
        : 'Calendar Days';
    return true;
  }

  Future<bool> saveLeaveType() async {
    if (isSaving.value || !(formKey.currentState?.validate() ?? false)) {
      return false;
    }
    final basedElementId = selectedBasedElementId.value;
    if (basedElementId == null || basedElementId.isEmpty) return false;

    isSaving.value = true;
    try {
      final payload = LeaveTypeModel(
        id: currentLeaveTypeId.value,
        name: name.text.trim(),
        code: code.text.trim(),
        type: selectedDayType.value,
        basedElementName: '',
        basedElementId: basedElementId,
      ).toRequestJson();
      if (currentLeaveTypeId.value.isEmpty) {
        await _api.postJson('/leave_types/add_new_leave_type', body: payload);
      } else {
        await _api.patchJson(
          '/leave_types/update_leave_type/${currentLeaveTypeId.value}',
          body: payload,
        );
      }
      await fetchLeaveTypes();
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The leave type could not be saved.');
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  Future<bool> deleteLeaveType(String id) async {
    try {
      await _api.deleteJson('/leave_types/delete_leave_type/$id');
      await fetchLeaveTypes();
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The leave type could not be deleted.');
    }
    return false;
  }

  Future<void> selectListType(String type) async {
    if (selectedListType.value == type) return;
    selectedListType.value = type;
    await fetchLeaveTypes();
  }

  Future<void> clearFilters() async {
    nameFilter.clear();
    codeFilter.clear();
    selectedFilterBasedElementId.value = null;
    selectedListType.value = 'All';
    await fetchLeaveTypes();
  }

  void nextPage() {
    if (canGoNext) currentPage.value++;
  }

  void previousPage() {
    if (canGoPrevious) currentPage.value--;
  }

  String? requiredText(String? value) {
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

  void _openLogin() {
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    nameFilter.dispose();
    codeFilter.dispose();
    name.dispose();
    code.dispose();
    super.onClose();
  }
}
