import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/payroll/public_holiday_model.dart';
import '../../routes/app_routes.dart';
import '../../services/authenticated_api_service.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';

class PublicHolidaysController extends GetxController {
  PublicHolidaysController({AuthenticatedApiService? api}) : _apiOverride = api;

  final AuthenticatedApiService? _apiOverride;
  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();

  late final TextEditingController yearController;
  final selectedYear = DateTime.now().year.obs;
  final selectedLegislationId = RxnString();
  final legislationOptions = <PublicHolidayLegislationOption>[].obs;
  final holidays = <String, PublicHolidayModel>{}.obs;

  final isLoading = false.obs;
  final isLoadingOptions = false.obs;
  final isSaving = false.obs;
  final isDeleting = false.obs;
  final listError = RxnString();

  bool _legislationsLoaded = false;

  static const monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const weekdayNames = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void onInit() {
    super.onInit();
    yearController = TextEditingController(text: '${selectedYear.value}');
    unawaited(loadLegislationOptions());
  }

  Map<String, dynamic> get legislationDropdownItems {
    return {
      for (final option in legislationOptions)
        option.id: {'_id': option.id, 'name': option.name},
    };
  }

  String get selectedLegislationName {
    final id = selectedLegislationId.value;
    if (id == null || id.isEmpty) return '';
    for (final option in legislationOptions) {
      if (option.id == id) return option.name;
    }
    return '';
  }

  int get holidayCount => holidays.length;

  PublicHolidayModel? holidayFor(DateTime date) {
    return holidays[publicHolidayDateKey(date)];
  }

  List<DateTime?> daysForMonth(int month) {
    final year = selectedYear.value;
    final firstDay = DateTime(year, month);
    final totalDays = DateUtils.getDaysInMonth(year, month);
    final leading = firstDay.weekday - DateTime.monday;
    final values = <DateTime?>[
      ...List<DateTime?>.filled(leading, null),
      ...List<DateTime?>.generate(
        totalDays,
        (index) => DateTime(year, month, index + 1),
      ),
    ];
    return <DateTime?>[
      ...values,
      ...List<DateTime?>.filled(42 - values.length, null),
    ];
  }

  Future<Map<String, dynamic>> getLegislationsForDropdown() async {
    final loaded = await loadLegislationOptions(forceRefresh: true);
    return loaded ? legislationDropdownItems : <String, dynamic>{};
  }

  Future<bool> loadLegislationOptions({bool forceRefresh = false}) async {
    if (_legislationsLoaded && !forceRefresh) return true;
    if (isLoadingOptions.value) return false;
    isLoadingOptions.value = true;
    try {
      final response = await _api.getJson('/legislation/get_all_legislations');
      final rawOptions = response['all_legislations'];
      if (rawOptions is! List) {
        throw const FormatException('Missing legislations');
      }
      legislationOptions.assignAll(
        rawOptions
            .whereType<Map>()
            .map(
              (item) => PublicHolidayLegislationOption.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((option) => option.id.isNotEmpty && option.name.isNotEmpty),
      );
      _legislationsLoaded = true;
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The legislation values could not be loaded.');
    } finally {
      isLoadingOptions.value = false;
    }
    return false;
  }

  void selectLegislation(String id) {
    if (selectedLegislationId.value == id) return;
    selectedLegislationId.value = id;
    holidays.clear();
    listError.value = null;
  }

  void clearLegislation() {
    selectedLegislationId.value = null;
    holidays.clear();
    listError.value = null;
  }

  Future<void> findHolidays() async {
    if (isLoading.value) return;
    final year = int.tryParse(yearController.text.trim());
    if (year == null || year < 2000 || year > 2100) {
      await showError('Enter a year between 2000 and 2100.');
      return;
    }
    final legislationId = selectedLegislationId.value ?? '';
    if (legislationId.isEmpty) {
      await showError('Select a legislation before finding holidays.');
      return;
    }

    selectedYear.value = year;
    isLoading.value = true;
    listError.value = null;
    try {
      final response = await _api.postJson(
        '/public_holidays/get_all_holidays',
        body: {'legislation': legislationId, 'year': year},
      );
      final rawHolidays = response['holidays'];
      if (rawHolidays is! List) {
        throw const FormatException('Missing public holidays');
      }
      final loaded = <String, PublicHolidayModel>{};
      for (final item in rawHolidays.whereType<Map>()) {
        final holiday = PublicHolidayModel.fromJson(
          Map<String, dynamic>.from(item),
        );
        loaded[publicHolidayDateKey(holiday.date)] = holiday;
      }
      holidays.assignAll(loaded);
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      listError.value = error.message;
      await showError(error.message);
    } on FormatException {
      listError.value = 'The server returned invalid public-holiday data.';
      await showError(listError.value!);
    } catch (_) {
      listError.value = 'Public holidays could not be loaded.';
      await showError(listError.value!);
    } finally {
      isLoading.value = false;
    }
  }

  void clearFilters() {
    final currentYear = DateTime.now().year;
    yearController.text = '$currentYear';
    selectedYear.value = currentYear;
    selectedLegislationId.value = null;
    holidays.clear();
    listError.value = null;
  }

  Future<bool> saveHoliday({
    required DateTime date,
    required String name,
    PublicHolidayModel? existing,
  }) async {
    if (isSaving.value) return false;
    final legislationId = selectedLegislationId.value ?? '';
    if (legislationId.isEmpty) {
      await showError('Select a legislation before saving a holiday.');
      return false;
    }
    final holidayName = name.trim();
    if (holidayName.isEmpty) {
      await showError('Enter a holiday name before saving.');
      return false;
    }

    isSaving.value = true;
    try {
      final request = PublicHolidayModel(
        id: existing?.id ?? '',
        name: holidayName,
        date: DateUtils.dateOnly(date),
        legislationId: legislationId,
      );
      final Map<String, dynamic> response;
      final String responseKey;
      if (existing == null) {
        response = await _api.postJson(
          '/public_holidays/add_new_holiday',
          body: request.toRequestJson(),
        );
        responseKey = 'added_holiday';
      } else {
        response = await _api.patchJson(
          '/public_holidays/update_holiday/${existing.id}',
          body: request.toRequestJson(),
        );
        responseKey = 'updated_holiday';
      }

      final rawSaved = response[responseKey];
      if (rawSaved is! Map) {
        throw const FormatException('Missing saved holiday');
      }
      final backendHoliday = PublicHolidayModel.fromJson(
        Map<String, dynamic>.from(rawSaved),
      );
      final saved = backendHoliday.copyWith(
        id: backendHoliday.id.isEmpty ? existing?.id : backendHoliday.id,
        name: backendHoliday.name.isEmpty ? request.name : backendHoliday.name,
        legislationId: backendHoliday.legislationId.isEmpty
            ? legislationId
            : backendHoliday.legislationId,
      );
      if (existing != null) {
        holidays.remove(publicHolidayDateKey(existing.date));
      }
      if (saved.date.year == selectedYear.value) {
        holidays[publicHolidayDateKey(saved.date)] = saved;
      }
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server returned invalid public-holiday data.');
    } catch (_) {
      await showError('The public holiday could not be saved.');
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  Future<bool> deleteHoliday(PublicHolidayModel holiday) async {
    if (isDeleting.value || holiday.id.isEmpty) return false;
    isDeleting.value = true;
    try {
      await _api.deleteJson('/public_holidays/delete_holiday/${holiday.id}');
      holidays.remove(publicHolidayDateKey(holiday.date));
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The public holiday could not be removed.');
    } finally {
      isDeleting.value = false;
    }
    return false;
  }

  Future<void> showError(String message) {
    return showAppAlertDialog(
      title: 'Could not complete the request',
      message: message,
      kind: AppAlertKind.error,
    );
  }

  void _openLogin() => Get.offAllNamed(AppRoutes.login);

  @override
  void onClose() {
    yearController.dispose();
    super.onClose();
  }
}
