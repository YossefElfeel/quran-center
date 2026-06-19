import 'package:flutter/material.dart';

import 'app_text_styles.dart';
import 'tokens.dart';

/// ثيم التطبيق — Material 3، عربي RTL، خط Cairo، لوحة "Emerald Nour".
/// يدعم Light / Dark / AMOLED. الألوان السيمانتيك بتتسجّل عبر [AppPalette].
abstract final class AppTheme {
  const AppTheme._();

  static const String fontFamily = AppTextStyles.fontFamily;

  static ThemeData light() => _build(AppPalette.light, Brightness.light);
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);
  static ThemeData amoled() => _build(AppPalette.amoled, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: isDark ? p.primaryDeep : const Color(0xFFD7F0E6),
      onPrimaryContainer: isDark ? p.textPrimary : p.primaryDeep,
      secondary: p.accent,
      onSecondary: const Color(0xFF2A1F00),
      secondaryContainer: p.accent.withValues(alpha: 0.18),
      onSecondaryContainer: isDark ? p.accentHi : const Color(0xFF4A3700),
      error: p.error,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.textPrimary,
      surfaceContainerHighest: p.surfaceVariant,
      surfaceContainerHigh: p.surfaceVariant,
      surfaceContainer: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainerLowest: p.background,
      onSurfaceVariant: p.textSecondary,
      outline: p.border,
      outlineVariant: p.border,
      shadow: p.shadowColor,
      scrim: Colors.black,
      inverseSurface: isDark ? p.textPrimary : const Color(0xFF1B1B1B),
      onInverseSurface: isDark ? p.background : Colors.white,
      inversePrimary: p.primary,
      tertiary: p.info,
      onTertiary: Colors.white,
    );

    final TextTheme textTheme = AppTextStyles.textTheme(
      p.textPrimary,
      p.textSecondary,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: p.background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[p],
    );

    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide.none,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: AppElevation.e2,
        shadowColor: p.shadowColor.withValues(alpha: 0.2),
        iconTheme: IconThemeData(color: p.primary),
        actionsIconTheme: IconThemeData(color: p.primary),
        titleTextStyle: AppTextStyles.titleLg.copyWith(color: p.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: AppElevation.e0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: p.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: p.border, width: 0.6),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: p.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: p.error, width: 1.2),
        ),
        labelStyle: AppTextStyles.bodyMd.copyWith(color: p.textSecondary),
        hintStyle: AppTextStyles.bodyMd.copyWith(color: p.textSecondary),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.primaryButtonHeight),
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.primary.withValues(alpha: 0.45),
          disabledForegroundColor: p.onPrimary.withValues(alpha: 0.8),
          elevation: 0,
          textStyle: AppTextStyles.titleMd.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.primaryButtonHeight),
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.primaryButtonHeight),
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: AppTextStyles.labelLg,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navBarHeight,
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.e2,
        shadowColor: p.shadowColor,
        indicatorColor: p.primary.withValues(alpha: AppOpacity.chipBg),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? p.primary
                : p.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (Set<WidgetState> s) => AppTextStyles.labelSm.copyWith(
            color: s.contains(WidgetState.selected)
                ? p.primary
                : p.textSecondary,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.primary.withValues(alpha: AppOpacity.chipBg),
        selectedIconTheme: IconThemeData(color: p.primary),
        unselectedIconTheme: IconThemeData(color: p.textSecondary),
        selectedLabelTextStyle: AppTextStyles.labelSm.copyWith(
          color: p.primary,
        ),
        unselectedLabelTextStyle: AppTextStyles.labelSm.copyWith(
          color: p.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        titleTextStyle: AppTextStyles.titleLg.copyWith(color: p.textPrimary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.primary.withValues(alpha: AppOpacity.chipBg),
        side: BorderSide.none,
        labelStyle: AppTextStyles.labelLg.copyWith(color: p.primary),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        contentTextStyle: AppTextStyles.bodyMd.copyWith(color: Colors.white),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 0.6),
      listTileTheme: ListTileThemeData(
        iconColor: p.primary,
        textColor: p.textPrimary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      iconTheme: IconThemeData(color: p.primary),
    );
  }
}
