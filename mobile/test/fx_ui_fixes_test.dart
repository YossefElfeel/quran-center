import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_center/core/utils/bidi.dart';
import 'package:quran_center/features/feedback/domain/complaint.dart';
import 'package:quran_center/features/notifications/domain/app_notification.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:quran_center/shared/presentation/relative_date.dart';
import 'package:quran_center/shared/theme/app_theme.dart';
import 'package:quran_center/shared/widgets/app_segmented_control.dart';

void main() {
  final AppL10n l = lookupAppL10n(const Locale('ar'));
  final DateTime now = DateTime(2026, 10, 13, 15);

  test('relative day label: today / yesterday / days ago / date', () {
    expect(
      relativeDayLabel(l, DateTime(2026, 10, 13, 1), now: now),
      'النهارده',
    );
    expect(relativeDayLabel(l, DateTime(2026, 10, 12, 23), now: now), 'امبارح');
    expect(relativeDayLabel(l, DateTime(2026, 10, 11), now: now), 'من يومين');
    expect(relativeDayLabel(l, DateTime(2026, 10, 10), now: now), 'من ٣ أيام');
    expect(relativeDayLabel(l, DateTime(2026, 10, 1), now: now), '١ أكتوبر');
    expect(
      relativeDayLabel(l, DateTime(2025, 12, 30), now: now),
      '٣٠ ديسمبر ٢٠٢٥',
    );
  });

  test('complaint short reference = last 4 of the reference number', () {
    const String id = 'ba07a183-1111-2222-3333-444455556666';
    expect(complaintReferenceNumber(id), 'BA07A183');
    expect(complaintShortReference(id), '#A183');
    expect(ltrIsolate('#A183').runes.first, 0x2066);
    expect(ltrIsolate('#A183').runes.last, 0x2069);
  });

  test('notification parses complaint_id from route_data', () {
    final AppNotification n = AppNotification.fromMap(<String, dynamic>{
      'id': 'n1',
      'type': 'complaint_overdue',
      'title': 't',
      'created_at': '2026-10-13T10:00:00Z',
      'route_data': <String, dynamic>{'complaint_id': 'abc'},
    });
    expect(n.complaintId, 'abc');
  });

  for (final (String name, ThemeData theme) in <(String, ThemeData)>[
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
    ('amoled', AppTheme.amoled()),
    ('hcLight', AppTheme.highContrastLight()),
    ('hcDark', AppTheme.highContrastDark()),
  ]) {
    testWidgets('segmented control selection is primary-family ($name)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: AppSegmentedControl<int>(
              segments: const <({int value, String label})>[
                (value: 0, label: 'a'),
                (value: 1, label: 'b'),
              ],
              selected: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      final ButtonStyle style = theme.segmentedButtonTheme.style!;
      final Color bg = style.backgroundColor!.resolve(<WidgetState>{
        WidgetState.selected,
      })!;
      final Color fg = style.foregroundColor!.resolve(<WidgetState>{
        WidgetState.selected,
      })!;
      // مش ذهبي (secondaryContainer) — ومقروء (≥ ٤٫٥:١).
      expect(bg, isNot(theme.colorScheme.secondaryContainer));
      final double a = bg.computeLuminance(), b = fg.computeLuminance();
      final double ratio = ((a > b ? a : b) + .05) / ((a < b ? a : b) + .05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  }
}
