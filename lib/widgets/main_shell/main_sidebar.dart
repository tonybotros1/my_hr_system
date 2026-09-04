import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/main_controllers/main_screen_controller.dart';
import 'company_brand.dart';
import 'sidebar_navigation_item.dart';

class MainSidebar extends GetView<MainScreenController> {
  const MainSidebar({
    required this.compact,
    required this.onClose,
    required this.activeRouteName,
    super.key,
  });

  final bool compact;
  final VoidCallback onClose;
  final String? activeRouteName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.sidebar,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, AppSpacing.xl, 17, 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => CompanyBrand(company: controller.company.value),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    onPressed: onClose,
                    tooltip: 'Close navigation',
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.sidebarText,
                    ),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 38),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Text('WORKSPACE', style: AppTextStyles.sidebarLabel),
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: _NavigationBody(
                  compact: compact,
                  activeRouteName: activeRouteName,
                ),
              ),
              const Divider(color: AppColors.sidebarDivider),
              const SizedBox(height: AppSpacing.md),
              const _SidebarFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends GetView<MainScreenController> {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final company = controller.company.value;
      final loggingOut = controller.isLoggingOut.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.profileAvatarSize,
                height: AppSizes.profileAvatarSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.sidebarAvatar,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  company?.userInitials ?? 'U',
                  style: AppTextStyles.fieldLabel.copyWith(
                    color: AppColors.sidebarAvatarText,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company?.displayUserName ?? 'Current user',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.profileName,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company?.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.profileDetail,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: loggingOut ? null : controller.requestLogout,
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              foregroundColor: AppColors.sidebarText,
              disabledForegroundColor: AppColors.sidebarLabel,
              backgroundColor: AppColors.sidebarActive,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.field),
              ),
            ),
            icon: loggingOut
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.sidebarText,
                    ),
                  )
                : const Icon(Icons.logout_rounded, size: 19),
            label: Text(loggingOut ? 'Signing out…' : 'Sign out'),
          ),
        ],
      );
    });
  }
}

class _NavigationBody extends GetView<MainScreenController> {
  const _NavigationBody({required this.compact, required this.activeRouteName});

  final bool compact;
  final String? activeRouteName;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.navigationItems.isEmpty) {
        return const Center(
          child: SizedBox.square(
            dimension: AppSizes.loadingIndicatorSize,
            child: CircularProgressIndicator(
              color: AppColors.sidebarText,
              strokeWidth: 2,
            ),
          ),
        );
      }

      if (controller.navigationItems.isEmpty) {
        final error = controller.errorMessage.value;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  error == null
                      ? Icons.lock_outline_rounded
                      : Icons.cloud_off_rounded,
                  color: AppColors.sidebarText,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error ?? 'No screens are available for your account.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.profileDetail.copyWith(fontSize: 11),
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: controller.loadShellData,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.surface,
                    ),
                    child: const Text('Try again'),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: controller.navigationItems.length,
        itemBuilder: (context, index) => SidebarNavigationItem(
          item: controller.navigationItems[index],
          compact: compact,
          activeRouteName: activeRouteName,
        ),
      );
    });
  }
}
