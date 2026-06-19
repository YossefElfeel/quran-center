import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/competition_models.dart';
import '../controllers/competition_controllers.dart';

/// نتائج المسابقة مرتّبة (تجميع المحكّمين + كسر التعادل).
class CompetitionResultsScreen extends ConsumerWidget {
  const CompetitionResultsScreen({
    required this.competitionId,
    required this.competitionName,
    super.key,
  });

  final String competitionId;
  final String competitionName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<CompetitionResultRow>> state = ref.watch(
      competitionResultsProvider(competitionId),
    );
    return AppScaffold(
      title: '${l.cmpResultsTitle} $competitionName',
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.cmpResultsLoadError,
          onRetry: () =>
              ref.invalidate(competitionResultsProvider(competitionId)),
        ),
        data: (List<CompetitionResultRow> items) => items.isEmpty
            ? EmptyState(message: l.cmpNoResults, icon: Icons.leaderboard)
            : AppRefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(competitionResultsProvider(competitionId)),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) {
                    final CompetitionResultRow r = items[i];
                    final AppPalette p = context.palette;
                    return AppListCard(
                      leading: CircleAvatar(
                        backgroundColor: i == 0 ? p.accent : p.primary,
                        child: Text(
                          arabicNumber(i + 1),
                          style: TextStyle(color: p.onPrimary),
                        ),
                      ),
                      title: r.applicantName,
                      subtitle:
                          '${l.cmpJudgeCount}: ${arabicNumber(r.judgeCount)}',
                      trailing: Text(
                        arabicNumber(r.average.round()),
                        style: AppTextStyles.titleLg.copyWith(
                          fontWeight: FontWeight.bold,
                          color: p.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
