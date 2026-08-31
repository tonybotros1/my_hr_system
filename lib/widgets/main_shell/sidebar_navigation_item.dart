import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/main_controllers/main_screen_controller.dart';
import '../../models/navigation/navigation_item_model.dart';
import '../../routes/app_routes.dart';

class SidebarNavigationItem extends GetView<MainScreenController> {
  const SidebarNavigationItem({
    required this.item,
    required this.compact,
    required this.activeRouteName,
    this.level = 0,
    super.key,
  });

  final NavigationItemModel item;
  final bool compact;
  final String? activeRouteName;
  final int level;

  @override
  Widget build(BuildContext context) {
    if (item.children.isNotEmpty) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('navigation-${item.id}'),
          initiallyExpanded: _containsActiveRoute(item),
          maintainState: true,
          tilePadding: EdgeInsets.only(
            left: AppSpacing.sm + (level * AppSpacing.sm),
            right: AppSpacing.xs,
          ),
          childrenPadding: EdgeInsets.zero,
          minTileHeight: 43,
          title: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.navigationItem,
          ),
          iconColor: AppColors.surface,
          collapsedIconColor: AppColors.sidebarLabel,
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          children: item.children
              .map(
                (child) => SidebarNavigationItem(
                  item: child,
                  compact: compact,
                  activeRouteName: activeRouteName,
                  level: level + 1,
                ),
              )
              .toList(growable: false),
        ),
      );
    }

    final selected = AppRoutes.isMenuRouteActive(
      item.routeName,
      activeRouteName,
    );
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xxs + (level * AppSpacing.sm),
        right: AppSpacing.xxs,
        bottom: AppSpacing.xxs,
      ),
      child: Material(
        color: selected ? AppColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.navigationItem),
        child: InkWell(
          onTap: item.canOpen
              ? () => controller.selectItem(item, compact: compact)
              : null,
          borderRadius: BorderRadius.circular(AppRadii.navigationItem),
          hoverColor: AppColors.sidebarActive,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 11,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: selected
                        ? AppTextStyles.navigationItemSelected
                        : AppTextStyles.navigationItem,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _containsActiveRoute(NavigationItemModel candidate) {
    if (AppRoutes.isMenuRouteActive(candidate.routeName, activeRouteName)) {
      return true;
    }
    for (final child in candidate.children) {
      if (_containsActiveRoute(child)) return true;
    }
    return false;
  }
}
