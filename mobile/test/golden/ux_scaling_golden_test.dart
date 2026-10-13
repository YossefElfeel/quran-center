@Tags(<String>['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/features/feedback/presentation/widgets/complaint_compose_sheet.dart';
import 'package:quran_center/features/session/domain/attendance_status.dart';
import 'package:quran_center/features/session/domain/roster_entry.dart';
import 'package:quran_center/features/session/presentation/widgets/score_pad.dart';
import 'package:quran_center/features/session/presentation/widgets/student_tile.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:quran_center/shared/theme/app_theme.dart';
import 'package:quran_center/shared/theme/tokens.dart';
import 'package:quran_center/shared/widgets/app_list_card.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Cairo')
      ..addFont(rootBundle.load('assets/fonts/Cairo.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  final cases = <String, Widget>{
    'dashboard_tile_200': AppListCard(
      title: 'حلقة محمد عبد الرحمن',
      subtitle: 'الحصة اتقفلت — ٢٢ حضور، ١٨ تسميع، ٣ غياب',
      leadingIcon: Icons.menu_book,
      onTap: () {},
    ),
    'student_tile_200': StudentTile(
      entry: const RosterEntry(
        enrollmentId: 'e',
        studentPersonId: 'p',
        studentName: 'محمد عبد الرحمن محمد أحمد',
        attendance: AttendanceStatus.absent,
      ),
      canRecordTasmee: true,
      onAttendanceChanged: (_) {},
      onTasmee: () {},
      onNote: () {},
      onRequestExcuse: () {},
    ),
    'score_pad_200': ScorePad(selected: 8, threshold: 7, onSelected: (_) {}),
    'complaint_sheet_200': const ComplaintComposeSheet(),
  };
  for (final entry in cases.entries) {
    testWidgets(entry.key, (tester) async {
      tester.view.physicalSize = const Size(375, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            locale: const Locale('ar'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: RepaintBoundary(
                key: const ValueKey('snapshot'),
                child: ColoredBox(
                  color: AppPalette.light.background,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(child: entry.value),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('snapshot')),
        matchesGoldenFile(
          'goldens/${Platform.operatingSystem}/${entry.key}.png',
        ),
      );
    });
  }
}
