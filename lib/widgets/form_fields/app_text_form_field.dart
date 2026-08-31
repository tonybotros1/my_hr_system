import 'package:flutter/material.dart';

import '../../consts.dart';

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    required this.label,
    required this.hintText,
    required this.controller,
    super.key,
    this.validator,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
    this.autofillHints,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final multiline = (maxLines ?? 1) > 1 || (minLines ?? 1) > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.labelLeftPadding,
            bottom: AppSpacing.xs,
          ),
          child: Text(label, style: AppTextStyles.fieldLabel),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
          autofillHints: autofillHints,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          textCapitalization: textCapitalization,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTextStyles.input,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
            errorMaxLines: 2,
            contentPadding: multiline
                ? const EdgeInsets.all(AppSizes.fieldHorizontalPadding)
                : null,
            constraints: const BoxConstraints(
              minHeight: AppSizes.inputMinHeight,
            ),
          ),
        ),
      ],
    );
  }
}
