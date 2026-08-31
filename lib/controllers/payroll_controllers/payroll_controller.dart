import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/payroll/payroll_model.dart';
import '../../routes/app_routes.dart';
import '../../services/authenticated_api_service.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';

class PayrollController extends GetxController {
  PayrollController({AuthenticatedApiService? api}) : _apiOverride = api;

  final AuthenticatedApiService? _apiOverride;
  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();

  final payrollFormKey = GlobalKey<FormState>();
  final periodFormKey = GlobalKey<FormState>();
  final monthlyPeriodsFormKey = GlobalKey<FormState>();

  final nameFilter = TextEditingController();
  final name = TextEditingController();
  final notes = TextEditingController();
  final periodName = TextEditingController();
  final periodStartDate = TextEditingController();
  final periodEndDate = TextEditingController();
  final yearStartDate = TextEditingController();

  final payrolls = <PayrollModel>[].obs;
  final paymentTypeOptions = <PaymentTypeOption>[].obs;
  final periods = <PayrollPeriodModel>[].obs;
  final selectedFilterPaymentTypeId = RxnString();
  final selectedFilterPaymentTypeName = RxnString();
  final selectedPaymentTypeId = RxnString();
  final selectedPaymentTypeName = RxnString();
  final selectedPeriodStatus = 'Active'.obs;
  final currentPayrollId = ''.obs;
  final currentPeriodId = ''.obs;
  final isLoading = false.obs;
  final isLoadingPaymentTypes = false.obs;
  final isLoadingEditor = false.obs;
  final isSaving = false.obs;
  final isSavingPeriod = false.obs;
  final isGeneratingPeriods = false.obs;
  final listError = RxnString();
  final currentPage = 0.obs;
  final pageSize = 1.obs;

  final List<PayrollModel> _allPayrolls = [];
  String _appliedNameFilter = '';
  String? _appliedPaymentTypeName;
  bool _paymentTypesLoaded = false;
  int? _scheduledPageSize;

  static const statusDropdownItems = <String, dynamic>{
    'Active': {'name': 'Active'},
    'Inactive': {'name': 'Inactive'},
  };

  @override
  void onInit() {
    super.onInit();
    unawaited(fetchPayrolls());
  }

  List<PayrollModel> get visiblePayrolls {
    final start = currentPage.value * pageSize.value;
    if (start >= payrolls.length) return const [];
    final end = (start + pageSize.value).clamp(0, payrolls.length).toInt();
    return payrolls.sublist(start, end);
  }

  int get totalPages =>
      payrolls.isEmpty ? 1 : (payrolls.length / pageSize.value).ceil();

  int get rowStart =>
      payrolls.isEmpty ? 0 : currentPage.value * pageSize.value + 1;

  int get rowEnd => ((currentPage.value + 1) * pageSize.value)
      .clamp(0, payrolls.length)
      .toInt();

  bool get canGoPrevious => currentPage.value > 0;
  bool get canGoNext => currentPage.value + 1 < totalPages;
  bool get editingExistingPayroll => currentPayrollId.value.isNotEmpty;

  Map<String, dynamic> get paymentTypeDropdownItems => {
    for (final option in paymentTypeOptions)
      option.id: {'_id': option.id, 'type': option.name},
  };

  String paymentTypeName(String? id) {
    if (id == null || id.isEmpty) return '';
    for (final option in paymentTypeOptions) {
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
      currentPage.value = payrolls.isEmpty
          ? 0
          : (firstVisibleIndex ~/ scheduledRows)
                .clamp(0, totalPages - 1)
                .toInt();
    });
  }

  Future<void> fetchPayrolls() async {
    if (isLoading.value) return;
    isLoading.value = true;
    listError.value = null;
    try {
      final response = await _api.getJson('/payroll/get_all_payrolls');
      final rawPayrolls = response['all_payrolls'];
      if (rawPayrolls is! List) {
        throw const FormatException('Missing payroll data');
      }
      _allPayrolls
        ..clear()
        ..addAll(
          rawPayrolls.whereType<Map>().map(
            (item) => PayrollModel.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
      _applyFilters();
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      listError.value = error.message;
    } on FormatException {
      listError.value = 'The server returned invalid payroll data.';
    } catch (_) {
      listError.value = 'Payroll definitions could not be loaded.';
    } finally {
      isLoading.value = false;
    }
  }

  void findPayrolls() {
    _appliedNameFilter = nameFilter.text.trim().toLowerCase();
    _appliedPaymentTypeName = selectedFilterPaymentTypeName.value
        ?.trim()
        .toLowerCase();
    _applyFilters();
  }

  Future<void> clearFilters() async {
    nameFilter.clear();
    selectedFilterPaymentTypeId.value = null;
    selectedFilterPaymentTypeName.value = null;
    _appliedNameFilter = '';
    _appliedPaymentTypeName = null;
    _applyFilters();
  }

  void _applyFilters() {
    final paymentType = _appliedPaymentTypeName;
    payrolls.assignAll(
      _allPayrolls.where((payroll) {
        final matchesName =
            _appliedNameFilter.isEmpty ||
            payroll.name.toLowerCase().contains(_appliedNameFilter);
        final matchesPaymentType =
            paymentType == null ||
            paymentType.isEmpty ||
            payroll.paymentTypeName.toLowerCase() == paymentType;
        return matchesName && matchesPaymentType;
      }),
    );
    currentPage.value = 0;
  }

  Future<bool> loadPaymentTypes({
    bool showErrors = true,
    bool forceRefresh = false,
  }) async {
    if (_paymentTypesLoaded && !forceRefresh) return true;
    while (!isClosed && isLoadingPaymentTypes.value) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    if (_paymentTypesLoaded && !forceRefresh) return true;
    if (isClosed) return false;
    isLoadingPaymentTypes.value = true;
    try {
      final response = await _api.getJson(
        '/ap_payment_types/get_all_ap_payment_types',
      );
      final rawTypes = response['types'];
      if (rawTypes is! List) throw const FormatException('Missing types');
      paymentTypeOptions.assignAll(
        rawTypes
            .whereType<Map>()
            .map(
              (item) =>
                  PaymentTypeOption.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((option) => option.id.isNotEmpty && option.name.isNotEmpty),
      );
      _paymentTypesLoaded = true;
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      if (showErrors) await showError(error.message);
    } on FormatException {
      if (showErrors) {
        await showError('The server returned invalid payment-type data.');
      }
    } catch (_) {
      if (showErrors) await showError('Payment types could not be loaded.');
    } finally {
      isLoadingPaymentTypes.value = false;
    }
    return false;
  }

  Future<Map<String, dynamic>> getPaymentTypesForDropdown() async {
    final loaded = await loadPaymentTypes(
      showErrors: false,
      forceRefresh: true,
    );
    return loaded ? paymentTypeDropdownItems : <String, dynamic>{};
  }

  Future<bool> prepareNewPayroll() async {
    _clearEditor();
    await loadPaymentTypes(showErrors: false);
    return true;
  }

  Future<bool> prepareExistingPayroll(PayrollModel summary) async {
    _clearEditor();
    currentPayrollId.value = summary.id;
    isLoadingEditor.value = true;
    try {
      final response = await _api.getJson(
        '/payroll/get_current_payroll_details/${summary.id}',
      );
      final rawPayroll = response['payroll_details'];
      if (rawPayroll is! Map) {
        throw const FormatException('Missing payroll details');
      }
      final payroll = PayrollModel.fromJson(
        Map<String, dynamic>.from(rawPayroll),
      );
      name.text = payroll.name;
      notes.text = payroll.notes;
      selectedPaymentTypeId.value = payroll.paymentTypeId.isEmpty
          ? null
          : payroll.paymentTypeId;
      selectedPaymentTypeName.value = payroll.paymentTypeName.isEmpty
          ? null
          : payroll.paymentTypeName;
      periods.assignAll(payroll.periods);
      await loadPaymentTypes(showErrors: false);
      _ensurePaymentTypeIsAvailable(
        payroll.paymentTypeId,
        payroll.paymentTypeName,
      );
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server returned invalid payroll details.');
    } catch (_) {
      await showError('The payroll details could not be loaded.');
    } finally {
      isLoadingEditor.value = false;
    }
    return false;
  }

  void _ensurePaymentTypeIsAvailable(String id, String typeName) {
    if (id.isEmpty || typeName.isEmpty) return;
    if (paymentTypeOptions.any((option) => option.id == id)) return;
    paymentTypeOptions.add(PaymentTypeOption(id: id, name: typeName));
  }

  Future<bool> savePayroll() async {
    if (isSaving.value || !(payrollFormKey.currentState?.validate() ?? false)) {
      return false;
    }
    isSaving.value = true;
    try {
      final model = PayrollModel(
        id: currentPayrollId.value,
        name: name.text.trim(),
        notes: notes.text.trim(),
        paymentTypeName: selectedPaymentTypeName.value ?? '',
        paymentTypeId: selectedPaymentTypeId.value ?? '',
        periods: periods.toList(growable: false),
      );
      final Map<String, dynamic> response;
      final dynamic rawPayroll;
      if (currentPayrollId.value.isEmpty) {
        response = await _api.postJson(
          '/payroll/create_new_payroll',
          body: model.toRequestJson(),
        );
        rawPayroll = response['added_details'];
      } else {
        response = await _api.patchJson(
          '/payroll/update_payroll/${currentPayrollId.value}',
          body: model.toRequestJson(),
        );
        rawPayroll = response['updated_data'];
      }
      if (rawPayroll is! Map) {
        throw const FormatException('Missing saved payroll');
      }
      final saved = PayrollModel.fromJson(
        Map<String, dynamic>.from(rawPayroll),
      );
      currentPayrollId.value = saved.id;
      name.text = saved.name;
      notes.text = saved.notes;
      selectedPaymentTypeId.value = saved.paymentTypeId.isEmpty
          ? selectedPaymentTypeId.value
          : saved.paymentTypeId;
      selectedPaymentTypeName.value = saved.paymentTypeName.isEmpty
          ? selectedPaymentTypeName.value
          : saved.paymentTypeName;
      periods.assignAll(saved.periods);
      _upsertPayroll(saved);
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server returned invalid saved payroll data.');
    } catch (_) {
      await showError('The payroll could not be saved.');
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  void _upsertPayroll(PayrollModel payroll) {
    final index = _allPayrolls.indexWhere((item) => item.id == payroll.id);
    if (index == -1) {
      _allPayrolls.insert(0, payroll);
    } else {
      _allPayrolls[index] = payroll;
    }
    _applyFilters();
  }

  Future<bool> deletePayroll(String id) async {
    try {
      await _api.deleteJson('/payroll/delete_payroll/$id');
      _allPayrolls.removeWhere((payroll) => payroll.id == id);
      _applyFilters();
      if (currentPayrollId.value == id) _clearEditor();
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The payroll could not be deleted.');
    }
    return false;
  }

  void prepareNewPeriod() {
    currentPeriodId.value = '';
    periodName.clear();
    periodStartDate.clear();
    periodEndDate.clear();
    selectedPeriodStatus.value = 'Active';
    periodFormKey.currentState?.reset();
  }

  void prepareExistingPeriod(PayrollPeriodModel period) {
    currentPeriodId.value = period.id;
    periodName.text = period.name;
    periodStartDate.text = formatPayrollDate(period.startDate);
    periodEndDate.text = formatPayrollDate(period.endDate);
    selectedPeriodStatus.value = period.status == 'Inactive'
        ? 'Inactive'
        : 'Active';
  }

  Future<bool> savePeriod() async {
    if (isSavingPeriod.value ||
        !(periodFormKey.currentState?.validate() ?? false)) {
      return false;
    }
    if (currentPayrollId.value.isEmpty) {
      await showInfo('Save the payroll before adding a period.');
      return false;
    }
    final startDate = parsePayrollDate(periodStartDate.text);
    final endDate = parsePayrollDate(periodEndDate.text);
    if (startDate == null || endDate == null) {
      await showError('Enter valid start and end dates.');
      return false;
    }
    if (endDate.isBefore(startDate)) {
      await showError('End date cannot be before start date.');
      return false;
    }
    final duplicate = periods.any((period) {
      if (period.id == currentPeriodId.value) return false;
      final existing = period.startDate;
      return existing != null &&
          existing.year == startDate.year &&
          existing.month == startDate.month;
    });
    if (duplicate) {
      await showError('A period already exists for this month.');
      return false;
    }

    isSavingPeriod.value = true;
    try {
      final period = PayrollPeriodModel(
        id: currentPeriodId.value,
        name: periodName.text.trim(),
        startDate: startDate,
        endDate: endDate,
        status: selectedPeriodStatus.value,
      );
      final Map<String, dynamic> response;
      final dynamic rawPeriod;
      if (currentPeriodId.value.isEmpty) {
        response = await _api.postJson(
          '/payroll/add_new_period/${currentPayrollId.value}',
          body: period.toRequestJson(),
        );
        rawPeriod = response['added_period'];
      } else {
        response = await _api.patchJson(
          '/payroll/update_period/${currentPeriodId.value}',
          body: period.toRequestJson(),
        );
        rawPeriod = response['updated_period'];
      }
      if (rawPeriod is! Map) {
        throw const FormatException('Missing saved period');
      }
      _upsertPeriod(
        PayrollPeriodModel.fromJson(Map<String, dynamic>.from(rawPeriod)),
      );
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server returned invalid saved period data.');
    } catch (_) {
      await showError('The payroll period could not be saved.');
    } finally {
      isSavingPeriod.value = false;
    }
    return false;
  }

  void _upsertPeriod(PayrollPeriodModel period) {
    final index = periods.indexWhere((item) => item.id == period.id);
    if (index == -1) {
      periods.insert(0, period);
    } else {
      periods[index] = period;
    }
  }

  Future<bool> deletePeriod(String id) async {
    try {
      await _api.deleteJson('/payroll/delete_period/$id');
      periods.removeWhere((period) => period.id == id);
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The payroll period could not be deleted.');
    }
    return false;
  }

  void prepareMonthlyGeneration() {
    yearStartDate.clear();
    monthlyPeriodsFormKey.currentState?.reset();
  }

  Future<bool> generateMonthlyPeriods() async {
    if (isGeneratingPeriods.value ||
        !(monthlyPeriodsFormKey.currentState?.validate() ?? false)) {
      return false;
    }
    if (currentPayrollId.value.isEmpty) {
      await showInfo('Save the payroll before generating periods.');
      return false;
    }
    final startDate = parsePayrollDate(yearStartDate.text);
    if (startDate == null) {
      await showError('Enter a valid year start date.');
      return false;
    }
    isGeneratingPeriods.value = true;
    try {
      final response = await _api.postJson(
        '/payroll/generate_monthly_periods/${currentPayrollId.value}',
        body: {'year_start_date': startDate.toIso8601String()},
      );
      final rawPeriods = response['periods'];
      if (rawPeriods is! List) {
        throw const FormatException('Missing generated periods');
      }
      periods.assignAll(
        rawPeriods.whereType<Map>().map(
          (item) =>
              PayrollPeriodModel.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
      final createdCount = response['created_count'];
      if (createdCount is num && createdCount == 0) {
        await showInfo('Monthly periods already exist for this payroll year.');
      }
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server returned invalid generated periods.');
    } catch (_) {
      await showError('Monthly periods could not be generated.');
    } finally {
      isGeneratingPeriods.value = false;
    }
    return false;
  }

  String? requiredText(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required.'
        : null;
  }

  String? requiredDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return parsePayrollDate(value) == null ? 'Enter a valid date.' : null;
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
      title: 'Payroll',
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

  void _clearEditor() {
    payrollFormKey.currentState?.reset();
    currentPayrollId.value = '';
    currentPeriodId.value = '';
    name.clear();
    notes.clear();
    selectedPaymentTypeId.value = null;
    selectedPaymentTypeName.value = null;
    periods.clear();
    prepareNewPeriod();
    prepareMonthlyGeneration();
  }

  void _openLogin() {
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    nameFilter.dispose();
    name.dispose();
    notes.dispose();
    periodName.dispose();
    periodStartDate.dispose();
    periodEndDate.dispose();
    yearStartDate.dispose();
    super.onClose();
  }
}

String formatPayrollDate(DateTime? date) {
  if (date == null) return '';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

DateTime? parsePayrollDate(String value) {
  final parts = value.trim().split('-');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  final result = DateTime(year, month, day);
  if (result.year != year || result.month != month || result.day != day) {
    return null;
  }
  return result;
}
