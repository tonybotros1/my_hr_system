import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../consts.dart';
import '../../controllers/main_controllers/main_screen_controller.dart';
import '../../services/theme_controller.dart';
import '../../widgets/main_shell/main_sidebar.dart';

class MainScreen extends GetView<MainScreenController> {
  const MainScreen({this.screenRouteName, super.key});

  final String? screenRouteName;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      themeController.selectedPaletteId.value;
      return Scaffold(
        backgroundColor: AppColors.mainCanvas,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth <= AppSizes.mainMobileBreakpoint;
            return Obx(() {
              final sidebarOpen = controller.sidebarIsOpen(compact: compact);
              if (compact) {
                return _CompactShell(
                  sidebarOpen: sidebarOpen,
                  availableWidth: constraints.maxWidth,
                  activeRouteName: screenRouteName,
                );
              }
              return _DesktopShell(
                sidebarOpen: sidebarOpen,
                sidebarWidth: controller.sidebarWidth.value,
                resizing: controller.isResizingSidebar.value,
                activeRouteName: screenRouteName,
              );
            });
          },
        ),
      );
    });
  }
}

class _DesktopShell extends GetView<MainScreenController> {
  const _DesktopShell({
    required this.sidebarOpen,
    required this.sidebarWidth,
    required this.resizing,
    required this.activeRouteName,
  });

  final bool sidebarOpen;
  final double sidebarWidth;
  final bool resizing;
  final String? activeRouteName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRect(
          child: AnimatedContainer(
            duration: resizing ? Duration.zero : AppDurations.sidebar,
            curve: Curves.easeInOutCubic,
            width: sidebarOpen ? sidebarWidth : 0,
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: sidebarWidth,
              maxWidth: sidebarWidth,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: MainSidebar(
                      compact: false,
                      onClose: controller.closeSidebar,
                      activeRouteName: activeRouteName,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: AppSizes.sidebarResizeHandleWidth,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeLeftRight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: (_) =>
                            controller.startSidebarResize(),
                        onHorizontalDragUpdate: (details) =>
                            controller.resizeSidebar(details.delta.dx),
                        onHorizontalDragEnd: (_) =>
                            controller.finishSidebarResize(),
                        onHorizontalDragCancel: controller.finishSidebarResize,
                        child: Center(
                          child: Container(
                            width: 1,
                            height: double.infinity,
                            color: AppColors.sidebarDivider,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _MainCanvas(
            sidebarOpen: sidebarOpen,
            compact: false,
            activeRouteName: activeRouteName,
          ),
        ),
      ],
    );
  }
}

class _CompactShell extends GetView<MainScreenController> {
  const _CompactShell({
    required this.sidebarOpen,
    required this.availableWidth,
    required this.activeRouteName,
  });

  final bool sidebarOpen;
  final double availableWidth;
  final String? activeRouteName;

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = math.min(
      AppSizes.mobileSidebarWidth,
      availableWidth * 0.88,
    );
    return Stack(
      children: [
        _MainCanvas(
          sidebarOpen: sidebarOpen,
          compact: true,
          activeRouteName: activeRouteName,
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !sidebarOpen,
            child: AnimatedOpacity(
              opacity: sidebarOpen ? 1 : 0,
              duration: AppDurations.sidebar,
              child: GestureDetector(
                onTap: controller.closeSidebar,
                child: const ColoredBox(color: AppColors.sidebarScrim),
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: AppDurations.sidebar,
          curve: Curves.easeInOutCubic,
          top: 0,
          bottom: 0,
          left: sidebarOpen ? 0 : -sidebarWidth,
          width: sidebarWidth,
          child: MainSidebar(
            compact: true,
            onClose: controller.closeSidebar,
            activeRouteName: activeRouteName,
          ),
        ),
      ],
    );
  }
}

class _MainCanvas extends GetView<MainScreenController> {
  const _MainCanvas({
    required this.sidebarOpen,
    required this.compact,
    required this.activeRouteName,
  });

  final bool sidebarOpen;
  final bool compact;
  final String? activeRouteName;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.mainCanvas,
      child: Stack(
        children: [
          Positioned.fill(child: _SelectedScreen(routeName: activeRouteName)),
          if (!sidebarOpen)
            Positioned(
              top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
              left: AppSpacing.sm,
              child: Material(
                color: AppColors.surface,
                elevation: 3,
                shadowColor: AppColors.cardShadow,
                borderRadius: BorderRadius.circular(AppRadii.field),
                child: IconButton(
                  onPressed: () => controller.toggleSidebar(compact: compact),
                  tooltip: 'Open navigation',
                  color: AppColors.primaryDark,
                  icon: const Icon(Icons.menu_rounded),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedScreen extends GetView<MainScreenController> {
  const _SelectedScreen({required this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    final normalizedRoute = routeName?.replaceAll('_', '').toLowerCase();
    return controller.getScreenFromRoute(normalizedRoute);
  }
}
