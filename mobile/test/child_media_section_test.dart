import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/core/auth/auth_providers.dart';
import 'package:quran_center/features/media/domain/media_item.dart';
import 'package:quran_center/features/media/presentation/controllers/child_media_controller.dart';
import 'package:quran_center/features/media/presentation/widgets/child_media_section.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpSection(WidgetTester tester, List<String> roles) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childMediaProvider('s1').overrideWith((ref) async => <MediaItem>[]),
          currentRolesProvider.overrideWith((ref) async => roles),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(body: ChildMediaSection(studentPersonId: 's1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('زر الرفع مخفي لولي الأمر', (WidgetTester tester) async {
    await pumpSection(tester, <String>['parent']);
    expect(find.byIcon(Icons.add_a_photo), findsNothing);
  });

  testWidgets('زر الرفع ظاهر للأدمن (دور مصرّح)', (WidgetTester tester) async {
    await pumpSection(tester, <String>['admin']);
    expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
  });
}
