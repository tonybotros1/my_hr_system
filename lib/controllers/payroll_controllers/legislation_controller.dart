import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/payroll/legislation_model.dart';
import '../../routes/app_routes.dart';
import '../../services/authenticated_api_service.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';

class IncomeTaxBracketFields {
  IncomeTaxBracketFields({IncomeTaxBracketModel? bracket}) {
    if (bracket == null) return;
    fromAmount.text = formatLegislationNumber(bracket.fromAmount);
    toAmount.text = bracket.toAmount == null
        ? ''
        : formatLegislationNumber(bracket.toAmount!);
    percentage.text = formatLegislationNumber(bracket.percentage);
  }

  final fromAmount = TextEditingController();
  final toAmount = TextEditingController();
  final percentage = TextEditingController();

  void dispose() {
    fromAmount.dispose();
    toAmount.dispose();
    percentage.dispose();
  }
}

class SocialSecurityCeilingFields {
  SocialSecurityCeilingFields({SocialSecurityCeilingModel? line}) {
    if (line == null) return;
    employeePercentage.text = formatLegislationNumber(line.employeePercentage);
    employerPercentage.text = formatLegislationNumber(line.employerPercentage);
    ceiling.text = formatLegislationNumber(line.ceiling);
    startDate.text = formatLegislationDate(line.startDate);
    endDate.text = formatLegislationDate(line.endDate);
  }

  final employeePercentage = TextEditingController();
  final employerPercentage = TextEditingController();
  final ceiling = TextEditingController();
  final startDate = TextEditingController();
  final endDate = TextEditingController();

  void dispose() {
    employeePercentage.dispose();
    employerPercentage.dispose();
    ceiling.dispose();
    startDate.dispose();
    endDate.dispose();
  }
}

class LegislationController extends GetxController {
  LegislationController({AuthenticatedApiService? api}) : _apiOverride = api;

  final AuthenticatedApiService? _apiOverride;
  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();

  static const weekDays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final formKey = GlobalKey<FormState>();
  final nameFilter = TextEditingController();
  final name = TextEditingController();
  final paidSickLeaveDays = TextEditingController();
  final halfPaidSickLeaveDays = TextEditingController();
  final unpaidSickLeaveDays = TextEditingController();
  final maternityLeaveDays = TextEditingController();
  final paternityLeaveDays = TextEditingController();
  final compassionateLeaveDays = TextEditingController();
  final normalOvertimeHours = TextEditingController();
  final holidayOvertimeHours = TextEditingController();
  final gratuityFirstFiveYears = TextEditingController();
  final gratuityAfterFiveYears = TextEditingController();
  final serviceTaxPercentage = TextEditingController();
  final incomeTaxPercentage = TextEditingController();
  final incomeTaxCeiling = TextEditingController();

  final legislations = <LegislationModel>[].obs;
  final selectedWeekendDays = <String>[].obs;
  final socialSecurityCeilings = <SocialSecurityCeilingFields>[].obs;
  final incomeTaxBrackets = <IncomeTaxBracketFields>[].obs;
  final currentLegislationId = ''.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final listError = RxnString();
  final currentPage = 0.obs;
  final pageSize = 1.obs;

  int? _scheduledPageSize;

  @override
  void onInit() {
    super.onInit();
    unawaited(fetchLegislations());
  }

  bool get isEditing => currentLegislationId.value.isNotEmpty;

  List<LegislationModel> get visibleLegislations {
    final start = currentPage.value * pageSize.value;
    if (start >= legislations.length) return const [];
    final end = (start + pageSize.value).clamp(0, legislations.length).toInt();
    return legislations.sublist(start, end);
  }

  int get totalPages =>
      legislations.isEmpty ? 1 : (legislations.length / pageSize.value).ceil();
  int get rowStart =>
      legislations.isEmpty ? 0 : currentPage.value * pageSize.value + 1;
  int get rowEnd => ((currentPage.value + 1) * pageSize.value)
      .clamp(0, legislations.length)
      .toInt();
  bool get canGoPrevious => currentPage.value > 0;
  bool get canGoNext => currentPage.value + 1 < totalPages;

  void schedulePageSize(int rows) {
    final normalized = rows < 1 ? 1 : rows;
    if (normalized == pageSize.value || normalized == _scheduledPageSize) {
      return;
    }
    _scheduledPageSize = normalized;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scheduled = _scheduledPageSize;
      _scheduledPageSize = null;
      if (isClosed || scheduled == null || scheduled == pageSize.value) return;
      final firstVisibleIndex = currentPage.value * pageSize.value;
      pageSize.value = scheduled;
      currentPage.value = legislations.isEmpty
          ? 0
          : (firstVisibleIndex ~/ scheduled).clamp(0, totalPages - 1).toInt();
    });
  }

  Future<void> fetchLegislations() async {
    if (isLoading.value) return;
    isLoading.value = true;
    listError.value = null;
    try {
      final query = nameFilter.text.trim();
      final response = await _api.postJson(
        '/legislation/search_engine_for_legislations',
        body: {if (query.isNotEmpty) 'name': query},
      );
      final rawItems = response['legislations_elements'];
      if (rawItems is! List) {
        throw const FormatException('Missing legislations');
      }
      legislations.assignAll(
        rawItems.whereType<Map>().map(
          (item) => LegislationModel.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
      currentPage.value = 0;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      listError.value = error.message;
    } on FormatException {
      listError.value = 'The server returned invalid legislation data.';
    } catch (_) {
      listError.value = 'Legislations could not be loaded.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearFilters() async {
    nameFilter.clear();
    await fetchLegislations();
  }

  void prepareNewLegislation() {
    currentLegislationId.value = '';
    _clearEditorValues();
    addSocialSecurityCeiling();
    addIncomeTaxBracket();
  }

  void prepareExistingLegislation(LegislationModel legislation) {
    currentLegislationId.value = legislation.id;
    _clearEditorValues();
    name.text = legislation.name;
    selectedWeekendDays.assignAll(legislation.weekend);
    paidSickLeaveDays.text = '${legislation.paidSickLeaveDays}';
    halfPaidSickLeaveDays.text = '${legislation.halfPaidSickLeaveDays}';
    unpaidSickLeaveDays.text = '${legislation.unpaidSickLeaveDays}';
    maternityLeaveDays.text = '${legislation.maternityLeaveDays}';
    paternityLeaveDays.text = '${legislation.paternityLeaveDays}';
    compassionateLeaveDays.text = '${legislation.compassionateLeaveDays}';
    normalOvertimeHours.text = formatLegislationNumber(
      legislation.normalOvertimeHours,
    );
    holidayOvertimeHours.text = formatLegislationNumber(
      legislation.holidayOvertimeHours,
    );
    gratuityFirstFiveYears.text = '${legislation.gratuityFirstFiveYears}';
    gratuityAfterFiveYears.text = '${legislation.gratuityAfterFiveYears}';
    serviceTaxPercentage.text = formatLegislationNumber(
      legislation.serviceTaxPercentage,
    );
    incomeTaxPercentage.text = formatLegislationNumber(
      legislation.incomeTaxPercentage,
    );
    incomeTaxCeiling.text = formatLegislationNumber(
      legislation.incomeTaxCeiling,
    );
    for (final line in legislation.socialSecurityCeilings) {
      addSocialSecurityCeiling(line: line);
    }
    if (socialSecurityCeilings.isEmpty) addSocialSecurityCeiling();
    for (final bracket in legislation.incomeTaxBrackets) {
      addIncomeTaxBracket(bracket: bracket);
    }
    if (incomeTaxBrackets.isEmpty) addIncomeTaxBracket();
  }

  void toggleWeekendDay(String day) {
    if (selectedWeekendDays.contains(day)) {
      selectedWeekendDays.remove(day);
    } else {
      selectedWeekendDays.add(day);
    }
  }

  void addSocialSecurityCeiling({SocialSecurityCeilingModel? line}) {
    socialSecurityCeilings.add(SocialSecurityCeilingFields(line: line));
  }

  void removeSocialSecurityCeiling(int index) {
    if (index < 0 || index >= socialSecurityCeilings.length) return;
    socialSecurityCeilings.removeAt(index).dispose();
    if (socialSecurityCeilings.isEmpty) addSocialSecurityCeiling();
  }

  void addIncomeTaxBracket({IncomeTaxBracketModel? bracket}) {
    incomeTaxBrackets.add(IncomeTaxBracketFields(bracket: bracket));
  }

  void removeIncomeTaxBracket(int index) {
    if (index < 0 || index >= incomeTaxBrackets.length) return;
    incomeTaxBrackets.removeAt(index).dispose();
    if (incomeTaxBrackets.isEmpty) addIncomeTaxBracket();
  }

  Future<bool> saveLegislation() async {
    if (isSaving.value || !(formKey.currentState?.validate() ?? false)) {
      return false;
    }
    final validationError = _dynamicRowsValidationError();
    if (validationError != null) {
      await showError(validationError);
      return false;
    }

    isSaving.value = true;
    try {
      final payload = _currentLegislation().toRequestJson();
      if (isEditing) {
        await _api.patchJson(
          '/legislation/update_legislation/${currentLegislationId.value}',
          body: payload,
        );
      } else {
        final response = await _api.postJson(
          '/legislation/add_new_legislation',
          body: payload,
        );
        if (response['new_leg'] is! Map) {
          throw const FormatException('Missing created legislation');
        }
      }
      await fetchLegislations();
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server returned invalid legislation data.');
    } catch (_) {
      await showError('The legislation could not be saved.');
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  Future<bool> deleteLegislation(LegislationModel legislation) async {
    try {
      final response = await _api.deleteJson(
        '/legislation/delete_legislation/${legislation.id}',
      );
      final message = response['message']?.toString().toLowerCase() ?? '';
      if (!message.contains('removed successfully')) {
        throw const ApiRequestException('The legislation was not deleted.');
      }
      await fetchLegislations();
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The legislation could not be deleted.');
    }
    return false;
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

  String? integerValue(String? value) {
    final source = value?.trim() ?? '';
    if (source.isEmpty) return null;
    final parsed = int.tryParse(source);
    return parsed == null || parsed < 0 ? 'Enter a valid whole number.' : null;
  }

  String? decimalValue(String? value) {
    final source = value?.trim() ?? '';
    if (source.isEmpty) return null;
    final parsed = double.tryParse(source);
    return parsed == null || parsed < 0 ? 'Enter a valid number.' : null;
  }

  Future<void> showError(String message) {
    return showAppAlertDialog(
      title: 'Could not complete the request',
      message: message,
      kind: AppAlertKind.error,
    );
  }

  String? _dynamicRowsValidationError() {
    if (socialSecurityCeilings.isEmpty) {
      return 'Add at least one social security ceiling line.';
    }
    for (var index = 0; index < socialSecurityCeilings.length; index++) {
      final line = socialSecurityCeilings[index];
      final employee = double.tryParse(line.employeePercentage.text.trim());
      final employer = double.tryParse(line.employerPercentage.text.trim());
      final ceiling = double.tryParse(line.ceiling.text.trim());
      final startDate = parseLegislationDate(line.startDate.text);
      final endDate = parseLegislationDate(line.endDate.text);
      if (employee == null || employee < 0) {
        return 'Ceiling line ${index + 1} needs a valid employee percentage.';
      }
      if (employer == null || employer < 0) {
        return 'Ceiling line ${index + 1} needs a valid employer percentage.';
      }
      if (ceiling == null || ceiling <= 0) {
        return 'Ceiling line ${index + 1} must have a ceiling greater than zero.';
      }
      if (startDate == null) {
        return 'Ceiling line ${index + 1} needs a start date.';
      }
      if (endDate != null && endDate.isBefore(startDate)) {
        return 'Ceiling line ${index + 1} end date cannot be before its start date.';
      }
    }
    for (var index = 0; index < incomeTaxBrackets.length; index++) {
      final bracket = incomeTaxBrackets[index];
      final fields = [
        bracket.fromAmount.text,
        bracket.toAmount.text,
        bracket.percentage.text,
      ];
      if (fields.every((value) => value.trim().isEmpty)) continue;
      final from = double.tryParse(bracket.fromAmount.text.trim());
      final toSource = bracket.toAmount.text.trim();
      final to = toSource.isEmpty ? null : double.tryParse(toSource);
      final percentage = double.tryParse(bracket.percentage.text.trim());
      if (from == null || from < 0 || percentage == null || percentage < 0) {
        return 'Tax bracket ${index + 1} contains an invalid value.';
      }
      if (toSource.isNotEmpty && (to == null || to <= from)) {
        return 'Tax bracket ${index + 1} upper amount must exceed its lower amount.';
      }
    }
    return null;
  }

  LegislationModel _currentLegislation() {
    return LegislationModel(
      id: currentLegislationId.value,
      name: name.text.trim(),
      weekend: selectedWeekendDays.toList(),
      paidSickLeaveDays: _int(paidSickLeaveDays),
      halfPaidSickLeaveDays: _int(halfPaidSickLeaveDays),
      unpaidSickLeaveDays: _int(unpaidSickLeaveDays),
      maternityLeaveDays: _int(maternityLeaveDays),
      compassionateLeaveDays: _int(compassionateLeaveDays),
      paternityLeaveDays: _int(paternityLeaveDays),
      normalOvertimeHours: _double(normalOvertimeHours),
      holidayOvertimeHours: _double(holidayOvertimeHours),
      socialSecurityCeilings: socialSecurityCeilings
          .map(
            (line) => SocialSecurityCeilingModel(
              employeePercentage: _double(line.employeePercentage),
              employerPercentage: _double(line.employerPercentage),
              ceiling: _double(line.ceiling),
              startDate: parseLegislationDate(line.startDate.text),
              endDate: parseLegislationDate(line.endDate.text),
            ),
          )
          .toList(),
      serviceTaxPercentage: _double(serviceTaxPercentage),
      incomeTaxPercentage: _double(incomeTaxPercentage),
      incomeTaxCeiling: _double(incomeTaxCeiling),
      incomeTaxBrackets: incomeTaxBrackets
          .where(
            (bracket) =>
                bracket.fromAmount.text.trim().isNotEmpty ||
                bracket.toAmount.text.trim().isNotEmpty ||
                bracket.percentage.text.trim().isNotEmpty,
          )
          .map(
            (bracket) => IncomeTaxBracketModel(
              fromAmount: _double(bracket.fromAmount),
              toAmount: bracket.toAmount.text.trim().isEmpty
                  ? null
                  : _double(bracket.toAmount),
              percentage: _double(bracket.percentage),
            ),
          )
          .toList(),
      gratuityFirstFiveYears: _int(gratuityFirstFiveYears),
      gratuityAfterFiveYears: _int(gratuityAfterFiveYears),
    );
  }

  int _int(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  double _double(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  void _clearEditorValues() {
    formKey.currentState?.reset();
    for (final controller in _baseControllers) {
      controller.clear();
    }
    selectedWeekendDays.clear();
    for (final line in socialSecurityCeilings) {
      line.dispose();
    }
    socialSecurityCeilings.clear();
    for (final bracket in incomeTaxBrackets) {
      bracket.dispose();
    }
    incomeTaxBrackets.clear();
  }

  List<TextEditingController> get _baseControllers => [
    name,
    paidSickLeaveDays,
    halfPaidSickLeaveDays,
    unpaidSickLeaveDays,
    maternityLeaveDays,
    paternityLeaveDays,
    compassionateLeaveDays,
    normalOvertimeHours,
    holidayOvertimeHours,
    gratuityFirstFiveYears,
    gratuityAfterFiveYears,
    serviceTaxPercentage,
    incomeTaxPercentage,
    incomeTaxCeiling,
  ];

  void _openLogin() => Get.offAllNamed(AppRoutes.login);

  @override
  void onClose() {
    nameFilter.dispose();
    for (final controller in _baseControllers) {
      controller.dispose();
    }
    for (final line in socialSecurityCeilings) {
      line.dispose();
    }
    for (final bracket in incomeTaxBrackets) {
      bracket.dispose();
    }
    super.onClose();
  }
}
