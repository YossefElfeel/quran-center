import 'package:flutter/material.dart';

/// ألوان التطبيق (design tokens) — مصدر واحد للألوان.
///
/// القيم دي هي **لوحة Emerald Nour (Light)**. الـ widgets القديمة لسه بتستعملها
/// مباشرةً؛ في مرحلة التحويل (P2) بننقلها تدريجيًا لـ [AppPalette] عشان الدارك
/// يشتغل صح. للوضع الفاتح القيم هنا = نفس قيم `AppPalette.light`.
abstract final class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF0C7C59); // زمرّدي أغنى
  static const Color primaryDark = Color(0xFF0A5C43);
  static const Color primaryDeep = Color(0xFF073A2B);
  static const Color accent = Color(0xFFC8A03C); // ذهبي
  static const Color accentHi = Color(0xFFE6C463);
  static const Color background = Color(0xFFF7F8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF1EC);
  static const Color textPrimary = Color(0xFF14241D);
  static const Color textSecondary = Color(0xFF5B6B63);
  static const Color border = Color(0xFFE2E7E1);
  static const Color error = Color(0xFFC0392B);
  static const Color success = Color(0xFF1E8E5A);
  static const Color warning = Color(0xFFC98A1A);
  static const Color info = Color(0xFF2D6CC0);
}

/// مقياس المسافات الموحّد.
abstract final class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// أنصاف أقطار الزوايا.
abstract final class AppRadii {
  const AppRadii._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 999;
}

/// مقاسات لمس دنيا (سهولة وصول للمستخدم غير التقني).
abstract final class AppSizes {
  const AppSizes._();

  static const double minTouch = 48;
  static const double primaryButtonHeight = 56;
  static const double navBarHeight = 74;
  static const double iconButton = 44;
}

/// مستويات الارتفاع + ظِلال ناعمة (M3 tint بيبان مسطّح فبنستعمل ظلّ صريح).
abstract final class AppElevation {
  const AppElevation._();

  static const double e0 = 0;
  static const double e1 = 1;
  static const double e2 = 3;
  static const double e3 = 6;

  static List<BoxShadow> shadowSm(Color base) => <BoxShadow>[
    BoxShadow(
      color: base.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd(Color base) => <BoxShadow>[
    BoxShadow(
      color: base.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> shadowLg(Color base) => <BoxShadow>[
    BoxShadow(
      color: base.withValues(alpha: 0.12),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];
}

/// شفافيّات موحّدة (بدل الأرقام السحرية المتناثرة).
abstract final class AppOpacity {
  const AppOpacity._();

  static const double surfaceTint = 0.05;
  static const double hover = 0.08;
  static const double chipBg = 0.12;
  static const double badgeTint = 0.14;
  static const double disabled = 0.38;
  static const double scrim = 0.55;
}

/// امتداد الثيم اللي بيحمل ألوان السيمانتيك اللي مش موجودة بنظافة في
/// [ColorScheme] (نجاح/تحذير/معلومة/ذهبي/تدرّج الـ hero/حالة المزامنة)،
/// مع نسخ فاتح/داكن/AMOLED. ده اللي بيخلّي الدارك يشتغل في كل مكان.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primaryDeep,
    required this.onPrimary,
    required this.accent,
    required this.accentHi,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.heroGradient,
    required this.offline,
    required this.syncPending,
    required this.synced,
    required this.shadowColor,
  });

  final Color primary;
  final Color primaryDeep;
  final Color onPrimary;
  final Color accent;
  final Color accentHi;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final List<Color> heroGradient;
  final Color offline;
  final Color syncPending;
  final Color synced;
  final Color shadowColor;

  /// نسخة الـ Light (Emerald Nour) — مطابقة لـ [AppColors].
  static const AppPalette light = AppPalette(
    primary: Color(0xFF0C7C59),
    primaryDeep: Color(0xFF073A2B),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFC8A03C),
    accentHi: Color(0xFFE6C463),
    background: Color(0xFFF7F8F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEEF1EC),
    textPrimary: Color(0xFF14241D),
    textSecondary: Color(0xFF5B6B63),
    border: Color(0xFFE2E7E1),
    success: Color(0xFF1E8E5A),
    warning: Color(0xFFC98A1A),
    error: Color(0xFFC0392B),
    info: Color(0xFF2D6CC0),
    heroGradient: <Color>[
      Color(0xFF0C7C59),
      Color(0xFF0A5C43),
      Color(0xFF073A2B),
    ],
    offline: Color(0xFF5B6B63),
    syncPending: Color(0xFFC98A1A),
    synced: Color(0xFF1E8E5A),
    shadowColor: Color(0xFF0A1F18),
  );

  /// نسخة الـ Dark.
  static const AppPalette dark = AppPalette(
    primary: Color(0xFF2BB888),
    primaryDeep: Color(0xFF0F2A20),
    onPrimary: Color(0xFF06231A),
    accent: Color(0xFFE6C463),
    accentHi: Color(0xFFF1D789),
    background: Color(0xFF0E1512),
    surface: Color(0xFF16201B),
    surfaceVariant: Color(0xFF1E2A24),
    textPrimary: Color(0xFFECF2EE),
    textSecondary: Color(0xFF9DB0A6),
    border: Color(0xFF27352E),
    success: Color(0xFF3FB97E),
    warning: Color(0xFFE0A93C),
    error: Color(0xFFE05B4C),
    info: Color(0xFF5A95E0),
    heroGradient: <Color>[
      Color(0xFF13513C),
      Color(0xFF0F3A2C),
      Color(0xFF0A2A20),
    ],
    offline: Color(0xFF9DB0A6),
    syncPending: Color(0xFFE0A93C),
    synced: Color(0xFF3FB97E),
    shadowColor: Color(0xFF000000),
  );

  /// نسخة AMOLED (أسود نقي للخلفيات).
  static const AppPalette amoled = AppPalette(
    primary: Color(0xFF2BB888),
    primaryDeep: Color(0xFF0A2A20),
    onPrimary: Color(0xFF06231A),
    accent: Color(0xFFE6C463),
    accentHi: Color(0xFFF1D789),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    surfaceVariant: Color(0xFF141414),
    textPrimary: Color(0xFFECF2EE),
    textSecondary: Color(0xFF9DB0A6),
    border: Color(0xFF1C1C1C),
    success: Color(0xFF3FB97E),
    warning: Color(0xFFE0A93C),
    error: Color(0xFFE05B4C),
    info: Color(0xFF5A95E0),
    heroGradient: <Color>[
      Color(0xFF0F3A2C),
      Color(0xFF09231B),
      Color(0xFF000000),
    ],
    offline: Color(0xFF9DB0A6),
    syncPending: Color(0xFFE0A93C),
    synced: Color(0xFF3FB97E),
    shadowColor: Color(0xFF000000),
  );

  /// تباين عالي (فاتح) — نصّ أسود نقي، حدود واضحة، ألوان سيمانتيك أغمق.
  static const AppPalette highContrastLight = AppPalette(
    primary: Color(0xFF0A5C43),
    primaryDeep: Color(0xFF052E22),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFF8A6D14),
    accentHi: Color(0xFFB68F1E),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE7ECE8),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF2E3A34),
    border: Color(0xFF5A6660),
    success: Color(0xFF0F6B3F),
    warning: Color(0xFF8A5E00),
    error: Color(0xFF9E2218),
    info: Color(0xFF134C92),
    heroGradient: <Color>[
      Color(0xFF0A5C43),
      Color(0xFF074733),
      Color(0xFF052E22),
    ],
    offline: Color(0xFF2E3A34),
    syncPending: Color(0xFF8A5E00),
    synced: Color(0xFF0F6B3F),
    shadowColor: Color(0xFF000000),
  );

  /// تباين عالي (داكن) — نصّ أبيض نقي على أسود، حدود واضحة.
  static const AppPalette highContrastDark = AppPalette(
    primary: Color(0xFF3FD99F),
    primaryDeep: Color(0xFF0A2A20),
    onPrimary: Color(0xFF00130C),
    accent: Color(0xFFF1D789),
    accentHi: Color(0xFFF7E6AC),
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    surfaceVariant: Color(0xFF1A1A1A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFD8E4DD),
    border: Color(0xFF6A7A72),
    success: Color(0xFF5FD99E),
    warning: Color(0xFFF2C158),
    error: Color(0xFFFF7A6B),
    info: Color(0xFF79AEF5),
    heroGradient: <Color>[
      Color(0xFF115540),
      Color(0xFF0B3528),
      Color(0xFF000000),
    ],
    offline: Color(0xFFD8E4DD),
    syncPending: Color(0xFFF2C158),
    synced: Color(0xFF5FD99E),
    shadowColor: Color(0xFF000000),
  );

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryDeep,
    Color? onPrimary,
    Color? accent,
    Color? accentHi,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    List<Color>? heroGradient,
    Color? offline,
    Color? syncPending,
    Color? synced,
    Color? shadowColor,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      accentHi: accentHi ?? this.accentHi,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      heroGradient: heroGradient ?? this.heroGradient,
      offline: offline ?? this.offline,
      syncPending: syncPending ?? this.syncPending,
      synced: synced ?? this.synced,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    List<Color> lerpGradient(List<Color> a, List<Color> b) {
      final int n = a.length < b.length ? a.length : b.length;
      return <Color>[
        for (int i = 0; i < n; i++) Color.lerp(a[i], b[i], t) ?? a[i],
      ];
    }

    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHi: Color.lerp(accentHi, other.accentHi, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      heroGradient: lerpGradient(heroGradient, other.heroGradient),
      offline: Color.lerp(offline, other.offline, t)!,
      syncPending: Color.lerp(syncPending, other.syncPending, t)!,
      synced: Color.lerp(synced, other.synced, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}

/// وصول سريع للوحة الحالية: `context.palette.primary`.
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
