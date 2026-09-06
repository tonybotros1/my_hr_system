import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/users/user_model.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_session_service.dart';
import '../../services/authenticated_api_service.dart';
import '../../services/hr_access_service.dart';
import '../../utils/app_date_utils.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';

class UsersController extends GetxController {
  UsersController({AuthenticatedApiService? api}) : _apiOverride = api;

  final AuthenticatedApiService? _apiOverride;
  AuthenticatedApiService get _api =>
      _apiOverride ?? Get.find<AuthenticatedApiService>();
  AuthSessionService get _session => Get.find<AuthSessionService>();

  final formKey = GlobalKey<FormState>();
  late final TextEditingController searchController;
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController expiryController;

  final users = <UserModel>[].obs;
  final activeQuery = ''.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final mutatingUserId = RxnString();
  final listError = RxnString();
  final selectedUser = Rxn<UserModel>();
  final isAdmin = false.obs;
  final obscurePassword = true.obs;
  final pageIndex = 0.obs;
  final pageSize = 10.obs;
  final selectedHrScreens = <String>{}.obs;

  String? _hrRoleId;
  String? _currentUserId;

  bool get isEditing => selectedUser.value != null;
  List<HrScreenDefinition> get availableHrScreens =>
      HrAccessPolicy.supportedScreens;
  bool get allHrScreensSelected =>
      selectedHrScreens.length == availableHrScreens.length;
  List<String> get selectedHrScreenRoutes => availableHrScreens
      .where((screen) => selectedHrScreens.contains(screen.routeName))
      .map((screen) => screen.routeName)
      .toList(growable: false);

  List<UserModel> get filteredUsers {
    final query = activeQuery.value.trim().toLowerCase();
    if (query.isEmpty) return List<UserModel>.unmodifiable(users);
    return users
        .where(
          (user) =>
              user.userName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  List<UserModel> get visibleUsers {
    final values = filteredUsers;
    final start = pageIndex.value * pageSize.value;
    if (start >= values.length) return const <UserModel>[];
    final end = (start + pageSize.value).clamp(0, values.length);
    return values.sublist(start, end);
  }

  int get rowStart =>
      filteredUsers.isEmpty ? 0 : (pageIndex.value * pageSize.value) + 1;
  int get rowEnd => filteredUsers.isEmpty
      ? 0
      : ((pageIndex.value + 1) * pageSize.value).clamp(0, filteredUsers.length);
  bool get canGoPrevious => pageIndex.value > 0;
  bool get canGoNext => rowEnd < filteredUsers.length;

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    expiryController = TextEditingController();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    _currentUserId = await _session.readUserId();
    await Future.wait([fetchUsers(), _loadHrRole()]);
  }

  bool isCurrentUser(UserModel user) => user.id == _currentUserId;

  Future<void> fetchUsers() async {
    if (isLoading.value) return;
    isLoading.value = true;
    listError.value = null;
    try {
      final response = await _api.getJson('/users/get_all_users');
      final rawUsers = response['users'];
      if (rawUsers is! List) throw const FormatException('Missing users');
      final loaded =
          rawUsers
              .whereType<Map>()
              .map(
                (item) => UserModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .where((user) => user.id.isNotEmpty)
              .toList(growable: false)
            ..sort(
              (first, second) => first.userName.toLowerCase().compareTo(
                second.userName.toLowerCase(),
              ),
            );
      users.assignAll(loaded);
      _clampPage();
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      listError.value = error.message;
    } on FormatException {
      listError.value = 'The server returned invalid user data.';
    } catch (_) {
      listError.value = 'Users could not be loaded.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadHrRole() async {
    try {
      final response = await _api.getJson('/responsibilities/get_all_roles');
      final roles = response['roles'];
      if (roles is! List) return;
      for (final rawRole in roles.whereType<Map>()) {
        final role = Map<String, dynamic>.from(rawRole);
        final menuName = _normalize(role['menu_name']?.toString() ?? '');
        final roleName = _normalize(role['role_name']?.toString() ?? '');
        if (_isHrName(menuName) || _isHrName(roleName)) {
          final id = role['_id']?.toString().trim() ?? '';
          if (id.isNotEmpty) {
            _hrRoleId = id;
            return;
          }
        }
      }
    } on SessionExpiredException {
      _openLogin();
    } catch (_) {
      // Saving a new user retries this lookup and shows a focused error.
    }
  }

  void findUsers() {
    activeQuery.value = searchController.text.trim();
    pageIndex.value = 0;
  }

  void clearFilters() {
    searchController.clear();
    activeQuery.value = '';
    pageIndex.value = 0;
  }

  void prepareNewUser() {
    selectedUser.value = null;
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    expiryController.text = formatUserDate(
      DateTime.now().add(const Duration(days: 365)),
    );
    isAdmin.value = false;
    selectAllHrScreens();
    obscurePassword.value = true;
  }

  void prepareExistingUser(UserModel user) {
    selectedUser.value = user;
    nameController.text = user.userName;
    emailController.text = user.email;
    passwordController.clear();
    expiryController.text = formatUserDate(user.expiryDate);
    isAdmin.value = user.isAdmin;
    final savedAccess = user.hrScreenAccess;
    if (savedAccess == null) {
      selectAllHrScreens();
    } else {
      final normalizedAccess = savedAccess
          .map(AppRoutes.normalizeMenuRoute)
          .toSet();
      selectedHrScreens.assignAll(
        availableHrScreens
            .where(
              (screen) => normalizedAccess.contains(
                AppRoutes.normalizeMenuRoute(screen.routeName),
              ),
            )
            .map((screen) => screen.routeName),
      );
    }
    obscurePassword.value = true;
  }

  void togglePasswordVisibility() => obscurePassword.toggle();

  void toggleHrScreen(String routeName) {
    if (selectedHrScreens.contains(routeName)) {
      selectedHrScreens.remove(routeName);
    } else {
      selectedHrScreens.add(routeName);
    }
  }

  void selectAllHrScreens() {
    selectedHrScreens.assignAll(
      availableHrScreens.map((screen) => screen.routeName),
    );
  }

  void clearHrScreens() {
    selectedHrScreens.clear();
  }

  Future<bool> saveUser() async {
    if (isSaving.value || !(formKey.currentState?.validate() ?? false)) {
      return false;
    }
    isSaving.value = true;
    try {
      final existing = selectedUser.value;
      final body = <String, dynamic>{
        'user_name': nameController.text.trim(),
        'is_admin': isAdmin.value,
        'expiry_date': userExpiryToIso(expiryController.text),
        'hr_screen_access': selectedHrScreenRoutes,
      };

      Map<String, dynamic> response;
      if (existing == null) {
        if (_hrRoleId == null) await _loadHrRole();
        final hrRoleId = _hrRoleId;
        if (hrRoleId == null || hrRoleId.isEmpty) {
          await showError(
            'The HR responsibility could not be found. Please try again.',
          );
          return false;
        }
        body.addAll({
          'email': emailController.text.trim().toLowerCase(),
          'password': passwordController.text,
          'roles': [hrRoleId],
          'branches': <String>[],
          'primary_branch': null,
        });
        response = await _api.postJson('/users/add_new_user', body: body);
        final rawUser = response['user'];
        if (rawUser is! Map) {
          await fetchUsers();
        } else {
          _upsert(UserModel.fromJson(Map<String, dynamic>.from(rawUser)));
        }
      } else {
        final password = passwordController.text;
        if (password.isNotEmpty) body['password'] = password;
        response = await _api.patchJson(
          '/users/update_user/${existing.id}',
          body: body,
        );
        if (response['_id'] == null) {
          await fetchUsers();
        } else {
          _upsert(UserModel.fromJson(response));
        }
      }
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } on FormatException {
      await showError('The server returned invalid user data.');
    } catch (_) {
      await showError('The user could not be saved.');
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  Future<bool> deleteUser(UserModel user) async {
    if (mutatingUserId.value != null) return false;
    mutatingUserId.value = user.id;
    try {
      await _api.deleteJson('/users/remove_user/${user.id}');
      users.removeWhere((item) => item.id == user.id);
      _clampPage();
      return true;
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The user could not be removed.');
    } finally {
      mutatingUserId.value = null;
    }
    return false;
  }

  Future<void> changeStatus(UserModel user, bool status) async {
    if (mutatingUserId.value != null) return;
    mutatingUserId.value = user.id;
    try {
      await _api.patchJsonValue(
        '/users/change_user_status/${user.id}',
        body: status,
      );
      _upsert(user.copyWith(status: status));
    } on SessionExpiredException {
      _openLogin();
    } on ApiRequestException catch (error) {
      await showError(error.message);
    } catch (_) {
      await showError('The user status could not be changed.');
    } finally {
      mutatingUserId.value = null;
    }
  }

  void schedulePageSize(int rows) {
    if (rows == pageSize.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed || rows == pageSize.value) return;
      pageSize.value = rows;
      _clampPage();
    });
  }

  void previousPage() {
    if (canGoPrevious) pageIndex.value--;
  }

  void nextPage() {
    if (canGoNext) pageIndex.value++;
  }

  String? requiredText(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required.'
        : null;
  }

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'This field is required.';
    if (!GetUtils.isEmail(email)) return 'Enter a valid email address.';
    return null;
  }

  String? validatePassword(String? value) {
    if (isEditing && (value == null || value.isEmpty)) return null;
    if (value == null || value.isEmpty) return 'This field is required.';
    return null;
  }

  String? validateExpiryDate(String? value) {
    final date = parseAppDate(value?.trim() ?? '');
    if (date == null) return 'Select an expiry date.';
    final today = DateUtils.dateOnly(DateTime.now());
    if (!DateUtils.dateOnly(date).isAfter(today)) {
      return 'Expiry date must be after today.';
    }
    return null;
  }

  Future<void> showError(String message) {
    return showAppAlertDialog(
      title: 'Could not complete the request',
      message: message,
      kind: AppAlertKind.error,
    );
  }

  void _upsert(UserModel user) {
    final index = users.indexWhere((item) => item.id == user.id);
    if (index < 0) {
      users.add(user);
    } else {
      users[index] = user;
    }
    users.sort(
      (first, second) =>
          first.userName.toLowerCase().compareTo(second.userName.toLowerCase()),
    );
    users.refresh();
    _clampPage();
  }

  void _clampPage() {
    final lastPage = filteredUsers.isEmpty
        ? 0
        : (filteredUsers.length - 1) ~/ pageSize.value;
    if (pageIndex.value > lastPage) pageIndex.value = lastPage;
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  }

  static bool _isHrName(String value) {
    return value == 'hr' ||
        value == 'humanresource' ||
        value == 'humanresources' ||
        value == 'humanresourcemanagement';
  }

  void _openLogin() => Get.offAllNamed(AppRoutes.login);

  @override
  void onClose() {
    searchController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    expiryController.dispose();
    super.onClose();
  }
}
