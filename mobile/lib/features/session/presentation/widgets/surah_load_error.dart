import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../controllers/surahs_controller.dart';

/// فشل تحميل قائمة السور جوّا شيتات المقطع — مع زر إعادة محاولة.
///
/// مهم: [surahsProvider] فيه keepAlive، فلو فشل التحميل مرّة (مثلًا سباق
/// عند فتح التطبيق قبل ما الجلسة تترجّع) بيفضل فاشل لحد ما نعمله invalidate.
/// من غير الزر ده المعلّم بيتحبس ومش قادر يحدّد مقطع → الحصة كلها متوقّفة.
class SurahLoadError extends ConsumerWidget {
  const SurahLoadError({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: AppSpacing.md),
        Icon(Icons.cloud_off_outlined, color: p.error, size: 40),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l.sesSurahsLoadError,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLg.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: l.retry,
          icon: Icons.refresh,
          variant: AppButtonVariant.tonal,
          expanded: false,
          onPressed: () => ref.invalidate(surahsProvider),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
