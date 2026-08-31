import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/dialogs/app_alert_dialog.dart';

/// Project-wide color tokens.
///
/// Use the semantic names (`primary`, `textPrimary`, and so on) in new code so
/// the application can be re-themed from this file without editing screens.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF0C9D93);
  static const primaryDark = Color(0xFF087870);
  static const primaryLight = Color(0xFFE7F8F6);
  static const primaryDisabled = Color(0x8C0C9D93);

  static const background = Color(0xFFF4FAF9);
  static const backgroundStart = Color(0xFFEDF9F8);
  static const backgroundMiddle = Color(0xFFF8FBFB);
  static const backgroundEnd = Color(0xFFE5F4F2);
  static const surface = Colors.white;
  static const mainCanvas = Color(0xFFF4F8F8);
  static const softSurface = Color(0xFFF8FBFB);
  static const segmentBackground = Color(0xFFEFF6F5);
  static const tableHeader = Color(0xFFF3F8F7);

  static const sidebarBackground = Color(0xFF143336);
  static const sidebarActive = Color(0xFF205156);
  static const sidebarText = Color(0xFFABC3C2);
  static const sidebarLabel = Color(0xFF719393);
  static const sidebarDivider = Color(0xFF2A5457);
  static const sidebarProfileText = Color(0xFF8BB0AF);
  static const sidebarAvatar = Color(0xFFE2B372);
  static const sidebarAvatarText = Color(0xFF64451E);
  static const sidebarScrim = Color(0x660D2022);
  static const dialogScrim = Color(0x73081F20);

  static const textPrimary = Color(0xFF20323A);
  static const textSecondary = Color(0xFF7C8A90);
  static const textHint = Color(0xFFAAB3B6);
  static const textFooter = Color(0xFF98A4A6);
  static const iconMuted = Color(0xFF7F9092);

  static const border = Color(0xFFDFE8E7);
  static const borderStrong = Color(0xFFC7DAD7);
  static const divider = Color(0xFFEDF1F1);
  static const error = Color(0xFFD44C4C);
  static const errorText = Color(0xFFB73B3B);
  static const dangerBackground = Color(0xFFFFF1F0);
  static const successBackground = Color(0xFFE9F7F1);
  static const informationBackground = Color(0xFFEEF2F7);
  static const informationText = Color(0xFF53687A);
  static const success = Color(0xFF2E8B72);
  static const warning = Color(0xFFF0A53A);

  static const cardShadow = Color(0x24105955);
  static const buttonShadow = Color(0x380C9D93);
  static const topBarShadow = Color(0x0D123C3E);

  // Backward-compatible aliases for code written before the semantic names.
  static const teal = primary;
  static const deepTeal = primaryDark;
  static const paleTeal = primaryLight;
  static const ink = textPrimary;
  static const muted = textSecondary;
  static const line = border;
}

/// Standard spacing values used throughout the project.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

class AppRadii {
  AppRadii._();

  static const double field = 11;
  static const double compactCard = 20;
  static const double statusCard = 22;
  static const double card = 24;
  static const double navigationItem = 10;
  static const double companyLogo = 10;
  static const double section = 16;
  static const double editor = 20;
}

/// Shared component sizes and responsive breakpoints.
class AppSizes {
  AppSizes._();

  static const double mobileBreakpoint = 480;
  static const double loginCardWidth = 430;
  static const double loadingCardWidth = 380;
  static const double inputMinHeight = 35;
  static const double inputActionSize = 28;
  static const double inputIconSize = 18;
  static const double fieldVerticalPadding = 7;
  static const double primaryButtonHeight = 48;
  static const double secondaryButtonHeight = 46;
  static const double compactPagePadding = 15;
  static const double compactCardHorizontalPadding = 24;
  static const double compactCardVerticalPadding = 30;
  static const double cardPadding = 40;
  static const double brandToHeadingGap = 31;
  static const double introToFormGap = 29;
  static const double formFieldGap = 18;
  static const double footerTopGap = 26;
  static const double labelLeftPadding = 5;
  static const double fieldHorizontalPadding = 14;
  static const double buttonLoaderSize = 20;
  static const double loadingIndicatorSize = 26;
  static const double mainMobileBreakpoint = 760;
  static const double sidebarWidth = 244;
  static const double sidebarMinWidth = 210;
  static const double sidebarMaxWidth = 420;
  static const double sidebarResizeHandleWidth = 8;
  static const double mobileSidebarWidth = 304;
  static const double shellTopBarHeight = 66;
  static const double companyLogoSize = 42;
  static const double profileAvatarSize = 34;
  static const double dialogButtonWidth = 96;
  static const double dialogButtonHeight = 40;
  static const double payrollCompactBreakpoint = 760;
  static const double payrollActionHeight = 42;
  static const double payrollTableMinWidth = 1020;
  static const double payrollTableHeaderHeight = 43;
  static const double payrollTableRowHeight = 56;
  static const double payrollEditorMaxWidth = 1200;
  static const double alertDialogWidth = 420;
  static const double alertIconSize = 58;
  static const double dropdownDialogWidth = 520;
  static const double dropdownDialogHeight = 580;
  static const double leaveTypesTableMinWidth = 900;
  static const double leaveTypesTableRowHeight = 51;
  static const double leaveTypeEditorWidth = 620;
  static const double payrollDefinitionsTableMinWidth = 820;
  static const double payrollPeriodTableMinWidth = 790;
  static const double payrollPeriodTableRowHeight = 55;
  static const double payrollPeriodDialogWidth = 540;
  static const double payrollMonthlyDialogWidth = 480;
  static const double balancesTableMinWidth = 1000;
  static const double balancesTableRowHeight = 51;
  static const double balanceEditorMaxWidth = 1200;
  static const double balanceBasedTableMinWidth = 700;
  static const double balanceBasedDialogWidth = 520;
  static const double loanAdvanceTypesTableMinWidth = 850;
  static const double loanAdvanceTypesTableRowHeight = 51;
  static const double loanAdvanceTypeEditorWidth = 620;
  static const double payrollRunsTableMinWidth = 1000;
  static const double payrollRunsTableRowHeight = 51;
  static const double payrollRunCreateDialogWidth = 620;
  static const double payrollRecipientsDialogWidth = 720;
  static const double payrollRunEmployeesTableMinWidth = 720;
  static const double payrollRunElementsTableMinWidth = 510;
  static const double payrollRunBalancesTableMinWidth = 430;
  static const double payrollRunDetailsRowHeight = 56;
  static const double publicHolidayDialogWidth = 520;
  static const double publicHolidayTwoColumnBreakpoint = 560;
  static const double publicHolidayThreeColumnBreakpoint = 820;
  static const double publicHolidayFourColumnBreakpoint = 1180;
  static const double legislationTableMinWidth = 600;
  static const double legislationTableRowHeight = 51;
  static const double legislationEditorMaxWidth = 1120;
  static const double legislationEditorMaxHeight = 860;
  static const double legislationEditorContentWidth = 1060;
  static const double employeesTableMinWidth = 1120;
  static const double employeesTableRowHeight = 58;
  static const double employeeFiltersMinWidth = 1180;
  static const double employeeFilterActionsWidth = 220;
  static const double employeeOverviewPanelHeight = 385;
  static const double employeePhotoColumnWidth = 230;
  static const double employeePhotoFallbackHeight = 268;
  static const double employeePhotoCompactHeight = 300;
  static const double employeePhotoActionsHeight = 35;
  static const double employeeRelatedTableMinWidth = 760;
  static const double employeeUtilityTableMinWidth = 1120;
  static const double employeeRecordDialogSmallWidth = 640;
  static const double employeeRecordDialogMediumWidth = 820;
  static const double employeeRecordDialogWideWidth = 980;
}

class AppDurations {
  AppDurations._();

  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 220);
  static const sidebar = Duration(milliseconds: 250);
}

class AppGradients {
  AppGradients._();

  static const pageBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.backgroundStart,
      AppColors.backgroundMiddle,
      AppColors.backgroundEnd,
    ],
    stops: [0, 0.5, 1],
  );

  static const primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryDark],
  );
}

double textFieldHeight = 35;
TextStyle textFieldFontStyle = const TextStyle(
  fontSize: 14,
  color: Colors.black,
);
SizedBox loadingProcess = SizedBox(
  height: 20,
  width: 20,
  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepTeal),
);
TextStyle textFieldLabelStyle = TextStyle(
  color: Colors.grey.shade700,
  fontSize: 12,
  fontWeight: FontWeight.bold,
);

class AppShadows {
  AppShadows._();

  static const loginCard = [
    BoxShadow(
      color: AppColors.cardShadow,
      blurRadius: 60,
      offset: Offset(0, 24),
    ),
  ];

  static const statusCard = [
    BoxShadow(
      color: AppColors.cardShadow,
      blurRadius: 50,
      offset: Offset(0, 20),
    ),
  ];

  static const primaryButton = [
    BoxShadow(
      color: AppColors.buttonShadow,
      blurRadius: 18,
      offset: Offset(0, 9),
    ),
  ];

  static const topBar = [
    BoxShadow(
      color: AppColors.topBarShadow,
      blurRadius: 12,
      offset: Offset(0, 3),
    ),
  ];

  static const contentCard = [
    BoxShadow(color: Color(0x14143336), blurRadius: 32, offset: Offset(0, 12)),
  ];
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading({double fontSize = 23}) {
    return GoogleFonts.plusJakartaSans(
      color: AppColors.textPrimary,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
    );
  }

  static TextStyle get brand => GoogleFonts.plusJakartaSans(
    color: AppColors.primary,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  static TextStyle get body => GoogleFonts.dmSans(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get bodyMuted =>
      body.copyWith(color: AppColors.textSecondary, height: 1.5);

  static TextStyle get fieldLabel => GoogleFonts.dmSans(
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get input => GoogleFonts.dmSans(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get hint => GoogleFonts.dmSans(
    color: AppColors.textHint,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get button => GoogleFonts.dmSans(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get link => GoogleFonts.dmSans(
    color: AppColors.primary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get error => GoogleFonts.dmSans(
    color: AppColors.errorText,
    fontSize: 12,
    height: 1.35,
  );

  static TextStyle get footer =>
      GoogleFonts.dmSans(color: AppColors.textFooter, fontSize: 11);

  static TextStyle get companyName => GoogleFonts.plusJakartaSans(
    color: AppColors.surface,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get sidebarLabel => GoogleFonts.dmSans(
    color: AppColors.sidebarLabel,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );

  static TextStyle get navigationItem => GoogleFonts.dmSans(
    color: AppColors.sidebarText,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get navigationItemSelected => navigationItem.copyWith(
    color: AppColors.surface,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get profileName => GoogleFonts.dmSans(
    color: AppColors.surface,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get profileDetail =>
      GoogleFonts.dmSans(color: AppColors.sidebarProfileText, fontSize: 10);

  static TextStyle get pageHeading => GoogleFonts.plusJakartaSans(
    color: AppColors.textPrimary,
    fontSize: 29,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static TextStyle get listCount =>
      GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13);

  static TextStyle get segment =>
      GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w800);

  static TextStyle get tableHeader => GoogleFonts.dmSans(
    color: Color(0xFF5E7775),
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.55,
  );

  static TextStyle get tableBody =>
      GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 13);

  static TextStyle get tableKey => GoogleFonts.dmSans(
    color: Color(0xFF446A68),
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
  );

  static TextStyle get badge =>
      GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800);

  static TextStyle get sectionTitle => GoogleFonts.dmSans(
    color: Color(0xFF244947),
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  static TextStyle get checkboxLabel => GoogleFonts.dmSans(
    color: Color(0xFF496663),
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
}

class AppDecorations {
  AppDecorations._();

  static const pageBackground = BoxDecoration(
    gradient: AppGradients.pageBackground,
  );

  static BoxDecoration loginCard({required bool compact}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(
        compact ? AppRadii.compactCard : AppRadii.card,
      ),
      boxShadow: AppShadows.loginCard,
    );
  }

  static final statusCard = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadii.statusCard),
    boxShadow: AppShadows.statusCard,
  );

  static final primaryButton = BoxDecoration(
    gradient: AppGradients.primaryButton,
    borderRadius: BorderRadius.circular(AppRadii.field),
    boxShadow: AppShadows.primaryButton,
  );

  static const sidebar = BoxDecoration(color: AppColors.sidebarBackground);

  static const topBar = BoxDecoration(
    color: AppColors.surface,
    boxShadow: AppShadows.topBar,
  );

  static final contentCard = BoxDecoration(
    color: AppColors.surface,
    border: Border.all(color: AppColors.border),
    borderRadius: BorderRadius.circular(AppRadii.section),
    boxShadow: AppShadows.contentCard,
  );
}

class AppButtonStyles {
  AppButtonStyles._();

  static final gradient = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(AppSizes.primaryButtonHeight),
    backgroundColor: Colors.transparent,
    disabledBackgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.field),
    ),
    textStyle: AppTextStyles.button,
  );

  static final link = TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    minimumSize: const Size(0, 40),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: AppTextStyles.link,
  );
}

/// The complete application theme. Add future component themes here rather
/// than styling each screen independently.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.primaryDark,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    final textTheme = GoogleFonts.dmSansTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      fontFamilyFallback: const ['Cairo'],
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      cardColor: AppColors.surface,
      dividerColor: AppColors.divider,
      disabledColor: AppColors.textHint,
      textTheme: textTheme.copyWith(
        headlineSmall: AppTextStyles.heading(),
        titleLarge: AppTextStyles.heading(fontSize: 20),
        bodyMedium: AppTextStyles.body,
        labelMedium: AppTextStyles.fieldLabel,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.heading(fontSize: 20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.fieldHorizontalPadding,
          vertical: AppSizes.fieldVerticalPadding,
        ),
        constraints: const BoxConstraints.tightFor(
          height: AppSizes.inputMinHeight,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: AppSizes.inputMinHeight,
          minHeight: AppSizes.inputMinHeight,
          maxHeight: AppSizes.inputMinHeight,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: AppSizes.inputMinHeight,
          minHeight: AppSizes.inputMinHeight,
          maxHeight: AppSizes.inputMinHeight,
        ),
        hintStyle: AppTextStyles.hint,
        labelStyle: AppTextStyles.fieldLabel,
        errorStyle: AppTextStyles.error,
        border: _fieldBorder(AppColors.border),
        enabledBorder: _fieldBorder(AppColors.border),
        focusedBorder: _fieldBorder(AppColors.primary, width: 1.3),
        errorBorder: _fieldBorder(AppColors.error),
        focusedErrorBorder: _fieldBorder(AppColors.error, width: 1.3),
        disabledBorder: _fieldBorder(AppColors.divider),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSizes.primaryButtonHeight),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.field),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.link,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.field),
          ),
          textStyle: AppTextStyles.button.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.primaryLight,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.field),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

// Compatibility helpers for existing code. New code should use AppTheme and
// AppTextStyles directly.
ThemeData buildAppTheme() => AppTheme.light();

TextStyle appHeadingStyle({double fontSize = 23}) {
  return AppTextStyles.heading(fontSize: fontSize);
}

Future<void> showError(String message) {
  return showAppAlertDialog(
    title: 'Could not complete the request',
    message: message,
    kind: AppAlertKind.error,
  );
}
