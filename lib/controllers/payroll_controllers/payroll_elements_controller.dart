import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../models/payroll/based_element_model.dart';
import '../../models/payroll/payroll_element_model.dart';
import '../../routes/app_routes.dart';
import '../../services/authenticated_api_service.dart';

class PayrollElementsController extends GetxController {
  PayrollElementsController({AuthenticatedApiService? api})
    : _apiOverride = api;

  static const elementTypes = ['Earning', 'Deduction', 'Information'];
  static const basedElementTypes = ['Add', 'Subtract'];
  static const functions = [
    'PY_INPUT_VALUE_FF',
    'PY_ANNUAL_LEAVE_FF',
    'PY_UNPAID_LEAVE_FF',
    'PY_SICK_LEAVE_FF',
    'PY_MATERNITY_LEAVE_FF',
    'PY_COMPASSIONATE_LEAVE_FF',
    'PY_ANNUAL_LEAVE_ENTITLEMENT_FF',
    'PY_PATERNITY_LEAVE_FF',
    'PY_OVERTIME_NORMAL_FF',
    'PY_OVERTIME_HOLIDAYS_FF',
    'PY_NONRECURRING_FF',
    'PY_SOCIAL_SECURITY_EMPLOYEE_FF',
    'PY_SOCIAL_SECURITY_EMPLOYER_FF',
    'PY_GRATUITY_ACCRUAL_FF',
    'PY_LOAN_AND_ADVANCES_FF',
    'PY_SERVICE_TAX_FF',
    'PY_INCOME_TAX_DEDUCTION_FF',
  ];

  final AuthenticatedApiService? _apiOverride;
  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();

  final keyFilter = TextEditingController();
  final nameFilter = TextEditingController();
  final elementKey = TextEditingController();
  final elementName = TextEditingController();
  final priority = TextEditingController();
  final entryValueName = TextEditingController();
  final comments = TextEditingController();

  final elementFormKey = GlobalKey<FormState>();
  final basedElementFormKey = GlobalKey<FormState>();

  final elements = <PayrollElementModel>[].obs;
  final basedElements = <BasedElementModel>[].obs;
  final basedElementOptions = <PayrollElementOption>[].obs;
  final selectedListType = 'All'.obs;
  final selectedElementType = 'Information'.obs;
  final selectedFunction = 'PY_NONRECURRING_FF'.obs;
  final selectedBasedElementId = RxnString();
  final selectedBasedElementType = 'Add'.obs;
  final currentElementId = ''.obs;
  final editingBasedElementId = ''.obs;
  final allowOverride = false.obs;
  final recurring = false.obs;
  final entryValue = false.obs;
  final standardLink = false.obs;
  final indirect = false.obs;
  final isLoading = false.obs;
  final isLoadingEditor = false.obs;
  final isSaving = false.obs;
  final isLoadingBasedOptions = false.obs;
  final isSavingBasedElement = false.obs;
  final listError = RxnString();
  final currentPage = 0.obs;
  final pageSize = 1.obs;
  int? _scheduledPageSize;

  @override
  void onInit() {
    super.onInit();
    unawaited(fetchElements());
  }

  List<PayrollElementModel> get visibleElements {
    final start = currentPage.value * pageSize.value;
    if (start >= elements.length) return const [];
    final end = (start + pageSize.value).clamp(0, elements.length).toInt();
    return elements.sublist(start, end);
  }

  int get totalPages =>
      elements.isEmpty ? 1 : (elements.length / pageSize.value).ceil();

  int get rowStart =>
      elements.isEmpty ? 0 : currentPage.value * pageSize.value + 1;

  int get rowEnd => ((currentPage.value + 1) * pageSize.value)
      .clamp(0, elements.length)
      .toInt();

  bool get canGoPrevious => currentPage.value > 0;

  bool get canGoNext => currentPage.value + 1 < totalPages;

  Map<String, dynamic> get basedElementDropdownItems => {
    for (final option in basedElementOptions)
      option.id: {'_id': option.id, 'name': option.name},
  };

  String basedElementOptionName(String? id) {
    if (id == null || id.isEmpty) return '';
    for (final option in basedElementOptions) {
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
      if (elements.isEmpty) {
        currentPage.value = 0;
        return;
      }
      currentPage.value = (firstVisibleIndex ~/ scheduledRows)
          .clamp(0, totalPages - 1)
          .toInt();
    });
  }

  Future<void> fetchElements() async {
    if (isLoading.value) return;
    isLoading.value = true;
    listError.value = null;
    try {
      final body = <String, dynamic>{};
      if (keyFilter.text.trim().isNotEmpty) {
        body['key'] = keyFilter.text.trim();
      }
      if (nameFilter.text.trim().isNotEmpty) {
        body['name'] = nameFilter.text.trim();
      }
      if (selectedListType.value != 'All') {
        body['type'] = selectedListType.value;
      }

      final response = await _api.postJson(
        '/payroll_elements/search_engine_for_payroll_elements',
        body: body,
      );
      final rawElements = response['payroll_elements'];
      if (rawElements is! List) {
        throw const FormatException('Missing payroll elements');
      }
      elements.assignAll(
        rawElements.whereType<Map>().map(
          (item) =>
              PayrollElementModel.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
      currentPage.value = 0;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      listError.value = error.message;
    } on FormatException {
      listError.value = 'The server returned invalid payroll element data.';
    } catch (_) {
      listError.value = 'Payroll elements could not be loaded.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectListType(String type) async {
    if (selectedListType.value == type) return;
    selectedListType.value = type;
    await fetchElements();
  }

  Future<void> clearFilters() async {
    keyFilter.clear();
    nameFilter.clear();
    selectedListType.value = 'All';
    await fetchElements();
  }

  void nextPage() {
    if (canGoNext) currentPage.value++;
  }

  void previousPage() {
    if (canGoPrevious) currentPage.value--;
  }

  void prepareNewElement() {
    currentElementId.value = '';
    elementKey.clear();
    elementName.clear();
    priority.text = '0';
    entryValueName.clear();
    comments.clear();
    selectedElementType.value = 'Information';
    selectedFunction.value = 'PY_NONRECURRING_FF';
    allowOverride.value = false;
    recurring.value = false;
    entryValue.value = false;
    standardLink.value = false;
    indirect.value = false;
    basedElements.clear();
  }

  Future<bool> loadElement(String id) async {
    if (isLoadingEditor.value) return false;
    isLoadingEditor.value = true;
    try {
      final element = await _fetchElementDetails(id);
      _hydrateEditor(element);
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server returned invalid element details.');
    } catch (_) {
      await showError('The payroll element could not be opened.');
    } finally {
      isLoadingEditor.value = false;
    }
    return false;
  }

  Future<bool> saveElement() async {
    if (isSaving.value || !(elementFormKey.currentState?.validate() ?? false)) {
      return false;
    }
    isSaving.value = true;
    try {
      final payload = _editorValue().toRequestJson();
      if (currentElementId.value.isEmpty) {
        final response = await _api.postJson(
          '/payroll_elements/add_new_payroll_element',
          body: payload,
        );
        final id = response['added_element_id']?.toString() ?? '';
        if (id.isEmpty) throw const FormatException('Missing element id');
        currentElementId.value = id;
      } else {
        await _api.patchJson(
          '/payroll_elements/update_payroll_element/${currentElementId.value}',
          body: payload,
        );
      }
      await fetchElements();
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server did not confirm the saved element.');
    } catch (_) {
      await showError('The payroll element could not be saved.');
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  Future<bool> deleteElement(String id) async {
    try {
      await _api.deleteJson('/payroll_elements/delete_payroll_element/$id');
      await fetchElements();
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The payroll element could not be deleted.');
    }
    return false;
  }

  Future<bool> prepareNewBasedElement() async {
    if (currentElementId.value.isEmpty) {
      await showError('Save the payroll element before adding based elements.');
      return false;
    }
    editingBasedElementId.value = '';
    selectedBasedElementId.value = null;
    selectedBasedElementType.value = 'Add';
    return _loadBasedElementOptions();
  }

  Future<bool> prepareExistingBasedElement(BasedElementModel element) async {
    editingBasedElementId.value = element.id;
    selectedBasedElementId.value = element.elementId;
    selectedBasedElementType.value = element.type.isEmpty
        ? 'Add'
        : element.type;
    return _loadBasedElementOptions();
  }

  Future<bool> _loadBasedElementOptions() async {
    if (isLoadingBasedOptions.value) return false;
    isLoadingBasedOptions.value = true;
    try {
      final response = await _api.postJson(
        '/payroll_elements/get_payroll_elements_for_lov_for_payroll_elements',
        body: {'element_id': currentElementId.value},
      );
      final rawOptions = response['elements'];
      if (rawOptions is! List) throw const FormatException('Missing options');
      basedElementOptions.assignAll(
        rawOptions.whereType<Map>().map(
          (item) =>
              PayrollElementOption.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server returned invalid based-element options.');
    } catch (_) {
      await showError('Based-element options could not be loaded.');
    } finally {
      isLoadingBasedOptions.value = false;
    }
    return false;
  }

  Future<bool> saveBasedElement() async {
    if (isSavingBasedElement.value ||
        !(basedElementFormKey.currentState?.validate() ?? false)) {
      return false;
    }
    final selectedId = selectedBasedElementId.value;
    if (selectedId == null || selectedId.isEmpty) return false;

    isSavingBasedElement.value = true;
    try {
      final body = {'name': selectedId, 'type': selectedBasedElementType.value};
      if (editingBasedElementId.value.isEmpty) {
        await _api.postJson(
          '/payroll_elements/add_new_based_element/${currentElementId.value}',
          body: body,
        );
      } else {
        await _api.patchJson(
          '/payroll_elements/update_based_element/${editingBasedElementId.value}',
          body: body,
        );
      }
      await _refreshBasedElements();
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The based element could not be saved.');
    } finally {
      isSavingBasedElement.value = false;
    }
    return false;
  }

  Future<bool> deleteBasedElement(String id) async {
    try {
      await _api.deleteJson('/payroll_elements/delete_based_element/$id');
      await _refreshBasedElements();
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

  Future<void> _refreshBasedElements() async {
    if (currentElementId.value.isEmpty) return;
    final element = await _fetchElementDetails(currentElementId.value);
    basedElements.assignAll(element.basedElements);
  }

  Future<PayrollElementModel> _fetchElementDetails(String id) async {
    final response = await _api.getJson(
      '/payroll_elements/get_payroll_element_details/$id',
    );
    final details = response['details'];
    if (details is! Map) throw const FormatException('Missing details');
    return PayrollElementModel.fromJson(Map<String, dynamic>.from(details));
  }

  PayrollElementModel _editorValue() {
    return PayrollElementModel(
      id: currentElementId.value,
      key: elementKey.text.trim(),
      name: elementName.text.trim(),
      type: selectedElementType.value,
      priority: priority.text.trim(),
      entryValueName: entryValueName.text.trim(),
      comments: comments.text.trim(),
      functionName: selectedFunction.value,
      allowOverride: allowOverride.value,
      recurring: recurring.value,
      entryValue: entryValue.value,
      standardLink: standardLink.value,
      indirect: indirect.value,
      basedElements: basedElements.toList(growable: false),
    );
  }

  void _hydrateEditor(PayrollElementModel element) {
    currentElementId.value = element.id;
    elementKey.text = element.key;
    elementName.text = element.name;
    priority.text = element.priority;
    entryValueName.text = element.entryValueName;
    comments.text = element.comments;
    selectedElementType.value = elementTypes.contains(element.type)
        ? element.type
        : 'Information';
    selectedFunction.value = functions.contains(element.functionName)
        ? element.functionName
        : 'PY_NONRECURRING_FF';
    allowOverride.value = element.allowOverride;
    recurring.value = element.recurring;
    entryValue.value = element.entryValue;
    standardLink.value = element.standardLink;
    indirect.value = element.indirect;
    basedElements.assignAll(element.basedElements);
  }

  String? requiredText(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required.'
        : null;
  }

  void _openLogin() {
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    keyFilter.dispose();
    nameFilter.dispose();
    elementKey.dispose();
    elementName.dispose();
    priority.dispose();
    entryValueName.dispose();
    comments.dispose();
    super.onClose();
  }
}
