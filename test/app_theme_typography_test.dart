import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_hr_system/consts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('application typography uses the Inter interface hierarchy', () {
    final theme = AppTheme.light();

    expect(theme.textTheme.titleLarge?.fontFamily, contains('Inter'));
    expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w700);
    expect(theme.textTheme.bodyMedium?.fontFamily, contains('Inter'));
    expect(theme.textTheme.bodyMedium?.fontWeight, FontWeight.w400);
    expect(theme.textTheme.labelMedium?.fontFamily, contains('Inter'));
    expect(theme.textTheme.labelMedium?.fontWeight, FontWeight.w600);

    expect(AppTextStyles.heading().fontFamily, contains('Inter'));
    expect(AppTextStyles.heading().fontWeight, FontWeight.w700);
    expect(AppTextStyles.body.fontFamily, contains('Inter'));
    expect(AppTextStyles.body.fontWeight, FontWeight.w400);
    expect(AppTextStyles.input.fontFamily, contains('Inter'));
    expect(AppTextStyles.input.fontWeight, FontWeight.w400);
    expect(AppTextStyles.button.fontFamily, contains('Inter'));
    expect(AppTextStyles.button.fontWeight, FontWeight.w700);
    expect(AppTextStyles.navigationItem.fontWeight, FontWeight.w600);

    expect(AppTextStyles.tableKey.fontFamily, contains('RobotoMono'));
    expect(AppTextStyles.tableKey.fontWeight, FontWeight.w600);
    expect(textFieldFontStyle.fontWeight, FontWeight.w400);
    expect(textFieldLabelStyle.fontWeight, FontWeight.w600);
  });
}
