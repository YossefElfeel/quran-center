import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../shared/theme/app_theme.dart';
import '../shared/theme/display_prefs.dart';
import '../shared/theme/theme_mode_provider.dart';
import 'router/app_router.dart';

/// جذر التطبيق — MaterialApp.router بثيم + عربي RTL + go_router.
class QuranCenterApp extends ConsumerWidget {
  const QuranCenterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    final AppThemeChoice themeChoice = ref.watch(themeChoiceProvider);
    final bool highContrast = ref.watch(highContrastProvider);
    final AppTextSize textSize = ref.watch(textSizeProvider);

    final ThemeData lightTheme = highContrast
        ? AppTheme.highContrastLight()
        : AppTheme.light();
    final ThemeData darkTheme = highContrast
        ? AppTheme.highContrastDark()
        : (themeChoice == AppThemeChoice.amoled
              ? AppTheme.amoled()
              : AppTheme.dark());

    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) => AppL10n.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      // لو النظام نفسه مفعّل عليه تباين عالي → نديله لوحة التباين العالي كمان.
      highContrastTheme: AppTheme.highContrastLight(),
      highContrastDarkTheme: AppTheme.highContrastDark(),
      themeMode: themeModeFor(themeChoice),
      locale: const Locale('ar'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routerConfig: router,
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mq = MediaQuery.of(context);
        // التطبيق عربي بالكامل → نفرض RTL؛ ونطبّق مقياس الخطّ المختار.
        return MediaQuery(
          data: mq.copyWith(
            textScaler: combinedTextScaler(mq.textScaler, textSize),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
