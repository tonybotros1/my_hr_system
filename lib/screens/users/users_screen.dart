import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/user_controllers/users_controller.dart';
import '../../models/users/user_model.dart';
import '../../widgets/dialogs/app_alert_dialog.dart';
import '../../widgets/form_fields/app_text_form_field.dart';
import '../../widgets/users/user_editor_dialog.dart';
import '../../widgets/users/users_table.dart';

class UsersScreen extends GetView<UsersController> {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < AppSizes.payrollCompactBreakpoint;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? AppSpacing.md : AppSpacing.xxl,
            compact ? AppSpacing.md : 30,
            compact ? AppSpacing.md : AppSpacing.xxl,
            AppSpacing.md,
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PageHeader(),
              SizedBox(height: AppSpacing.lg),
              _FilterCard(),
              SizedBox(height: AppSpacing.md),
              Expanded(child: _UsersListCard()),
            ],
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Users',
      textAlign: TextAlign.center,
      style: AppTextStyles.pageHeading,
    );
  }
}

class _FilterCard extends GetView<UsersController> {
  const _FilterCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 720) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(child: _SearchField()),
                  const SizedBox(width: AppSpacing.sm),
                  _FindButton(),
                  const SizedBox(width: AppSpacing.sm),
                  _ClearButton(),
                  const SizedBox(width: AppSpacing.sm),
                  const _NewButton(),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SearchField(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _FindButton(),
                    const SizedBox(width: AppSpacing.sm),
                    _ClearButton(),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const _NewButton(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchField extends GetView<UsersController> {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      label: 'Search',
      hintText: 'Search by user name or email',
      controller: controller.searchController,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (_) => controller.findUsers(),
    );
  }
}

class _FindButton extends GetView<UsersController> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: AppSizes.inputMinHeight,
        child: FilledButton(
          onPressed: controller.isLoading.value ? null : controller.findUsers,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.primaryDark,
            elevation: 0,
          ),
          child: const Text('Find'),
        ),
      ),
    );
  }
}

class _ClearButton extends GetView<UsersController> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.inputMinHeight,
      child: OutlinedButton(
        onPressed: controller.clearFilters,
        child: const Text('Clear'),
      ),
    );
  }
}

class _NewButton extends GetView<UsersController> {
  const _NewButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.inputMinHeight,
      child: FilledButton.icon(
        onPressed: () {
          controller.prepareNewUser();
          showUserEditorDialog(context);
        },
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('New User'),
      ),
    );
  }
}

class _UsersListCard extends GetView<UsersController> {
  const _UsersListCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.section),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Obx(
                  () => Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${controller.filteredUsers.length}',
                          style: AppTextStyles.listCount.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(text: ' users'),
                      ],
                    ),
                    style: AppTextStyles.listCount,
                  ),
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableRows =
                      constraints.maxHeight - AppSizes.payrollTableHeaderHeight;
                  final rows = availableRows <= 0
                      ? 1
                      : (availableRows / AppSizes.usersTableRowHeight)
                            .floor()
                            .clamp(1, 1000)
                            .toInt();
                  controller.schedulePageSize(rows);
                  return Obx(() {
                    if (controller.isLoading.value &&
                        controller.users.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final error = controller.listError.value;
                    if (error != null && controller.users.isEmpty) {
                      return _ListMessage(
                        icon: Icons.cloud_off_rounded,
                        message: error,
                        actionLabel: 'Try again',
                        onAction: controller.fetchUsers,
                      );
                    }
                    if (controller.filteredUsers.isEmpty) {
                      return const _ListMessage(
                        icon: Icons.manage_accounts_outlined,
                        message: 'No users match this search.',
                      );
                    }
                    return UsersTable(
                      users: controller.visibleUsers,
                      mutatingUserId: controller.mutatingUserId.value,
                      isCurrentUser: controller.isCurrentUser,
                      onEdit: (user) => _edit(context, user),
                      onDelete: (user) => _delete(context, user),
                      onStatusChanged: controller.changeStatus,
                    );
                  });
                },
              ),
            ),
            const Divider(),
            const _TablePager(),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context, UserModel user) {
    controller.prepareExistingUser(user);
    showUserEditorDialog(context);
  }

  Future<void> _delete(BuildContext context, UserModel user) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete user?',
      message: '"${user.userName}" will permanently lose access.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed) await controller.deleteUser(user);
  }
}

class _TablePager extends GetView<UsersController> {
  const _TablePager();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Rows ${controller.rowStart}-${controller.rowEnd} of ${controller.filteredUsers.length}',
                style: AppTextStyles.listCount,
              ),
            ),
            _PagerButton(
              tooltip: 'Previous page',
              icon: Icons.chevron_left_rounded,
              onPressed: controller.canGoPrevious
                  ? controller.previousPage
                  : null,
            ),
            const SizedBox(width: AppSpacing.xs),
            _PagerButton(
              tooltip: 'Next page',
              icon: Icons.chevron_right_rounded,
              onPressed: controller.canGoNext ? controller.nextPage : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 34,
        child: IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            disabledForegroundColor: AppColors.textHint,
            side: const BorderSide(color: AppColors.border),
            padding: EdgeInsets.zero,
          ),
          icon: Icon(icon, size: 19),
        ),
      ),
    );
  }
}

class _ListMessage extends StatelessWidget {
  const _ListMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.iconMuted, size: 34),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
