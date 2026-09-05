import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../consts.dart';
import '../models/settings/app_color_palette.dart';

class ThemeController extends GetxService {
  ThemeController() : selectedPaletteId = AppColors.activePalette.id.obs;

  static const _preferenceKey = 'selected_color_palette';

  final RxString selectedPaletteId;

  List<AppColorPalette> get palettes => AppColorPalettes.values;

  AppColorPalette get selectedPalette =>
      AppColorPalettes.byId(selectedPaletteId.value);

  static Future<void> restoreSavedPalette() async {
    final preferences = await SharedPreferences.getInstance();
    AppColors.applyPalette(
      AppColorPalettes.byId(preferences.getString(_preferenceKey)),
    );
  }

  Future<void> selectPalette(String paletteId) async {
    final palette = AppColorPalettes.byId(paletteId);
    AppColors.applyPalette(palette);
    selectedPaletteId.value = palette.id;
    if (Get.context != null) Get.changeTheme(AppTheme.light());

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, palette.id);
  }

  Future<void> restoreDefault() => selectPalette(AppColorPalettes.dataHub.id);
}
