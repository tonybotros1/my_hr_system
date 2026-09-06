import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/main_controllers/main_screen_controller.dart';
import '../../routes/app_routes.dart';
import '../../models/navigation/navigation_item_model.dart';
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
              SidebarNavigationItem(
                item: const NavigationItemModel(
                  id: 'dashboard',
                  name: 'Dashboard',
                  isMenu: false,
                  routeName: '/dashboard',
                  children: [],
                ),
                compact: compact,
                activeRouteName:
                    activeRouteName == null || activeRouteName!.isEmpty
                    ? '/dashboard'
                    : activeRouteName,
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: _NavigationBody(
                  compact: compact,
                  activeRouteName: activeRouteName,
                ),
              ),
              Divider(color: AppColors.sidebarDivider),
              const SizedBox(height: AppSpacing.md),
              _SidebarFooter(
                compact: compact,
                activeRouteName: activeRouteName,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends GetView<MainScreenController> {
  const _SidebarFooter({required this.compact, required this.activeRouteName});

  final bool compact;
  final String? activeRouteName;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _SidebarCircleAction(
                tooltip: 'Settings',
                icon: Icons.settings_rounded,
                selected: AppRoutes.isMenuRouteActive(
                  '/settings',
                  activeRouteName,
                ),
                onPressed: () => controller.openSettings(compact: compact),
              ),
              const SizedBox(width: AppSpacing.xs),
              _SidebarCircleAction(
                tooltip: loggingOut ? 'Signing out' : 'Sign out',
                icon: Icons.logout_rounded,
                onPressed: loggingOut ? null : controller.requestLogout,
                child: loggingOut
                    ? SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.sidebarText,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _SidebarCircleAction extends StatelessWidget {
  const _SidebarCircleAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.child,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(40),
        foregroundColor: selected ? AppColors.surface : AppColors.sidebarText,
        disabledForegroundColor: AppColors.sidebarLabel,
        backgroundColor: selected ? AppColors.primary : AppColors.sidebarActive,
        hoverColor: AppColors.primaryDark,
        shape: const CircleBorder(),
      ),
      icon: child ?? Icon(icon, size: 19),
    );
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
        return Center(
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
