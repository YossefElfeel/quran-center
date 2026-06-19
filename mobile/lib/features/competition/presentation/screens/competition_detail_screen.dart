import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/competition_models.dart';
import '../controllers/competition_controllers.dart';

/// متقدّمو المسابقة + التحكيم (إدخال درجة /100 لكل متقدّم).
class CompetitionDetailScreen extends ConsumerWidget {
  const CompetitionDetailScreen({
    required this.competitionId,
    required this.competitionName,
    super.key,
  });

  final String competitionId;
  final String competitionName;

  Future<void> _score(
    BuildContext context,
    WidgetRef ref,
    CompetitionApplicationRow app,
  ) async {
    final AppL10n l = AppL10n.of(context);
    final TextEditingController c = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('${l.cmpScore} ${app.applicantName}'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.cmpScoreOutOf100),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.cmpSave),
          ),
        ],
      ),
    );
    final double? value = double.tryParse(c.text.trim());
    c.dispose();
    if (ok == true && value != null && value >= 0 && value <= 100) {
      try {
        await ref
            .read(competitionApplicationsProvider(competitionId).notifier)
            .score(app.id, value);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.cmpScoreForbidden)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<CompetitionApplicationRow>> state = ref.watch(
      competitionApplicationsProvider(competitionId),
    );
    final List<String> roles =
        ref.watch(currentRolesProvider).asData?.value ?? const <String>[];
    final bool isAdmin =
        roles.contains('admin') || roles.contains('super_admin');
    return AppScaffold(
      title: competitionName,
      actions: <Widget>[
        IconButton(
          tooltip: l.cmpResults,
          icon: const Icon(Icons.leaderboard),
          onPressed: () => context.go(
            Routes.competitionResults(competitionId, competitionName),
          ),
        ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.cmpApplicantsLoadError,
          onRetry: () =>
              ref.invalidate(competitionApplicationsProvider(competitionId)),
        ),
        data: (List<CompetitionApplicationRow> items) => items.isEmpty
            ? EmptyState(message: l.cmpNoApplicants, icon: Icons.how_to_reg)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final CompetitionApplicationRow a = items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.md,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.record_voice_over,
                        color: AppColors.primary,
                      ),
                      title: Text(a.applicantName),
                      subtitle: Text(a.status),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (isAdmin && a.status == 'pending') ...<Widget>[
                            IconButton(
                              tooltip: l.cmpAccept,
                              icon: const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                              ),
                              onPressed: () => ref
                                  .read(
                                    competitionApplicationsProvider(
                                      competitionId,
                                    ).notifier,
                                  )
                                  .setStatus(a.id, 'accepted'),
                            ),
                            IconButton(
                              tooltip: l.cmpReject,
                              icon: const Icon(
                                Icons.cancel,
                                color: AppColors.error,
                              ),
                              onPressed: () => ref
                                  .read(
                                    competitionApplicationsProvider(
                                      competitionId,
                                    ).notifier,
                                  )
                                  .setStatus(a.id, 'rejected'),
                            ),
                          ],
                          TextButton.icon(
                            icon: const Icon(Icons.grade),
                            label: Text(l.cmpScore),
                            onPressed: () => _score(context, ref, a),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
