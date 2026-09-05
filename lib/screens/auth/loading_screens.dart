import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/auth_controllers/loading_screen_controller.dart';

class LoadingScreen extends GetView<LoadingScreenController> {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: AppDecorations.pageBackground,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Obx(
              () => AnimatedSwitcher(
                duration: AppDurations.normal,
                child: controller.needRefresh.value
                    ? _RetryCard(onRetry: controller.checkLogStatus)
                    : const _LoadingCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      key: const ValueKey('loading'),
      children: [
        Text('DataHub AI', style: AppTextStyles.brand),
        const SizedBox(height: AppSizes.footerTopGap),
        const SizedBox(
          width: AppSizes.loadingIndicatorSize,
          height: AppSizes.loadingIndicatorSize,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        const SizedBox(height: AppSizes.formFieldGap),
        Text(
          'Checking your secure session…',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      key: const ValueKey('retry'),
      children: [
        Icon(Icons.cloud_off_rounded, color: AppColors.primary, size: 34),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Connection unavailable',
          style: AppTextStyles.heading(fontSize: 19),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'We could not verify your session. Check your connection and try again.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSizes.secondaryButtonHeight),
          ),
          child: const Text('Try again'),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.loadingCardWidth,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: 34,
      ),
      decoration: AppDecorations.statusCard,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
