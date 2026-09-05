import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../models/settings/app_color_palette.dart';
import '../../services/theme_controller.dart';

class SettingsScreen extends GetView<ThemeController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.selectedPaletteId.value;
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < AppSizes.payrollCompactBreakpoint;
          return ColoredBox(
            color: AppColors.mainCanvas,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? AppSpacing.md : AppSpacing.xxl,
                compact ? AppSpacing.md : 30,
                compact ? AppSpacing.md : AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Settings',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.pageHeading,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _AppearanceCard(compact: compact),
                      const SizedBox(height: AppSpacing.md),
                      const _ThemePreviewCard(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _AppearanceCard extends GetView<ThemeController> {
  const _AppearanceCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: AppColors.primaryDark,
                    size: 23,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Appearance', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Choose the color palette that feels best for your workspace.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
                if (!compact)
                  TextButton(
                    onPressed: () => unawaited(controller.restoreDefault()),
                    child: const Text('Restore default'),
                  ),
              ],
            ),
            if (compact) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => unawaited(controller.restoreDefault()),
                  child: const Text('Restore default'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text('COLOR THEME', style: AppTextStyles.tableHeader),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 860
                    ? 3
                    : constraints.maxWidth >= 540
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (AppSpacing.sm * (columns - 1))) /
                    columns;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: controller.palettes
                      .map(
                        (palette) => SizedBox(
                          width: width,
                          child: _PaletteCard(
                            palette: palette,
                            selected:
                                controller.selectedPaletteId.value ==
                                palette.id,
                            onPressed: () =>
                                unawaited(controller.selectPalette(palette.id)),
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Your selection is saved on this device and restored automatically.',
                    style: AppTextStyles.listCount,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.palette,
    required this.selected,
    required this.onPressed,
  });

  final AppColorPalette palette;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.primaryLight : AppColors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? palette.primary : AppColors.border,
          width: selected ? 1.6 : 1,
        ),
        borderRadius: BorderRadius.circular(AppRadii.section),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ColorDot(color: palette.primary),
                  Transform.translate(
                    offset: const Offset(-5, 0),
                    child: _ColorDot(color: palette.primaryDark),
                  ),
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: _ColorDot(color: palette.sidebarBackground),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: AppDurations.fast,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selected ? palette.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? palette.primary
                            : AppColors.borderStrong,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                palette.name,
                style: AppTextStyles.fieldLabel.copyWith(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                palette.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.listCount.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: AppShadows.contentCard,
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.contentCard,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Live preview', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Buttons, highlights, navigation, and page backgrounds update instantly.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              decoration: BoxDecoration(
                color: AppColors.mainCanvas,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadii.section),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  Container(
                    width: 74,
                    height: 150,
                    color: AppColors.sidebarBackground,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.sidebarActive,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          height: 6,
                          width: 34,
                          decoration: BoxDecoration(
                            color: AppColors.sidebarText,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(
                                AppRadii.field,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.field,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Container(
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.field,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
