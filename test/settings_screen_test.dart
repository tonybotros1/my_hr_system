import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_hr_system/consts.dart';
import 'package:my_hr_system/models/settings/app_color_palette.dart';
import 'package:my_hr_system/screens/settings/settings_screen.dart';
import 'package:my_hr_system/services/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    AppColors.applyPalette(AppColorPalettes.dataHub);
    Get.put(ThemeController());
  });

  tearDown(() {
    AppColors.applyPalette(AppColorPalettes.dataHub);
    Get.reset();
  });

  testWidgets('settings screen observes and persists palette changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light(), home: const SettingsScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Ocean Blue'), findsOneWidget);

    await tester.tap(find.text('Ocean Blue'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(AppColors.activePalette.id, AppColorPalettes.ocean.id);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('selected_color_palette'),
      AppColorPalettes.ocean.id,
    );
  });
}
