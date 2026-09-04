import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/user_controllers/users_controller.dart';
import '../form_fields/app_date_form_field.dart';
import '../form_fields/app_text_form_field.dart';

Future<void> showUserEditorDialog(BuildContext context) async {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final width = math.max(
    280,
    math.min(AppSizes.userEditorWidth, screenWidth - (AppSpacing.md * 2)),
  );
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.dialogScrim,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      backgroundColor: AppColors.mainCanvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.editor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width.toDouble(),
          maxHeight:
              MediaQuery.sizeOf(dialogContext).height - (AppSpacing.md * 2),
        ),
        child: _UserEditor(onClose: () => Navigator.of(dialogContext).pop()),
      ),
    ),
  );
}

class _UserEditor extends GetView<UsersController> {
  const _UserEditor({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EditorHeader(onClose: onClose),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('User details', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Choose the HR screens this user can open.',
                    style: AppTextStyles.bodyMuted,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextFormField(
                    label: 'User name',
                    hintText: 'Enter the user name',
                    controller: controller.nameController,
                    validator: controller.requiredText,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Obx(
                    () => AppTextFormField(
                      label: 'Email',
                      hintText: 'name@company.com',
                      controller: controller.emailController,
                      validator: controller.validateEmail,
                      enabled: !controller.isEditing,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Obx(
                    () => AppTextFormField(
                      label: controller.isEditing
                          ? 'New password (optional)'
                          : 'Password',
                      hintText: controller.isEditing
                          ? 'Leave empty to keep the current password'
                          : 'Enter a password',
                      controller: controller.passwordController,
                      validator: controller.validatePassword,
                      obscureText: controller.obscurePassword.value,
                      textInputAction: TextInputAction.next,
                      suffixIcon: IconButton(
                        tooltip: controller.obscurePassword.value
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: controller.togglePasswordVisibility,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          controller.obscurePassword.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: AppSizes.inputIconSize,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final expiry = AppDateFormField(
                        label: 'Expiry date',
                        controller: controller.expiryController,
                        validator: controller.validateExpiryDate,
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      const admin = _AdminToggle();
                      if (constraints.maxWidth < 500) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            expiry,
                            const SizedBox(height: AppSpacing.md),
                            admin,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(flex: 3, child: expiry),
                          const SizedBox(width: AppSpacing.md),
                          const Expanded(flex: 2, child: admin),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _HrScreenAccessSelector(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HrScreenAccessSelector extends GetView<UsersController> {
  const _HrScreenAccessSelector();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadii.section),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HR screen access',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${controller.selectedHrScreens.length} of ${controller.availableHrScreens.length} selected',
                        style: AppTextStyles.listCount,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: controller.allHrScreensSelected
                      ? controller.clearHrScreens
                      : controller.selectAllHrScreens,
                  child: Text(
                    controller.allHrScreensSelected
                        ? 'Clear all'
                        : 'Select all',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 480;
                final itemWidth = compact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - AppSpacing.sm) / 2;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: controller.availableHrScreens
                      .map(
                        (screen) => SizedBox(
                          width: itemWidth,
                          child: _ScreenPermissionTile(
                            name: screen.name,
                            selected: controller.selectedHrScreens.contains(
                              screen.routeName,
                            ),
                            onChanged: () =>
                                controller.toggleHrScreen(screen.routeName),
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenPermissionTile extends StatelessWidget {
  const _ScreenPermissionTile({
    required this.name,
    required this.selected,
    required this.onChanged,
  });

  final String name;
  final bool selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.softSurface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onChanged,
        child: SizedBox(
          height: 42,
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: (_) => onChanged(),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.checkboxLabel.copyWith(
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorHeader extends GetView<UsersController> {
  const _EditorHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: Text(
                controller.isEditing ? 'Edit User' : 'New User',
                style: AppTextStyles.heading(fontSize: 21),
              ),
            ),
            TextButton(
              onPressed: controller.isSaving.value ? null : onClose,
              style: TextButton.styleFrom(foregroundColor: AppColors.textHint),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () async {
                      final saved = await controller.saveUser();
                      if (saved) onClose();
                    },
              child: controller.isSaving.value
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save User'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminToggle extends GetView<UsersController> {
  const _AdminToggle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.labelLeftPadding,
            bottom: AppSpacing.xs,
          ),
          child: Text('Access', style: AppTextStyles.fieldLabel),
        ),
        Obx(
          () => Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadii.field),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => controller.isAdmin.toggle(),
              child: SizedBox(
                height: AppSizes.inputMinHeight,
                child: Row(
                  children: [
                    Checkbox(
                      value: controller.isAdmin.value,
                      onChanged: (value) =>
                          controller.isAdmin.value = value ?? false,
                      visualDensity: VisualDensity.compact,
                    ),
                    Text('Admin', style: AppTextStyles.checkboxLabel),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
