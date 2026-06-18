import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
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
    final AsyncValue<List<CompetitionResultRow>> state = ref.watch(
      competitionResultsProvider(competitionId),
    );
    return AppScaffold(
      title: 'نتائج $competitionName',
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل النتائج',
          onRetry: () =>
              ref.invalidate(competitionResultsProvider(competitionId)),
        ),
        data: (List<CompetitionResultRow> items) => items.isEmpty
            ? const EmptyState(
                message: 'مفيش نتائج لسه (محتاج متقدّمين مقبولين + درجات)',
                icon: Icons.leaderboard,
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final CompetitionResultRow r = items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.md,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: i == 0
                            ? AppColors.accent
                            : AppColors.primary,
                        child: Text(
                          arabicNumber(i + 1),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(r.applicantName),
                      subtitle: Text(
                        'عدد المحكّمين: ${arabicNumber(r.judgeCount)}',
                      ),
                      trailing: Text(
                        arabicNumber(r.average.round()),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
