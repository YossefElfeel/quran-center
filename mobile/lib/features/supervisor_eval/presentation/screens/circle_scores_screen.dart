import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_inline_banner.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../progress_engine/domain/ledger_state.dart';
import '../../domain/circle_roster_score.dart';
import '../controllers/attention_detail_controllers.dart';

/// تفصيل حلقة من لوحة الانتباه: المقطع الحالي + حالة كل طالب عليه (متعثّر أولًا).
class CircleScoresScreen extends ConsumerWidget {
  const CircleScoresScreen({
    required this.circleId,
    required this.circleName,
    super.key,
  });

  final String circleId;
  final String circleName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<CircleScores> state = ref.watch(
      circleRosterScoresProvider(circleId),
    );
    return AppScaffold(
      title: circleName,
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.supCirclesLoadError,
          onRetry: () => ref.invalidate(circleRosterScoresProvider(circleId)),
        ),
        data: (CircleScores scores) => AppRefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(circleRosterScoresProvider(circleId)),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppInlineBanner(
                  message: scores.portionName == null
                      ? l.supCircleNoCurrentPortion
                      : l.supCirclePortionLabel(scores.portionName!),
                  kind: AppBannerKind.info,
                ),
              ),
              if (scores.students.isEmpty)
                EmptyState(
                  message: l.supNoStudentsInCircle,
                  icon: Icons.groups_outlined,
                )
              else
                for (final CircleRosterScore s in scores.students)
                  _ScoreRow(score: s),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.score});

  final CircleRosterScore score;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final (
      String label,
      AppStatusKind kind,
      IconData icon,
      Color color,
    ) = switch (score.state) {
      LedgerState.passed => (
        l.supScorePassed,
        AppStatusKind.success,
        Icons.check_circle,
        p.success,
      ),
      LedgerState.failedRetry => (
        l.supScoreFailed,
        AppStatusKind.error,
        Icons.warning_amber,
        p.error,
      ),
      _ => (
        l.supScorePending,
        AppStatusKind.neutral,
        Icons.hourglass_empty,
        p.textSecondary,
      ),
    };
    return AppListCard(
      leadingIcon: icon,
      iconColor: color,
      title: score.studentName,
      trailing: AppStatusBadge(label: label, kind: kind),
    );
  }
}
