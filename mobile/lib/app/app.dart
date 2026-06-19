import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../shared/theme/app_theme.dart';
import 'router/app_router.dart';

/// جذر التطبيق — MaterialApp.router بثيم + عربي RTL + go_router.
class QuranCenterApp extends ConsumerWidget {
  const QuranCenterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) => AppL10n.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routerConfig: router,
      builder: (BuildContext context, Widget? child) {
        // التطبيق عربي بالكامل → نفرض RTL.
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
