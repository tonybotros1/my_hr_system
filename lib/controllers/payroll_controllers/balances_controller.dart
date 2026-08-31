import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/payroll/balance_model.dart';
import '../../routes/app_routes.dart';
import '../../services/authenticated_api_service.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';

class BalancesController extends GetxController {
  BalancesController({AuthenticatedApiService? api}) : _apiOverride = api;

  final AuthenticatedApiService? _apiOverride;
  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();

  final balanceFormKey = GlobalKey<FormState>();
  final basedElementFormKey = GlobalKey<FormState>();

  final nameFilter = TextEditingController();
  final name = TextEditingController();
  final description = TextEditingController();

  final balances = <BalanceModel>[].obs;
  final basedElements = <BalanceBasedElementModel>[].obs;
  final payrollElementOptions = <BalancePayrollElementOption>[].obs;
  final selectedFilterType = RxnString();
  final selectedType = 'Number'.obs;
  final selectedDimension = 'Inception to Date'.obs;
  final showOnAssignment = true.obs;
  final showOnPayroll = true.obs;
  final showOnLeave = true.obs;
  final selectedBasedElementId = RxnString();
  final selectedBasedElementName = RxnString();
  final selectedBasedElementType = 'Add'.obs;
  final currentBalanceId = ''.obs;
  final currentBasedElementId = ''.obs;
  final isLoading = false.obs;
  final isLoadingEditor = false.obs;
  final isLoadingOptions = false.obs;
  final isSaving = false.obs;
  final isSavingBasedElement = false.obs;
  final listError = RxnString();
  final currentPage = 0.obs;
  final pageSize = 1.obs;

  bool _payrollElementsLoaded = false;
  int? _scheduledPageSize;

  static const typeDropdownItems = <String, dynamic>{
    'Number': {'name': 'Number'},
    'Value': {'name': 'Value'},
  };

  static const dimensionDropdownItems = <String, dynamic>{
    'Year to Date': {'name': 'Year to Date'},
    'Inception to Date': {'name': 'Inception to Date'},
    'Run to Date': {'name': 'Run to Date'},
  };

  static const basedElementTypeDropdownItems = <String, dynamic>{
    'Add': {'name': 'Add'},
    'Subtract': {'name': 'Subtract'},
  };

  @override
  void onInit() {
    super.onInit();
    unawaited(fetchBalances());
  }

  List<BalanceModel> get visibleBalances {
    final start = currentPage.value * pageSize.value;
    if (start >= balances.length) return const [];
    final end = (start + pageSize.value).clamp(0, balances.length).toInt();
    return balances.sublist(start, end);
  }

  int get totalPages =>
      balances.isEmpty ? 1 : (balances.length / pageSize.value).ceil();

  int get rowStart =>
      balances.isEmpty ? 0 : currentPage.value * pageSize.value + 1;

  int get rowEnd => ((currentPage.value + 1) * pageSize.value)
      .clamp(0, balances.length)
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
      currentPage.value = balances.isEmpty
          ? 0
          : (firstVisibleIndex ~/ scheduledRows)
                .clamp(0, totalPages - 1)
                .toInt();
    });
  }

  Future<void> fetchBalances() async {
    if (isLoading.value) return;
    isLoading.value = true;
    listError.value = null;
    try {
      final body = <String, dynamic>{};
      final filterName = nameFilter.text.trim();
      if (filterName.isNotEmpty) body['name'] = filterName;
      final filterType = selectedFilterType.value;
      if (filterType != null && filterType.isNotEmpty) {
        body['type'] = filterType;
      }

      final response = await _api.postJson(
        '/balance/search_engine_for_balance',
        body: body,
      );
      final rawBalances = response['balances'];
      if (rawBalances is! List) {
        throw const FormatException('Missing balances');
      }
      balances.assignAll(
        rawBalances.whereType<Map>().map(
          (item) => BalanceModel.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
      currentPage.value = 0;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      listError.value = error.message;
    } on FormatException {
      listError.value = 'The server returned invalid balance data.';
    } catch (_) {
      listError.value = 'Balances could not be loaded.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearFilters() async {
    nameFilter.clear();
    selectedFilterType.value = null;
    await fetchBalances();
  }

  void prepareNewBalance() {
    balanceFormKey.currentState?.reset();
    currentBalanceId.value = '';
    name.clear();
    description.clear();
    selectedType.value = 'Number';
    selectedDimension.value = 'Inception to Date';
    showOnAssignment.value = true;
    showOnPayroll.value = true;
    showOnLeave.value = true;
    basedElements.clear();
    prepareNewBasedElement();
  }

  Future<bool> prepareExistingBalance(BalanceModel summary) async {
    prepareNewBalance();
    currentBalanceId.value = summary.id;
    isLoadingEditor.value = true;
    try {
      final response = await _api.getJson(
        '/balance/get_balance_details/${summary.id}',
      );
      final rawDetails = response['details'];
      if (rawDetails is! Map) {
        throw const FormatException('Missing balance details');
      }
      final balance = BalanceModel.fromJson(
        Map<String, dynamic>.from(rawDetails),
      );
      currentBalanceId.value = balance.id;
      name.text = balance.name;
      description.text = balance.description;
      selectedType.value = typeDropdownItems.containsKey(balance.type)
          ? balance.type
          : 'Number';
      selectedDimension.value =
          dimensionDropdownItems.containsKey(balance.dimension)
          ? balance.dimension
          : 'Inception to Date';
      showOnAssignment.value = balance.showOnAssignment;
      showOnPayroll.value = balance.showOnPayroll;
      showOnLeave.value = balance.showOnLeave;
      basedElements.assignAll(balance.basedElements);
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server returned invalid balance details.');
    } catch (_) {
      await showError('The balance details could not be loaded.');
    } finally {
      isLoadingEditor.value = false;
    }
    return false;
  }

  Future<bool> saveBalance() async {
    if (isSaving.value || !(balanceFormKey.currentState?.validate() ?? false)) {
      return false;
    }
    isSaving.value = true;
    try {
      var model = _currentBalance();
      if (currentBalanceId.value.isEmpty) {
        final response = await _api.postJson(
          '/balance/add_new_balance',
          body: model.toRequestJson(),
        );
        final id = response['added_balance_id']?.toString() ?? '';
        if (id.isEmpty) throw const FormatException('Missing balance id');
        currentBalanceId.value = id;
        model = _currentBalance();
      } else {
        await _api.patchJson(
          '/balance/update_balance/${currentBalanceId.value}',
          body: model.toRequestJson(),
        );
      }
      _upsertBalance(model);
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server returned invalid saved balance data.');
    } catch (_) {
      await showError('The balance could not be saved.');
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  BalanceModel _currentBalance() {
    return BalanceModel(
      id: currentBalanceId.value,
      name: name.text.trim(),
      type: selectedType.value,
      dimension: selectedDimension.value,
      description: description.text.trim(),
      showOnAssignment: showOnAssignment.value,
      showOnPayroll: showOnPayroll.value,
      showOnLeave: showOnLeave.value,
      basedElements: basedElements.toList(growable: false),
    );
  }

  void _upsertBalance(BalanceModel balance) {
    final index = balances.indexWhere((item) => item.id == balance.id);
    if (index == -1) {
      balances.insert(0, balance);
    } else {
      balances[index] = balance;
    }
  }

  Future<bool> deleteBalance(String id) async {
    try {
      await _api.deleteJson('/balance/delete_balance/$id');
      balances.removeWhere((balance) => balance.id == id);
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The balance could not be deleted.');
    }
    return false;
  }

  Future<bool> loadPayrollElementOptions({
    bool showErrors = true,
    bool forceRefresh = false,
  }) async {
    if (_payrollElementsLoaded && !forceRefresh) return true;
    while (!isClosed && isLoadingOptions.value) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    if (_payrollElementsLoaded && !forceRefresh) return true;
    if (isClosed) return false;
    isLoadingOptions.value = true;
    try {
      final response = await _api.postJson(
        '/payroll_elements/get_payroll_elements_for_lov_for_payroll_elements',
        body: const {'element_id': ''},
      );
      final rawOptions = response['elements'];
      if (rawOptions is! List) throw const FormatException('Missing options');
      payrollElementOptions.assignAll(
        rawOptions
            .whereType<Map>()
            .map(
              (item) => BalancePayrollElementOption.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((option) => option.id.isNotEmpty && option.name.isNotEmpty),
      );
      _payrollElementsLoaded = true;
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      if (showErrors) await showError(error.message);
    } on FormatException {
      if (showErrors) {
        await showError('The server returned invalid payroll elements.');
      }
    } catch (_) {
      if (showErrors) await showError('Payroll elements could not be loaded.');
    } finally {
      isLoadingOptions.value = false;
    }
    return false;
  }

  Future<Map<String, dynamic>> getPayrollElementsForDropdown() async {
    final loaded = await loadPayrollElementOptions(
      showErrors: false,
      forceRefresh: true,
    );
    return loaded ? payrollElementDropdownItems : <String, dynamic>{};
  }

  void prepareNewBasedElement() {
    basedElementFormKey.currentState?.reset();
    currentBasedElementId.value = '';
    selectedBasedElementId.value = null;
    selectedBasedElementName.value = null;
    selectedBasedElementType.value = 'Add';
  }

  Future<void> prepareExistingBasedElement(
    BalanceBasedElementModel element,
  ) async {
    currentBasedElementId.value = element.id;
    selectedBasedElementId.value = element.elementId;
    selectedBasedElementName.value = element.elementName;
    selectedBasedElementType.value = element.type == 'Subtract'
        ? 'Subtract'
        : 'Add';
    await loadPayrollElementOptions(showErrors: false);
    if (element.elementId.isNotEmpty &&
        element.elementName.isNotEmpty &&
        !payrollElementOptions.any(
          (option) => option.id == element.elementId,
        )) {
      payrollElementOptions.add(
        BalancePayrollElementOption(
          id: element.elementId,
          name: element.elementName,
        ),
      );
    }
  }

  Future<bool> saveBasedElement() async {
    if (isSavingBasedElement.value ||
        !(basedElementFormKey.currentState?.validate() ?? false)) {
      return false;
    }
    if (currentBalanceId.value.isEmpty) {
      await showInfo('Save the balance before adding a based element.');
      return false;
    }
    final elementId = selectedBasedElementId.value;
    final elementName = selectedBasedElementName.value;
    if (elementId == null ||
        elementId.isEmpty ||
        elementName == null ||
        elementName.isEmpty) {
      return false;
    }
    final duplicate = basedElements.any(
      (element) =>
          element.elementId == elementId &&
          element.id != currentBasedElementId.value,
    );
    if (duplicate) {
      await showError('This based element is already added.');
      return false;
    }

    isSavingBasedElement.value = true;
    try {
      var element = BalanceBasedElementModel(
        id: currentBasedElementId.value,
        elementId: elementId,
        elementName: elementName,
        type: selectedBasedElementType.value,
      );
      if (currentBasedElementId.value.isEmpty) {
        final response = await _api.postJson(
          '/balance/add_new_based_element/${currentBalanceId.value}',
          body: element.toRequestJson(),
        );
        final id = response['added_based_element_id']?.toString() ?? '';
        if (id.isEmpty) {
          throw const FormatException('Missing based element id');
        }
        element = BalanceBasedElementModel(
          id: id,
          elementId: element.elementId,
          elementName: element.elementName,
          type: element.type,
        );
      } else {
        await _api.patchJson(
          '/balance/update_based_element/${currentBasedElementId.value}',
          body: element.toRequestJson(),
        );
      }
      _upsertBasedElement(element);
      _upsertBalance(_currentBalance());
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server returned invalid based-element data.');
    } catch (_) {
      await showError('The based element could not be saved.');
    } finally {
      isSavingBasedElement.value = false;
    }
    return false;
  }

  void _upsertBasedElement(BalanceBasedElementModel element) {
    final index = basedElements.indexWhere((item) => item.id == element.id);
    if (index == -1) {
      basedElements.add(element);
    } else {
      basedElements[index] = element;
    }
  }

  Future<bool> deleteBasedElement(String id) async {
    try {
      await _api.deleteJson('/balance/delete_based_element/$id');
      basedElements.removeWhere((element) => element.id == id);
      _upsertBalance(_currentBalance());
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The based element could not be deleted.');
    }
    return false;
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

  Future<void> showInfo(String message) {
    return showAppAlertDialog(
      title: 'Balances',
      message: message,
      kind: AppAlertKind.info,
    );
  }

  void nextPage() {
    if (canGoNext) currentPage.value++;
  }

  void previousPage() {
    if (canGoPrevious) currentPage.value--;
  }

  void _openLogin() {
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    nameFilter.dispose();
    name.dispose();
    description.dispose();
    super.onClose();
  }
}
