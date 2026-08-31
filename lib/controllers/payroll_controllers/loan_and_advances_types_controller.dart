import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/payroll/loan_advance_type_model.dart';
import '../../routes/app_routes.dart';
import '../../services/authenticated_api_service.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';

class LoanAndAdvancesTypesController extends GetxController {
  LoanAndAdvancesTypesController({AuthenticatedApiService? api})
    : _apiOverride = api;

  final AuthenticatedApiService? _apiOverride;
  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();

  final nameFilter = TextEditingController();
  final codeFilter = TextEditingController();
  final name = TextEditingController();
  final code = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final loanAdvanceTypes = <LoanAdvanceTypeModel>[].obs;
  final payrollElementOptions = <LoanAdvancePayrollElementOption>[].obs;
  final selectedFilterBasedElementId = RxnString();
  final selectedBasedElementId = RxnString();
  final currentTypeId = ''.obs;
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
    unawaited(fetchLoanAdvanceTypes());
  }

  List<LoanAdvanceTypeModel> get visibleTypes {
    final start = currentPage.value * pageSize.value;
    if (start >= loanAdvanceTypes.length) return const [];
    final end = (start + pageSize.value)
        .clamp(0, loanAdvanceTypes.length)
        .toInt();
    return loanAdvanceTypes.sublist(start, end);
  }

  int get totalPages => loanAdvanceTypes.isEmpty
      ? 1
      : (loanAdvanceTypes.length / pageSize.value).ceil();

  int get rowStart =>
      loanAdvanceTypes.isEmpty ? 0 : currentPage.value * pageSize.value + 1;

  int get rowEnd => ((currentPage.value + 1) * pageSize.value)
      .clamp(0, loanAdvanceTypes.length)
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

  Future<Map<String, dynamic>> getPayrollElementsForDropdown() async {
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
      if (loanAdvanceTypes.isEmpty) {
        currentPage.value = 0;
        return;
      }
      currentPage.value = (firstVisibleIndex ~/ scheduledRows)
          .clamp(0, totalPages - 1)
          .toInt();
    });
  }

  Future<void> fetchLoanAdvanceTypes() async {
    if (isLoading.value) return;
    isLoading.value = true;
    listError.value = null;
    try {
      final body = <String, dynamic>{};
      final filterName = nameFilter.text.trim();
      final filterCode = codeFilter.text.trim();
      if (filterName.isNotEmpty) body['name'] = filterName;
      if (filterCode.isNotEmpty) body['code'] = filterCode;
      final basedElementId = selectedFilterBasedElementId.value;
      if (basedElementId != null && basedElementId.isNotEmpty) {
        body['based_element'] = basedElementId;
      }

      final response = await _api.postJson(
        '/loan_and_advances_types/search_engine_for_loan_and_advances_types',
        body: body,
      );
      final rawTypes = response['loan_and_advances_types'];
      if (rawTypes is! List) {
        throw const FormatException('Missing loan and advance types');
      }
      loanAdvanceTypes.assignAll(
        rawTypes.whereType<Map>().map(
          (item) =>
              LoanAdvanceTypeModel.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
      currentPage.value = 0;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      listError.value = error.message;
    } on FormatException {
      listError.value = 'The server returned invalid loan-type data.';
    } catch (_) {
      listError.value = 'Loan and advance types could not be loaded.';
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
        '/payroll_elements/get_payroll_elements_for_lov',
      );
      final rawOptions = response['elements'];
      if (rawOptions is! List) throw const FormatException('Missing options');
      payrollElementOptions.assignAll(
        rawOptions
            .whereType<Map>()
            .map(
              (item) => LoanAdvancePayrollElementOption.fromJson(
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

  Future<bool> prepareNewType() async {
    final loaded = await loadPayrollElementOptions();
    if (!loaded) return false;
    if (payrollElementOptions.isEmpty) {
      await showError('No payroll elements are available for this type.');
      return false;
    }
    currentTypeId.value = '';
    name.clear();
    code.clear();
    selectedBasedElementId.value = payrollElementOptions.first.id;
    return true;
  }

  Future<bool> prepareExistingType(LoanAdvanceTypeModel type) async {
    final loaded = await loadPayrollElementOptions();
    if (!loaded) return false;
    if (type.basedElementId.isNotEmpty &&
        !payrollElementOptions.any(
          (option) => option.id == type.basedElementId,
        )) {
      payrollElementOptions.add(
        LoanAdvancePayrollElementOption(
          id: type.basedElementId,
          name: type.basedElementName,
        ),
      );
    }
    currentTypeId.value = type.id;
    name.text = type.name;
    code.text = type.code;
    selectedBasedElementId.value = type.basedElementId.isEmpty
        ? null
        : type.basedElementId;
    return true;
  }

  Future<bool> saveType() async {
    if (isSaving.value || !(formKey.currentState?.validate() ?? false)) {
      return false;
    }
    final basedElementId = selectedBasedElementId.value;
    if (basedElementId == null || basedElementId.isEmpty) return false;

    isSaving.value = true;
    try {
      final payload = LoanAdvanceTypeModel(
        id: currentTypeId.value,
        name: name.text.trim(),
        code: code.text.trim(),
        basedElementName: '',
        basedElementId: basedElementId,
      ).toRequestJson();
      if (currentTypeId.value.isEmpty) {
        await _api.postJson(
          '/loan_and_advances_types/add_new_loan_and_advances_type',
          body: payload,
        );
      } else {
        await _api.patchJson(
          '/loan_and_advances_types/update_loan_and_advances_type/${currentTypeId.value}',
          body: payload,
        );
      }
      await fetchLoanAdvanceTypes();
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The loan or advance type could not be saved.');
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  Future<bool> deleteType(String id) async {
    try {
      await _api.deleteJson(
        '/loan_and_advances_types/delete_loan_and_advances_type/$id',
      );
      await fetchLoanAdvanceTypes();
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The loan or advance type could not be deleted.');
    }
    return false;
  }

  Future<void> clearFilters() async {
    nameFilter.clear();
    codeFilter.clear();
    selectedFilterBasedElementId.value = null;
    await fetchLoanAdvanceTypes();
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
