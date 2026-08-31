import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/payroll_controllers/public_holidays_controller.dart';
import '../../models/payroll/public_holiday_model.dart';
import '../dialogs/app_alert_dialog.dart';
import '../form_fields/app_text_form_field.dart';

Future<void> showPublicHolidayEditorDialog(
  BuildContext context, {
  required DateTime date,
  PublicHolidayModel? holiday,
}) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierColor: AppColors.dialogScrim,
    builder: (_) =>
        _PublicHolidayEditorDialog(initialDate: date, holiday: holiday),
  );
}

class _PublicHolidayEditorDialog extends StatefulWidget {
  const _PublicHolidayEditorDialog({
    required this.initialDate,
    required this.holiday,
  });

  final DateTime initialDate;
  final PublicHolidayModel? holiday;

  @override
  State<_PublicHolidayEditorDialog> createState() =>
      _PublicHolidayEditorDialogState();
}

class _PublicHolidayEditorDialogState
    extends State<_PublicHolidayEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime selectedDate;
  late final TextEditingController dateController;
  late final TextEditingController nameController;

  PublicHolidaysController get controller =>
      Get.find<PublicHolidaysController>();

  bool get isEditing => widget.holiday != null;

  @override
  void initState() {
    super.initState();
    selectedDate = DateUtils.dateOnly(widget.initialDate);
    dateController = TextEditingController(
      text: formatPublicHolidayDate(selectedDate),
    );
    nameController = TextEditingController(text: widget.holiday?.name ?? '');
  }

  @override
  void dispose() {
    dateController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.section),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.publicHolidayDialogWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final title = Text(
                      'Public Holiday',
                      style: AppTextStyles.heading(fontSize: 21),
                    );
                    final actions = Obx(
                      () => Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            onPressed:
                                controller.isSaving.value ||
                                    controller.isDeleting.value
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textHint,
                            ),
                            child: const Text('Cancel'),
                          ),
                          if (isEditing)
                            TextButton(
                              onPressed:
                                  controller.isSaving.value ||
                                      controller.isDeleting.value
                                  ? null
                                  : _remove,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: controller.isDeleting.value
                                  ? const _DialogLoader(color: AppColors.error)
                                  : const Text('Remove'),
                            ),
                          TextButton(
                            onPressed:
                                controller.isSaving.value ||
                                    controller.isDeleting.value
                                ? null
                                : _save,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                            child: controller.isSaving.value
                                ? const _DialogLoader()
                                : const Text('Save Holiday'),
                          ),
                        ],
                      ),
                    );
                    if (constraints.maxWidth < 450) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          title,
                          const SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: Alignment.centerRight,
                            child: actions,
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: AppSpacing.sm),
                        actions,
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextFormField(
                  label: 'Date',
                  hintText: 'DD-MM-YYYY',
                  controller: dateController,
                  readOnly: true,
                  onTap: _selectDate,
                  suffixIcon: IconButton(
                    tooltip: 'Select holiday date',
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextFormField(
                  label: 'Holiday Name',
                  hintText: "e.g. New Year's Day",
                  controller: nameController,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Holiday name is required.'
                      : null,
                  onFieldSubmitted: (_) => _save(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final year = controller.selectedYear.value;
    final selected = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(year),
      lastDate: DateTime(year, 12, 31),
      helpText: 'Holiday date',
    );
    if (selected == null || !mounted) return;
    setState(() {
      selectedDate = DateUtils.dateOnly(selected);
      dateController.text = formatPublicHolidayDate(selectedDate);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final saved = await controller.saveHoliday(
      date: selectedDate,
      name: nameController.text,
      existing: widget.holiday,
    );
    if (saved && mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final holiday = widget.holiday;
    if (holiday == null) return;
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Remove public holiday?',
      message: '${holiday.name} will be removed from this calendar.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final deleted = await controller.deleteHoliday(holiday);
    if (deleted && mounted) Navigator.of(context).pop();
  }
}

class _DialogLoader extends StatelessWidget {
  const _DialogLoader({this.color = AppColors.primary});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 17,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}
