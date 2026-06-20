import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_inline_banner.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../parent_portal/domain/child_history.dart';
import '../../../session/domain/tasmee_kind.dart';
import '../controllers/attention_detail_controllers.dart';

/// تفصيل طالب متعثّر: ليه متعثّر (المقطع + عدد المحاولات) + سجلّ محاولاته
/// (نمط التعثّر) — عشان المشرف يتدخّل بمعلومة.
class StrugglingStudentDetailScreen extends ConsumerWidget {
  const StrugglingStudentDetailScreen({
    required this.studentPersonId,
    required this.studentName,
    required this.portionName,
    required this.attempts,
    super.key,
  });

  final String studentPersonId;
  final String studentName;
  final String portionName;
  final int attempts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<TasmeeHistoryEntry>> state = ref.watch(
      studentTasmeeHistoryProvider(studentPersonId),
    );
    return AppScaffold(
      title: studentName,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppInlineBanner(
              message: l.supStrugglingDetail(
                portionName,
                arabicNumber(attempts),
              ),
              kind: AppBannerKind.warning,
            ),
          ),
          AppSectionHeader(title: l.supAttemptsHistory),
          state.when(
            loading: () => const AppListSkeleton(itemCount: 4),
            error: (Object e, StackTrace _) => AppErrorView(
              message: l.ppHistoryLoadError,
              onRetry: () =>
                  ref.invalidate(studentTasmeeHistoryProvider(studentPersonId)),
            ),
            data: (List<TasmeeHistoryEntry> items) => items.isEmpty
                ? EmptyState(
                    message: l.supNoAttempts,
                    icon: Icons.record_voice_over,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final TasmeeHistoryEntry t in items) _AttemptRow(t),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow(this.entry);

  final TasmeeHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final bool isRevision = entry.kind == TasmeeKind.revision;
    final Color color = entry.passed ? p.success : p.error;
    return AppListCard(
      leadingIcon: isRevision ? Icons.replay : Icons.menu_book,
      iconColor: isRevision ? p.accent : p.primary,
      title: entry.portionName.isEmpty
          ? (isRevision ? l.ppKindRevision : l.ppKindMemorization)
          : entry.portionName,
      subtitle:
          '${isRevision ? l.ppKindRevision : l.ppKindMemorization} · '
          '${arabicNumber(entry.date.day)}/${arabicNumber(entry.date.month)}/'
          '${arabicNumber(entry.date.year)}',
      trailing: Text(
        l.ppScoreOf10(arabicNumber(entry.score)),
        style: AppTextStyles.titleMd.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
