import 'package:flutter/material.dart';

@immutable
class AppColorPalette {
  const AppColorPalette({
    required this.id,
    required this.name,
    required this.description,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primaryDisabled,
    required this.background,
    required this.backgroundStart,
    required this.backgroundMiddle,
    required this.backgroundEnd,
    required this.mainCanvas,
    required this.sidebarBackground,
    required this.sidebarActive,
    required this.sidebarText,
    required this.sidebarLabel,
    required this.sidebarDivider,
    required this.sidebarProfileText,
  });

  final String id;
  final String name;
  final String description;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primaryDisabled;
  final Color background;
  final Color backgroundStart;
  final Color backgroundMiddle;
  final Color backgroundEnd;
  final Color mainCanvas;
  final Color sidebarBackground;
  final Color sidebarActive;
  final Color sidebarText;
  final Color sidebarLabel;
  final Color sidebarDivider;
  final Color sidebarProfileText;
}

class AppColorPalettes {
  AppColorPalettes._();

  static const dataHub = AppColorPalette(
    id: 'datahub-teal',
    name: 'DataHub Teal',
    description: 'The balanced teal theme designed for DataHub AI.',
    primary: Color(0xFF0C9D93),
    primaryDark: Color(0xFF087870),
    primaryLight: Color(0xFFE7F8F6),
    primaryDisabled: Color(0x8C0C9D93),
    background: Color(0xFFF4FAF9),
    backgroundStart: Color(0xFFEDF9F8),
    backgroundMiddle: Color(0xFFF8FBFB),
    backgroundEnd: Color(0xFFE5F4F2),
    mainCanvas: Color(0xFFF4F8F8),
    sidebarBackground: Color(0xFF143336),
    sidebarActive: Color(0xFF205156),
    sidebarText: Color(0xFFABC3C2),
    sidebarLabel: Color(0xFF719393),
    sidebarDivider: Color(0xFF2A5457),
    sidebarProfileText: Color(0xFF8BB0AF),
  );

  static const ocean = AppColorPalette(
    id: 'ocean-blue',
    name: 'Ocean Blue',
    description: 'Crisp blue accents with a calm navy workspace.',
    primary: Color(0xFF2F6FEB),
    primaryDark: Color(0xFF1E4FB7),
    primaryLight: Color(0xFFEAF1FF),
    primaryDisabled: Color(0x8C2F6FEB),
    background: Color(0xFFF5F8FF),
    backgroundStart: Color(0xFFEEF4FF),
    backgroundMiddle: Color(0xFFFAFBFF),
    backgroundEnd: Color(0xFFE8F0FF),
    mainCanvas: Color(0xFFF3F6FC),
    sidebarBackground: Color(0xFF172640),
    sidebarActive: Color(0xFF254570),
    sidebarText: Color(0xFFB8C9E7),
    sidebarLabel: Color(0xFF7F96BC),
    sidebarDivider: Color(0xFF2C4B76),
    sidebarProfileText: Color(0xFF9FB3D4),
  );

  static const violet = AppColorPalette(
    id: 'royal-violet',
    name: 'Royal Violet',
    description: 'A polished violet accent with a deep plum sidebar.',
    primary: Color(0xFF7659D7),
    primaryDark: Color(0xFF5740AE),
    primaryLight: Color(0xFFF1EDFF),
    primaryDisabled: Color(0x8C7659D7),
    background: Color(0xFFF8F6FD),
    backgroundStart: Color(0xFFF3EFFF),
    backgroundMiddle: Color(0xFFFCFBFF),
    backgroundEnd: Color(0xFFEFEAFA),
    mainCanvas: Color(0xFFF7F5FB),
    sidebarBackground: Color(0xFF2B2440),
    sidebarActive: Color(0xFF493C6A),
    sidebarText: Color(0xFFD0C5E9),
    sidebarLabel: Color(0xFF9B8DBB),
    sidebarDivider: Color(0xFF514570),
    sidebarProfileText: Color(0xFFB7A9D1),
  );

  static const forest = AppColorPalette(
    id: 'forest-green',
    name: 'Forest Green',
    description: 'Natural green accents for a grounded, quiet workspace.',
    primary: Color(0xFF24966A),
    primaryDark: Color(0xFF176B4B),
    primaryLight: Color(0xFFE8F7F0),
    primaryDisabled: Color(0x8C24966A),
    background: Color(0xFFF4F9F6),
    backgroundStart: Color(0xFFEDF8F1),
    backgroundMiddle: Color(0xFFFAFCFA),
    backgroundEnd: Color(0xFFE7F2EB),
    mainCanvas: Color(0xFFF3F7F4),
    sidebarBackground: Color(0xFF17352B),
    sidebarActive: Color(0xFF285846),
    sidebarText: Color(0xFFB6D1C5),
    sidebarLabel: Color(0xFF7F9F91),
    sidebarDivider: Color(0xFF315D4D),
    sidebarProfileText: Color(0xFF9DBBAE),
  );

  static const coral = AppColorPalette(
    id: 'warm-coral',
    name: 'Warm Coral',
    description: 'Friendly coral accents balanced by a rich aubergine base.',
    primary: Color(0xFFDF625F),
    primaryDark: Color(0xFFB6444E),
    primaryLight: Color(0xFFFFEFEE),
    primaryDisabled: Color(0x8CDF625F),
    background: Color(0xFFFFF8F6),
    backgroundStart: Color(0xFFFFF1EE),
    backgroundMiddle: Color(0xFFFFFCFB),
    backgroundEnd: Color(0xFFF9EAE8),
    mainCanvas: Color(0xFFFAF5F3),
    sidebarBackground: Color(0xFF3B252B),
    sidebarActive: Color(0xFF623D46),
    sidebarText: Color(0xFFE1C3C8),
    sidebarLabel: Color(0xFFAD888F),
    sidebarDivider: Color(0xFF69444C),
    sidebarProfileText: Color(0xFFC5A3A9),
  );

  static const values = <AppColorPalette>[
    dataHub,
    ocean,
    violet,
    forest,
    coral,
  ];

  static AppColorPalette byId(String? id) {
    for (final palette in values) {
      if (palette.id == id) return palette;
    }
    return dataHub;
  }
}
