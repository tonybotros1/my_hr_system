import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';

enum AppAlertKind { success, error, info }

Future<void> showAppAlertDialog({
  required String title,
  required String message,
  AppAlertKind kind = AppAlertKind.info,
}) async {
  final context = Get.overlayContext ?? Get.context;
  if (context == null) return;

  await showDialog<void>(
    context: context,
    barrierColor: AppColors.dialogScrim,
    builder: (dialogContext) =>
        _AppAlertDialog(title: title, message: message, kind: kind),
  );
}

Future<bool> showAppConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.dialogScrim,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.section),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.alertDialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AlertIcon(
                icon: destructive
                    ? Icons.delete_outline_rounded
                    : Icons.help_outline_rounded,
                foreground: destructive
                    ? AppColors.error
                    : AppColors.primaryDark,
                background: destructive
                    ? AppColors.dangerBackground
                    : AppColors.primaryLight,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading(fontSize: 19),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: destructive
                          ? FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                            )
                          : null,
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result == true;
}

class _AppAlertDialog extends StatelessWidget {
  const _AppAlertDialog({
    required this.title,
    required this.message,
    required this.kind,
  });

  final String title;
  final String message;
  final AppAlertKind kind;

  @override
  Widget build(BuildContext context) {
    final presentation = switch (kind) {
      AppAlertKind.success => (
        Icons.check_rounded,
        AppColors.success,
        AppColors.successBackground,
      ),
      AppAlertKind.error => (
        Icons.close_rounded,
        AppColors.error,
        AppColors.dangerBackground,
      ),
      AppAlertKind.info => (
        Icons.info_outline_rounded,
        AppColors.primaryDark,
        AppColors.primaryLight,
      ),
    };

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.section),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.alertDialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AlertIcon(
                icon: presentation.$1,
                foreground: presentation.$2,
                background: presentation.$3,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading(fontSize: 19),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: kind == AppAlertKind.error
                      ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                      : null,
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertIcon extends StatelessWidget {
  const _AlertIcon({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.alertIconSize,
      height: AppSizes.alertIconSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: foreground, size: 28),
    );
  }
}
