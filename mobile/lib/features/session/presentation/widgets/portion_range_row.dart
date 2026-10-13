import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_search_picker.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/surah_option.dart';

/// صف اختيار طرف نطاق (سورة + آية) — مشترك بين تحديد المقطع وخطة المراجعة.
class PortionRangeRow extends StatelessWidget {
  const PortionRangeRow({
    required this.title,
    required this.surahs,
    required this.surah,
    required this.onSurah,
    required this.ayahController,
    super.key,
  });

  final String title;
  final List<SurahOption> surahs;
  final int? surah;
  final ValueChanged<int?> onSurah;
  final TextEditingController ayahController;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Row(
      children: <Widget>[
        SizedBox(
          width: 48,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: OutlinedButton(
            onPressed: () async {
              final SurahOption? choice =
                  await showAppSearchPicker<SurahOption>(
                    context: context,
                    title: l.sesSurahHint,
                    items: surahs,
                    label: (SurahOption s) => s.name,
                  );
              if (choice != null) onSurah(choice.number);
            },
            child: Text(
              surah == null
                  ? l.sesSurahHint
                  : surahs
                        .firstWhere(
                          (SurahOption s) => s.number == surah,
                          // سورة مش في القايمة (داتا قديمة/ناقصة) — منقعش.
                          orElse: () => SurahOption(
                            number: surah!,
                            name: l.sesSurahHint,
                            ayahCount: 0,
                          ),
                        )
                        .name,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: AppTextField(
            controller: ayahController,
            keyboardType: TextInputType.number,
            label: l.sesAyahLabel,
          ),
        ),
      ],
    );
  }
}

/// مشكلة في نطاق المقطع (الرسالة من [PortionRangeIssueLabel.label]).
enum PortionRangeIssue {
  incomplete,
  startAyahOutOfRange,
  endAyahOutOfRange,
  endBeforeStart,
}

extension PortionRangeIssueLabel on PortionRangeIssue {
  String label(AppL10n l) => switch (this) {
    PortionRangeIssue.incomplete => l.sesRangeIncomplete,
    PortionRangeIssue.startAyahOutOfRange => l.sesRangeStartAyahTooLarge,
    PortionRangeIssue.endAyahOutOfRange => l.sesRangeEndAyahTooLarge,
    PortionRangeIssue.endBeforeStart => l.sesRangeEndBeforeStart,
  };
}

/// تحقّق نطاق المقطع: الخانات كاملة + الآيات في حدود السورة + الترتيب صح.
/// بيرجّع نوع المشكلة أو null لو سليم.
PortionRangeIssue? portionRangeError({
  required List<SurahOption> surahs,
  required String name,
  required int? surahStart,
  required int? ayahStart,
  required int? surahEnd,
  required int? ayahEnd,
}) {
  if (name.isEmpty ||
      surahStart == null ||
      ayahStart == null ||
      surahEnd == null ||
      ayahEnd == null ||
      ayahStart <= 0 ||
      ayahEnd <= 0) {
    return PortionRangeIssue.incomplete;
  }
  final SurahOption? start = _surahByNumber(surahs, surahStart);
  final SurahOption? end = _surahByNumber(surahs, surahEnd);
  if (start != null && ayahStart > start.ayahCount) {
    return PortionRangeIssue.startAyahOutOfRange;
  }
  if (end != null && ayahEnd > end.ayahCount) {
    return PortionRangeIssue.endAyahOutOfRange;
  }
  if (surahEnd < surahStart ||
      (surahEnd == surahStart && ayahEnd < ayahStart)) {
    return PortionRangeIssue.endBeforeStart;
  }
  return null;
}

SurahOption? _surahByNumber(List<SurahOption> surahs, int number) {
  for (final SurahOption s in surahs) {
    if (s.number == number) return s;
  }
  return null;
}
