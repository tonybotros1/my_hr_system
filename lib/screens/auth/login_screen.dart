import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../consts.dart';
import '../../controllers/auth_controllers/login_screen_controller.dart';
import '../../widgets/form_fields/app_text_form_field.dart';

class LoginScreen extends GetView<LoginScreenController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: AppDecorations.pageBackground,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth <= AppSizes.mobileBreakpoint;
              final pagePadding = compact
                  ? AppSizes.compactPagePadding
                  : AppSpacing.xl;

              return SingleChildScrollView(
                padding: EdgeInsets.all(pagePadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (pagePadding * 2),
                  ),
                  child: Center(
                    child: Container(
                      width: AppSizes.loginCardWidth,
                      padding: EdgeInsets.symmetric(
                        horizontal: compact
                            ? AppSizes.compactCardHorizontalPadding
                            : AppSizes.cardPadding,
                        vertical: compact
                            ? AppSizes.compactCardVerticalPadding
                            : AppSizes.cardPadding,
                      ),
                      decoration: AppDecorations.loginCard(compact: compact),
                      child: AutofillGroup(
                        child: Form(
                          key: controller.formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'DataHub AI',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.brand,
                              ),
                              const SizedBox(
                                height: AppSizes.brandToHeadingGap,
                              ),
                              Text(
                                'Welcome back',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.heading(),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Sign in to manage your people, payroll, and more.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMuted,
                              ),
                              const SizedBox(height: AppSizes.introToFormGap),
                              AppTextFormField(
                                label: 'Email address',
                                hintText: 'name@company.com',
                                controller: controller.emailController,
                                focusNode: controller.emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: controller.validateEmail,
                                autofillHints: const [AutofillHints.email],
                                onFieldSubmitted: (_) {
                                  controller.passwordFocusNode.requestFocus();
                                },
                              ),
                              const SizedBox(height: AppSizes.formFieldGap),
                              Obx(
                                () => AppTextFormField(
                                  label: 'Password',
                                  hintText: 'Enter your password',
                                  controller: controller.passwordController,
                                  focusNode: controller.passwordFocusNode,
                                  textInputAction: TextInputAction.done,
                                  obscureText: controller.obscurePassword.value,
                                  validator: controller.validatePassword,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) {
                                    TextInput.finishAutofillContext();
                                    controller.submit();
                                  },
                                  suffixIcon: IconButton(
                                    tooltip: controller.obscurePassword.value
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed:
                                        controller.togglePasswordVisibility,
                                    icon: Icon(
                                      controller.obscurePassword.value
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.iconMuted,
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: controller.showForgotPasswordHelp,
                                  style: AppButtonStyles.link,
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                              Obx(() {
                                final message = controller.errorMessage.value;
                                if (message == null) {
                                  return const SizedBox(height: 7);
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      message,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.error,
                                    ),
                                  ),
                                );
                              }),
                              Obx(
                                () => _SignInButton(
                                  loading: controller.isSigningIn.value,
                                  onPressed: controller.submit,
                                ),
                              ),
                              const SizedBox(height: AppSizes.footerTopGap),
                              const Divider(),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Secure access for your organization',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.footer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.primaryButton,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: AppButtonStyles.gradient,
        child: AnimatedSwitcher(
          duration: AppDurations.fast,
          child: loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: AppSizes.buttonLoaderSize,
                  height: AppSizes.buttonLoaderSize,
                  child: CircularProgressIndicator(
                    color: AppColors.surface,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Sign in', key: ValueKey('label')),
        ),
      ),
    );
  }
}
