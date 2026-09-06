import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/employee_controllers/employees_controller.dart';
import '../../models/employees/employee_model.dart';
import '../../routes/app_routes.dart';
import '../../services/browser_dialog_history.dart';
import '../../services/authenticated_api_service.dart';
import '../../services/hr_access_service.dart';
import '../dialogs/app_alert_dialog.dart';
import '../drop_down_menu.dart';
import '../form_fields/app_date_form_field.dart';
import '../form_fields/app_text_form_field.dart';
import 'employee_record_dialog.dart';
import 'employee_records_table.dart';
import 'employee_documents_dialog.dart';
import 'employee_lookup_values_dialog.dart';
import 'employee_utility_dialog.dart';

bool _employeeWorkspaceRouteActive = false;

Future<void> showEmployeeWorkspaceDialog(BuildContext context) async {
  if (_employeeWorkspaceRouteActive ||
      Get.currentRoute == AppRoutes.employeeWorkspace) {
    return;
  }
  _employeeWorkspaceRouteActive = true;
  try {
    final employeeId = Get.find<EmployeesController>().currentEmployeeId;
    if (employeeId.isEmpty) {
      await Get.toNamed<void>(AppRoutes.employeeWorkspace);
    } else {
      await Get.toNamed<void>(
        AppRoutes.employeeWorkspace,
        parameters: <String, String>{'employeeId': employeeId},
      );
    }
  } finally {
    _employeeWorkspaceRouteActive = false;
  }
}

class EmployeeWorkspaceRoute extends StatefulWidget {
  const EmployeeWorkspaceRoute({super.key});

  @override
  State<EmployeeWorkspaceRoute> createState() => _EmployeeWorkspaceRouteState();
}

class _EmployeeWorkspaceRouteState extends State<EmployeeWorkspaceRoute> {
  final _formKey = GlobalKey<FormState>();
  late Future<_WorkspacePreparation> _preparation;

  @override
  void initState() {
    super.initState();
    _preparation = _prepare();
  }

  Future<_WorkspacePreparation> _prepare() async {
    final requestedEmployeeId = Get.parameters['employeeId']?.trim() ?? '';
    try {
      final accessService = Get.find<HrAccessService>();
      final access =
          accessService.currentAccess.value ?? await accessService.load();
      if (!access.hasHrResponsibility || !access.canOpenRoute('/employees')) {
        return const _WorkspacePreparation.denied();
      }

      final employeesController = Get.find<EmployeesController>();
      if (requestedEmployeeId.isEmpty) {
        employeesController.beginNewEmployee();
        return const _WorkspacePreparation.ready();
      }
      if (employeesController.currentEmployeeId == requestedEmployeeId) {
        return const _WorkspacePreparation.ready();
      }
      final loaded = await employeesController.loadEmployee(
        requestedEmployeeId,
      );
      return loaded
          ? const _WorkspacePreparation.ready()
          : const _WorkspacePreparation.failed(
              'The employee could not be restored. Return to Employees and try again.',
            );
    } on SessionExpiredException {
      Get.offAllNamed(AppRoutes.login);
      return const _WorkspacePreparation.navigating();
    } on ApiRequestException catch (error) {
      return _WorkspacePreparation.failed(error.message);
    } catch (_) {
      return const _WorkspacePreparation.failed(
        'The employee workspace could not be loaded. Please try again.',
      );
    }
  }

  void _retry() {
    setState(() => _preparation = _prepare());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_WorkspacePreparation>(
      future: _preparation,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _EmployeeWorkspaceLoading();
        }
        final preparation =
            snapshot.data ??
            const _WorkspacePreparation.failed(
              'The employee workspace could not be loaded.',
            );
        return switch (preparation.status) {
          _WorkspacePreparationStatus.ready => _buildWorkspace(),
          _WorkspacePreparationStatus.denied => _EmployeeWorkspaceDenied(
            onClose: () => _closeEmployeeWorkspace(context),
          ),
          _WorkspacePreparationStatus.failed => _EmployeeWorkspaceFailure(
            message: preparation.message,
            onRetry: _retry,
            onClose: () => _closeEmployeeWorkspace(context),
          ),
          _WorkspacePreparationStatus.navigating =>
            const _EmployeeWorkspaceLoading(),
        };
      },
    );
  }

  Widget _buildWorkspace() {
    return ColoredBox(
      color: AppColors.dialogScrim,
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.sm),
        clipBehavior: Clip.antiAlias,
        backgroundColor: AppColors.mainCanvas,
        elevation: 24,
        shadowColor: Colors.black.withValues(alpha: 0.22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.editor),
        ),
        child: SizedBox.expand(
          key: const ValueKey('employee-workspace-surface'),
          child: Column(
            children: [
              _WorkspaceHeader(formKey: _formKey),
              Expanded(child: _WorkspaceBody(formKey: _formKey)),
            ],
          ),
        ),
      ),
    );
  }
}

enum _WorkspacePreparationStatus { ready, denied, failed, navigating }

class _WorkspacePreparation {
  const _WorkspacePreparation.ready()
    : status = _WorkspacePreparationStatus.ready,
      message = '';
  const _WorkspacePreparation.denied()
    : status = _WorkspacePreparationStatus.denied,
      message = '';
  const _WorkspacePreparation.failed(this.message)
    : status = _WorkspacePreparationStatus.failed;
  const _WorkspacePreparation.navigating()
    : status = _WorkspacePreparationStatus.navigating,
      message = '';

  final _WorkspacePreparationStatus status;
  final String message;
}

class _EmployeeWorkspaceLoading extends StatelessWidget {
  const _EmployeeWorkspaceLoading();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('employee-workspace-loading'),
      color: AppColors.mainCanvas,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmployeeWorkspaceFailure extends StatelessWidget {
  const _EmployeeWorkspaceFailure({
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.mainCanvas,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: AppColors.iconMuted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  OutlinedButton(
                    onPressed: onClose,
                    child: const Text('Close'),
                  ),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _closeEmployeeWorkspace(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop<void>();
  } else {
    Get.offAllNamed(AppRoutes.employees);
  }
}

class _EmployeeWorkspaceDenied extends StatelessWidget {
  const _EmployeeWorkspaceDenied({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.mainCanvas,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 42,
                color: AppColors.iconMuted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You do not have access to Employees.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: onClose, child: const Text('Close')),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceHeader extends GetView<EmployeesController> {
  const _WorkspaceHeader({required this.formKey});

  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.primaryDark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The full action set needs more room than the form itself. Stack it
          // below the identity before labels can overflow at laptop widths.
          final compact = constraints.maxWidth < 1320;
          final identity = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.badge_outlined, color: Colors.white, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Employees',
                style: AppTextStyles.heading(
                  fontSize: 19,
                ).copyWith(color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Obx(() {
                final periods = controller.availablePeriods;
                final current =
                    periods.contains(controller.selectedPeriod.value)
                    ? controller.selectedPeriod.value
                    : periods.first;
                return Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.field),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: current,
                      icon: controller.isLoadingPeriod.value
                          ? const SizedBox.square(
                              dimension: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_drop_down_rounded),
                      items: periods
                          .map(
                            (period) => DropdownMenuItem(
                              value: period,
                              child: Text(period),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: controller.isLoadingPeriod.value
                          ? null
                          : (value) async {
                              if (value != null) {
                                await controller.setPeriod(value);
                              }
                            },
                    ),
                  ),
                );
              }),
            ],
          );
          final actions = _WorkspaceActions(compact: compact, formKey: formKey);
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: AppSpacing.xs),
                actions,
              ],
            );
          }
          return Row(children: [identity, const Spacer(), actions]);
        },
      ),
    );
  }
}

class _WorkspaceActions extends GetView<EmployeesController> {
  const _WorkspaceActions({required this.compact, required this.formKey});

  final bool compact;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final savedEmployee = controller.isEditing;
      final buttonColor = Colors.white.withValues(alpha: 0.94);
      final actions = <Widget>[
        TextButton(
          onPressed: controller.isSaving.value
              ? null
              : () => controller.saveEmployee(formKey),
          style: TextButton.styleFrom(
            foregroundColor: buttonColor,
            disabledForegroundColor: Colors.white54,
          ),
          child: controller.isSaving.value
              ? const SizedBox.square(
                  dimension: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
        _HeaderDivider(compact: compact),
        _HeaderAction(
          label: 'Leaves',
          enabled: savedEmployee,
          onTap: () => showEmployeeUtilityDialog(
            context,
            kind: EmployeeRecordKind.leave,
          ),
        ),
        _HeaderDot(compact: compact),
        _HeaderAction(
          label: compact ? 'Contacts' : 'Contacts and Relatives',
          enabled: savedEmployee,
          onTap: () => showEmployeeUtilityDialog(
            context,
            kind: EmployeeRecordKind.contactRelative,
          ),
        ),
        _HeaderDot(compact: compact),
        _HeaderAction(
          label: compact ? 'Documents' : 'Document of Record',
          enabled: savedEmployee,
          onTap: () => showEmployeeDocumentsDialog(context),
        ),
        _HeaderDivider(compact: compact),
        IconButton(
          tooltip: 'Close employee workspace',
          onPressed: controller.isSaving.value
              ? null
              : () => _closeEmployeeWorkspace(context),
          style: IconButton.styleFrom(foregroundColor: Colors.white),
          icon: const Icon(Icons.close_rounded),
        ),
      ];
      return compact
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: actions),
            )
          : Row(mainAxisSize: MainAxisSize.min, children: actions);
    });
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: enabled ? onTap : null,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
      ),
      child: Text(label),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: compact ? 2 : AppSpacing.xs),
    child: const Text('|', style: TextStyle(color: Colors.white54)),
  );
}

class _HeaderDot extends StatelessWidget {
  const _HeaderDot({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 3),
    child: const Text('•', style: TextStyle(color: Colors.white54)),
  );
}

class _EmployeeFormFocusNodes {
  final fullName = FocusNode(debugLabel: 'employee.fullName');
  final countryOfBirth = FocusNode(debugLabel: 'employee.countryOfBirth');
  final placeOfBirth = FocusNode(debugLabel: 'employee.placeOfBirth');
  final dateOfBirth = FocusNode(debugLabel: 'employee.dateOfBirth');
  final gender = FocusNode(debugLabel: 'employee.gender');
  final maritalStatus = FocusNode(debugLabel: 'employee.maritalStatus');
  final legislation = FocusNode(debugLabel: 'employee.legislation');
  final employer = FocusNode(debugLabel: 'employee.employer');
  final department = FocusNode(debugLabel: 'employee.department');
  final jobTitle = FocusNode(debugLabel: 'employee.jobTitle');
  final location = FocusNode(debugLabel: 'employee.location');
  final reportingManager = FocusNode(debugLabel: 'employee.reportingManager');
  final payroll = FocusNode(debugLabel: 'employee.payroll');
  final hireDate = FocusNode(debugLabel: 'employee.hireDate');
  final endDate = FocusNode(debugLabel: 'employee.endDate');

  void dispose() {
    fullName.dispose();
    countryOfBirth.dispose();
    placeOfBirth.dispose();
    dateOfBirth.dispose();
    gender.dispose();
    maritalStatus.dispose();
    legislation.dispose();
    employer.dispose();
    department.dispose();
    jobTitle.dispose();
    location.dispose();
    reportingManager.dispose();
    payroll.dispose();
    hireDate.dispose();
    endDate.dispose();
  }
}

class _WorkspaceBody extends StatefulWidget {
  const _WorkspaceBody({required this.formKey});

  final GlobalKey<FormState> formKey;

  @override
  State<_WorkspaceBody> createState() => _WorkspaceBodyState();
}

class _WorkspaceBodyState extends State<_WorkspaceBody> {
  final _personalPanelKey = GlobalKey();
  final _focusNodes = _EmployeeFormFocusNodes();
  double? _personalPanelHeight;

  EmployeesController get controller => Get.find<EmployeesController>();

  void _measurePersonalPanel() {
    final box = _personalPanelKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final height = box.size.height;
    if ((_personalPanelHeight ?? 0) - height > -0.5 &&
        (_personalPanelHeight ?? 0) - height < 0.5) {
      return;
    }
    if (mounted) setState(() => _personalPanelHeight = height);
  }

  @override
  void dispose() {
    _focusNodes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _measurePersonalPanel(),
    );
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Form(
        key: widget.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 1250;
              final personal = KeyedSubtree(
                key: _personalPanelKey,
                child: _PersonalInformationPanel(focusNodes: _focusNodes),
              );
              final records = SizedBox(
                height:
                    _personalPanelHeight ??
                    AppSizes.employeeOverviewPanelHeight,
                child: const _RelatedRecordsPanel(),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sideBySide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: personal),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(flex: 6, child: records),
                      ],
                    )
                  else ...[
                    personal,
                    const SizedBox(height: AppSpacing.md),
                    records,
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _AssignmentPanel(focusNodes: _focusNodes),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PersonalInformationPanel extends StatefulWidget {
  const _PersonalInformationPanel({required this.focusNodes});

  final _EmployeeFormFocusNodes focusNodes;

  @override
  State<_PersonalInformationPanel> createState() =>
      _PersonalInformationPanelState();
}

class _PersonalInformationPanelState extends State<_PersonalInformationPanel> {
  final _fieldsKey = GlobalKey();
  double? _fieldsHeight;
  bool _measurementScheduled = false;

  EmployeesController get controller => Get.find<EmployeesController>();

  void _scheduleFieldsMeasurement() {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (!mounted) return;
      final box = _fieldsKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final height = box.size.height;
      if ((_fieldsHeight ?? 0) - height > -0.5 &&
          (_fieldsHeight ?? 0) - height < 0.5) {
        return;
      }
      setState(() => _fieldsHeight = height);
    });
  }

  Widget _trackedFields() {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _scheduleFieldsMeasurement();
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: KeyedSubtree(
          key: _fieldsKey,
          child: _PersonalFields(focusNodes: widget.focusNodes),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleFieldsMeasurement();
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.tableHeader,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadii.section),
                topRight: Radius.circular(AppRadii.section),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Personal Information',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
                AnimatedBuilder(
                  animation: Listenable.merge([
                    controller.hireDate,
                    controller.endDate,
                  ]),
                  builder: (context, _) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.computedPersonType,
                      style: AppTextStyles.badge.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 660;
                final fields = _trackedFields();
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: AppSizes.employeePhotoCompactHeight,
                        child: _EmployeeImagePicker(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      fields,
                    ],
                  );
                }
                final photoHeight = math.max(
                  _fieldsHeight ?? AppSizes.employeePhotoFallbackHeight,
                  AppSizes.employeePhotoActionsHeight + 100,
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: AppSizes.employeePhotoColumnWidth,
                      height: photoHeight,
                      child: const _EmployeeImagePicker(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: fields),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeImagePicker extends GetView<EmployeesController> {
  const _EmployeeImagePicker();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bytes = controller.imageBytes.value;
      final url = controller.selectedEmployee.value?.imageUrl ?? '';
      Widget preview;
      if (bytes != null && bytes.isNotEmpty) {
        preview = Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
        );
      } else if (url.isNotEmpty) {
        preview = Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
          errorBuilder: (_, _, _) => const _ImagePlaceholder(),
        );
      } else {
        preview = const _ImagePlaceholder();
      }
      final hasImage = (bytes != null && bytes.isNotEmpty) || url.isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.softSurface,
                border: Border.all(color: AppColors.borderStrong),
                borderRadius: BorderRadius.circular(AppRadii.field),
              ),
              child: preview,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: AppSizes.employeePhotoActionsHeight,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: controller.pickImage,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      textStyle: AppTextStyles.button.copyWith(fontSize: 11.5),
                    ),
                    icon: const Icon(Icons.add_a_photo_outlined, size: 15),
                    label: Text(
                      hasImage ? 'Choose another' : 'Choose image',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasImage
                        ? () => _showEmployeeImageViewer(
                            context,
                            bytes: bytes,
                            url: url,
                            title: controller.fullName.text.trim(),
                          )
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxs,
                      ),
                      textStyle: AppTextStyles.link.copyWith(fontSize: 11.5),
                    ),
                    icon: const Icon(Icons.open_in_full_rounded, size: 14),
                    label: const Text('Open'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

Future<void> _showEmployeeImageViewer(
  BuildContext context, {
  required List<int>? bytes,
  required String url,
  required String title,
}) async {
  final size = MediaQuery.sizeOf(context);
  final dialogWidth = math.min(760, size.width - (AppSpacing.xxl * 2));
  final dialogHeight = math.min(760, size.height - (AppSpacing.xxl * 2));
  final navigator = Navigator.of(context, rootNavigator: true);
  final history = BrowserDialogHistory.open(() {
    if (navigator.canPop()) navigator.pop<void>();
  });
  try {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: AppColors.dialogScrim,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.xxl),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.section),
        ),
        child: SizedBox(
          width: dialogWidth.toDouble(),
          height: dialogHeight.toDouble(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.isEmpty ? 'Employee picture' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading(fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop<void>(),
                      tooltip: 'Close image',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ColoredBox(
                  color: AppColors.softSurface,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5,
                    child: Center(
                      child: bytes != null && bytes.isNotEmpty
                          ? Image.memory(
                              Uint8List.fromList(bytes),
                              fit: BoxFit.contain,
                            )
                          : Image.network(
                              url,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const _ImageLoadError(),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } finally {
    history.complete();
  }
}

class _ImageLoadError extends StatelessWidget {
  const _ImageLoadError();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_outlined, color: AppColors.textHint, size: 38),
        SizedBox(height: AppSpacing.xs),
        Text(
          'The image could not be opened.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, color: AppColors.textHint, size: 30),
        SizedBox(height: AppSpacing.xs),
        Text(
          'No image selected',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _PersonalFields extends GetView<EmployeesController> {
  const _PersonalFields({required this.focusNodes});

  final _EmployeeFormFocusNodes focusNodes;

  @override
  Widget build(BuildContext context) {
    return _ResponsiveFieldGrid(
      children: [
        _FieldSpan(
          span: 2,
          focusOrder: 1,
          child: AppTextFormField(
            label: 'Full Name',
            hintText: 'Employee full name',
            controller: controller.fullName,
            validator: controller.requiredText,
            focusNode: focusNodes.fullName,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => focusNodes.countryOfBirth.requestFocus(),
            textCapitalization: TextCapitalization.words,
          ),
        ),
        _FieldSpan(
          focusOrder: 2,
          child: _LookupField(
            label: 'Country of Birth',
            textController: controller.countryOfBirth,
            selectedId: controller.countryOfBirthId,
            onOpen: controller.countries,
            focusNode: focusNodes.countryOfBirth,
            nextFocusNode: focusNodes.placeOfBirth,
          ),
        ),
        _FieldSpan(
          focusOrder: 3,
          child: AppTextFormField(
            label: 'Place of Birth',
            hintText: 'Place of birth',
            controller: controller.placeOfBirth,
            focusNode: focusNodes.placeOfBirth,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => focusNodes.dateOfBirth.requestFocus(),
          ),
        ),
        _FieldSpan(
          focusOrder: 4,
          child: _DateField(
            label: 'Date of Birth',
            controller: controller.dateOfBirth,
            focusNode: focusNodes.dateOfBirth,
          ),
        ),
        _FieldSpan(
          focusOrder: 5,
          child: _LookupField(
            label: 'Gender',
            textController: controller.gender,
            selectedId: controller.genderId,
            onOpen: () => controller.listValues('GENDER'),
            focusNode: focusNodes.gender,
            nextFocusNode: focusNodes.maritalStatus,
          ),
        ),
        _FieldSpan(
          focusOrder: 6,
          child: _LookupField(
            label: 'Marital Status',
            textController: controller.maritalStatus,
            selectedId: controller.maritalStatusId,
            onOpen: () => controller.listValues('MARITAL_STATUS'),
            focusNode: focusNodes.maritalStatus,
            nextFocusNode: focusNodes.legislation,
          ),
        ),
        _FieldSpan(
          focusOrder: 7,
          child: _LookupField(
            label: 'Legislation *',
            textController: controller.legislation,
            selectedId: controller.legislationId,
            onOpen: controller.legislations,
            focusNode: focusNodes.legislation,
            nextFocusNode: focusNodes.employer,
            required: true,
          ),
        ),
      ],
    );
  }
}

class _RelatedRecordsPanel extends GetView<EmployeesController> {
  const _RelatedRecordsPanel();

  static const kinds = [
    EmployeeRecordKind.address,
    EmployeeRecordKind.nationality,
    EmployeeRecordKind.phone,
    EmployeeRecordKind.socialContact,
    EmployeeRecordKind.bankAccount,
    EmployeeRecordKind.healthCard,
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedContactTab.value;
      return Container(
        decoration: AppDecorations.contentCard,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _TabStrip(
              tabs: kinds
                  .map(
                    (kind) => _TabOption(
                      label: labelForRecordKind(kind),
                      selected: selected == kind,
                      onTap: () => controller.selectedContactTab.value = kind,
                    ),
                  )
                  .toList(growable: false),
            ),
            Container(
              height: 54,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: FilledButton(
                onPressed: controller.isEditing
                    ? () => showEmployeeRecordDialog(context, kind: selected)
                    : null,
                child: const Text('New'),
              ),
            ),
            Expanded(
              child: controller.isEditing
                  ? EmployeeRecordsTable(
                      kind: selected,
                      records: controller.recordsFor(selected),
                      deletingRecordId: controller.isDeleting.value,
                      onEdit: (record) => showEmployeeRecordDialog(
                        context,
                        kind: selected,
                        record: record,
                      ),
                      onDelete: (record) =>
                          _confirmDelete(context, selected, record),
                    )
                  : const _SaveFirstMessage(),
            ),
          ],
        ),
      );
    });
  }
}

class _AssignmentPanel extends GetView<EmployeesController> {
  const _AssignmentPanel({required this.focusNodes});

  final _EmployeeFormFocusNodes focusNodes;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedAssignmentTab.value;
      return Container(
        constraints: const BoxConstraints(minHeight: 480),
        decoration: AppDecorations.contentCard,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TabStrip(
              tabs: [
                _TabOption(
                  label: 'Assignment Information',
                  selected: selected == EmployeeRecordKind.address,
                  onTap: () => controller.selectedAssignmentTab.value =
                      EmployeeRecordKind.address,
                ),
                _TabOption(
                  label: 'Payroll Elements',
                  selected: selected == EmployeeRecordKind.payrollElement,
                  onTap: () => controller.selectedAssignmentTab.value =
                      EmployeeRecordKind.payrollElement,
                ),
                _TabOption(
                  label: 'Loan and Advances',
                  selected: selected == EmployeeRecordKind.loanAdvance,
                  onTap: () => controller.selectedAssignmentTab.value =
                      EmployeeRecordKind.loanAdvance,
                ),
              ],
            ),
            if (selected == EmployeeRecordKind.address)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _AssignmentInformation(focusNodes: focusNodes),
              )
            else
              SizedBox(
                height: 420,
                child: Column(
                  children: [
                    Container(
                      height: 56,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: FilledButton(
                        onPressed: controller.isEditing
                            ? () => showEmployeeRecordDialog(
                                context,
                                kind: selected,
                              )
                            : null,
                        child: const Text('New'),
                      ),
                    ),
                    Expanded(
                      child: controller.isEditing
                          ? EmployeeRecordsTable(
                              kind: selected,
                              records: controller.recordsFor(selected),
                              deletingRecordId: controller.isDeleting.value,
                              onEdit: (record) => showEmployeeRecordDialog(
                                context,
                                kind: selected,
                                record: record,
                              ),
                              onDelete: (record) =>
                                  _confirmDelete(context, selected, record),
                            )
                          : const _SaveFirstMessage(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _AssignmentInformation extends StatefulWidget {
  const _AssignmentInformation({required this.focusNodes});

  final _EmployeeFormFocusNodes focusNodes;

  @override
  State<_AssignmentInformation> createState() => _AssignmentInformationState();
}

class _AssignmentInformationState extends State<_AssignmentInformation> {
  final _employmentKey = GlobalKey();
  final _contractKey = GlobalKey();
  double? _equalCardHeight;
  double? _lastWidth;
  bool _measurementScheduled = false;

  void _scheduleCardMeasurement() {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (!mounted) return;
      final employmentBox = _employmentKey.currentContext?.findRenderObject();
      final contractBox = _contractKey.currentContext?.findRenderObject();
      if (employmentBox is! RenderBox || contractBox is! RenderBox) return;
      if (!employmentBox.hasSize || !contractBox.hasSize) return;
      final height = math.max(
        employmentBox.size.height,
        contractBox.size.height,
      );
      if ((_equalCardHeight ?? 0) - height > -0.5 &&
          (_equalCardHeight ?? 0) - height < 0.5) {
        return;
      }
      setState(() => _equalCardHeight = height);
    });
  }

  Widget _trackedCard(GlobalKey key, Widget child) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _scheduleCardMeasurement();
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: ConstrainedBox(
          key: key,
          constraints: BoxConstraints(minHeight: _equalCardHeight ?? 0),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleCardMeasurement();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (_lastWidth != constraints.maxWidth) {
              _lastWidth = constraints.maxWidth;
              _equalCardHeight = null;
              _scheduleCardMeasurement();
            }
            final sideBySide = constraints.maxWidth >= 1250;
            final employment = _trackedCard(
              _employmentKey,
              _EmploymentCard(focusNodes: widget.focusNodes),
            );
            final contract = _trackedCard(
              _contractKey,
              _ContractCard(focusNodes: widget.focusNodes),
            );
            if (sideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: employment),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(flex: 3, child: contract),
                ],
              );
            }
            return Column(
              children: [
                employment,
                const SizedBox(height: AppSpacing.md),
                contract,
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const _BalancesCard(),
      ],
    );
  }
}

class _EmploymentCard extends GetView<EmployeesController> {
  const _EmploymentCard({required this.focusNodes});

  final _EmployeeFormFocusNodes focusNodes;

  @override
  Widget build(BuildContext context) {
    return _SubCard(
      title: 'Employment Details',
      child: _ResponsiveFieldGrid(
        children: [
          _FieldSpan(
            focusOrder: 8,
            child: _EmploymentLookupField(
              label: 'Employer',
              focusNode: focusNodes.employer,
              nextFocusNode: focusNodes.department,
              textController: controller.employer,
              selectedId: controller.employerId,
              onOpen: () => controller.listValues('EMPLOYERS'),
              onManage: () => showEmployeeLookupValuesDialog(
                context,
                controller: controller,
                code: 'EMPLOYERS',
                title: 'Employers',
                singularTitle: 'Employer',
              ),
            ),
          ),
          _FieldSpan(
            focusOrder: 9,
            child: _EmploymentLookupField(
              label: 'Department',
              focusNode: focusNodes.department,
              nextFocusNode: focusNodes.jobTitle,
              textController: controller.department,
              selectedId: controller.departmentId,
              onOpen: () => controller.listValues('DEPARTMENTS'),
              onManage: () => showEmployeeLookupValuesDialog(
                context,
                controller: controller,
                code: 'DEPARTMENTS',
                title: 'Departments',
                singularTitle: 'Department',
              ),
            ),
          ),
          _FieldSpan(
            focusOrder: 10,
            child: _EmploymentLookupField(
              label: 'Job Title',
              focusNode: focusNodes.jobTitle,
              nextFocusNode: focusNodes.location,
              textController: controller.jobTitle,
              selectedId: controller.jobTitleId,
              onOpen: () => controller.listValues('JOBS'),
              onManage: () => showEmployeeLookupValuesDialog(
                context,
                controller: controller,
                code: 'JOBS',
                title: 'Jobs',
                singularTitle: 'Job',
              ),
            ),
          ),
          _FieldSpan(
            focusOrder: 11,
            child: _EmploymentLookupField(
              label: 'Location',
              focusNode: focusNodes.location,
              nextFocusNode: focusNodes.reportingManager,
              textController: controller.location,
              selectedId: controller.locationId,
              onOpen: () => controller.listValues('LOCATIONS'),
              onManage: () => showEmployeeLookupValuesDialog(
                context,
                controller: controller,
                code: 'LOCATIONS',
                title: 'Locations',
                singularTitle: 'Location',
              ),
            ),
          ),
          _FieldSpan(
            focusOrder: 12,
            child: _EmploymentLookupField(
              label: 'Reporting Manager',
              focusNode: focusNodes.reportingManager,
              nextFocusNode: focusNodes.payroll,
              textController: controller.reportingManager,
              selectedId: controller.reportingManagerId,
              onOpen: () => controller.listValues('REPORTING_MANAGER'),
              onManage: () => showEmployeeLookupValuesDialog(
                context,
                controller: controller,
                code: 'REPORTING_MANAGER',
                title: 'Reporting Managers',
                singularTitle: 'Reporting Manager',
              ),
            ),
          ),
          _FieldSpan(
            focusOrder: 13,
            child: _EmploymentLookupField(
              label: 'Payroll *',
              focusNode: focusNodes.payroll,
              nextFocusNode: focusNodes.hireDate,
              textController: controller.payroll,
              selectedId: controller.payrollId,
              onOpen: controller.payrolls,
              required: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractCard extends GetView<EmployeesController> {
  const _ContractCard({required this.focusNodes});

  final _EmployeeFormFocusNodes focusNodes;

  @override
  Widget build(BuildContext context) {
    return _SubCard(
      title: 'Contract Dates',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DateField(
                  label: 'Hire Date',
                  controller: controller.hireDate,
                  focusNode: focusNodes.hireDate,
                  focusOrder: 14,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateField(
                  label: 'End Date',
                  controller: controller.endDate,
                  focusNode: focusNodes.endDate,
                  focusOrder: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedBuilder(
            animation: Listenable.merge([
              controller.hireDate,
              controller.endDate,
            ]),
            builder: (context, _) {
              final start = EmployeesController.parseDateInput(
                controller.hireDate.text,
              );
              final end =
                  EmployeesController.parseDateInput(controller.endDate.text) ??
                  DateTime.now();
              final days = start == null
                  ? 0
                  : end.difference(start).inDays.abs();
              final totalMonths = days ~/ 30;
              final years = totalMonths ~/ 12;
              final months = totalMonths % 12;
              final remainingDays = days % 30;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.softSurface,
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DurationValue(value: '$years', label: 'Years'),
                    _DurationValue(value: '$months', label: 'Months'),
                    _DurationValue(value: '$remainingDays', label: 'Days'),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BalancesCard extends GetView<EmployeesController> {
  const _BalancesCard();

  @override
  Widget build(BuildContext context) {
    return _SubCard(
      title: 'Assignment Balances',
      child: Obx(() {
        final balances = controller.assignmentBalances;
        if (!controller.isEditing) return const _SaveFirstMessage(height: 110);
        if (balances.isEmpty) {
          return SizedBox(
            height: 110,
            child: Center(
              child: Text(
                'No assignment balances for ${controller.selectedPeriod.value}.',
                style: AppTextStyles.listCount,
              ),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 1000
                ? (constraints.maxWidth - AppSpacing.md * 3) / 4
                : constraints.maxWidth >= 560
                ? (constraints.maxWidth - AppSpacing.md) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: balances
                  .map(
                    (balance) => SizedBox(
                      width: cardWidth,
                      child: _BalanceTile(balance: balance),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        );
      }),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.balance});

  final EmployeeRecord balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            constraints: const BoxConstraints(minHeight: 104),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadii.field),
                bottomLeft: Radius.circular(AppRadii.field),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    balance.text('name'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.checkboxLabel,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    balance.text('balance_dimension'),
                    style: AppTextStyles.listCount.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    balance.number('balance').toStringAsFixed(2),
                    style: AppTextStyles.heading(
                      fontSize: 21,
                    ).copyWith(color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationValue extends StatelessWidget {
  const _DurationValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.heading(fontSize: 20)),
        Text(label, style: AppTextStyles.listCount.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _SubCard extends StatelessWidget {
  const _SubCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: AppColors.tableHeader,
            child: Text(title, style: AppTextStyles.sectionTitle),
          ),
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
        ],
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.tabs});

  final List<_TabOption> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: const Color(0xFF8BA5A3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const minimumTabWidth = 118.0;
          final minimumWidth = tabs.length * minimumTabWidth;
          if (constraints.maxWidth >= minimumWidth) {
            return Row(
              children: tabs
                  .map((tab) => Expanded(child: tab))
                  .toList(growable: false),
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: minimumWidth,
              child: Row(
                children: tabs
                    .map((tab) => SizedBox(width: minimumTabWidth, child: tab))
                    .toList(growable: false),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabOption extends StatelessWidget {
  const _TabOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.warning : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.checkboxLabel.copyWith(
            color: selected ? const Color(0xFFFFE36B) : Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LookupField extends StatelessWidget {
  const _LookupField({
    required this.label,
    required this.textController,
    required this.selectedId,
    required this.onOpen,
    required this.focusNode,
    required this.nextFocusNode,
    this.required = false,
  });

  final String label;
  final TextEditingController textController;
  final RxString selectedId;
  final Future<Map<String, dynamic>> Function() onOpen;
  final FocusNode focusNode;
  final FocusNode nextFocusNode;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      selectedId.value;
      return LayoutBuilder(
        builder: (context, constraints) => CustomDropdown(
          width: constraints.maxWidth,
          hintText: label,
          textcontroller: textController.text,
          showedSelectedName: 'name',
          validator: required,
          focusNode: focusNode,
          nextFocusNode: nextFocusNode,
          onOpen: onOpen,
          onDelete: () {
            selectedId.value = '';
            textController.clear();
          },
          onChanged: (key, value) {
            selectedId.value = key;
            textController.text = employeeString((value as Map)['name']);
          },
        ),
      );
    });
  }
}

class _EmploymentLookupField extends StatelessWidget {
  const _EmploymentLookupField({
    required this.label,
    required this.textController,
    required this.selectedId,
    required this.onOpen,
    required this.focusNode,
    required this.nextFocusNode,
    this.onManage,
    this.required = false,
  });

  final String label;
  final TextEditingController textController;
  final RxString selectedId;
  final Future<Map<String, dynamic>> Function() onOpen;
  final FocusNode focusNode;
  final FocusNode nextFocusNode;
  final VoidCallback? onManage;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _LookupField(
            label: label,
            textController: textController,
            selectedId: selectedId,
            onOpen: onOpen,
            focusNode: focusNode,
            nextFocusNode: nextFocusNode,
            required: required,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(top: 23),
          child: ExcludeFocus(
            child: SizedBox.square(
              dimension: AppSizes.inputMinHeight,
              child: onManage == null
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Manage $label',
                      onPressed: onManage,
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        backgroundColor: AppColors.primaryLight,
                        hoverColor: AppColors.segmentBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.field),
                          side: const BorderSide(color: AppColors.borderStrong),
                        ),
                      ),
                      icon: const Icon(Icons.add_card_outlined, size: 18),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.controller,
    required this.focusNode,
    this.focusOrder,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final double? focusOrder;

  @override
  Widget build(BuildContext context) {
    final field = AppDateFormField(
      label: label,
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.next,
      firstDate: DateTime(1940),
      lastDate: DateTime(2200),
    );
    final order = focusOrder;
    return order == null
        ? field
        : FocusTraversalOrder(order: NumericFocusOrder(order), child: field);
  }
}

class _ResponsiveFieldGrid extends StatelessWidget {
  const _ResponsiveFieldGrid({required this.children});

  final List<_FieldSpan> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820
            ? 3
            : constraints.maxWidth >= 500
            ? 2
            : 1;
        final unitWidth =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: children
              .map((field) {
                final span = math.min(field.span, columns);
                return SizedBox(
                  width: unitWidth * span + AppSpacing.md * (span - 1),
                  child: field.focusOrder == null
                      ? field.child
                      : FocusTraversalOrder(
                          order: NumericFocusOrder(field.focusOrder!),
                          child: field.child,
                        ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

class _FieldSpan {
  const _FieldSpan({required this.child, this.span = 1, this.focusOrder});

  final Widget child;
  final int span;
  final double? focusOrder;
}

class _SaveFirstMessage extends StatelessWidget {
  const _SaveFirstMessage({this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Save the employee first to add related records.',
            textAlign: TextAlign.center,
            style: AppTextStyles.listCount,
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  EmployeeRecordKind kind,
  EmployeeRecord record,
) async {
  final controller = Get.find<EmployeesController>();
  final confirmed = await showAppConfirmationDialog(
    context,
    title: 'Delete this record?',
    message: 'This action permanently removes the selected employee record.',
    confirmLabel: 'Delete',
    destructive: true,
  );
  if (confirmed) await controller.deleteRecord(kind, record);
}
