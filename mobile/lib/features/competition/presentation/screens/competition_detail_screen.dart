import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final TextEditingController c = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('درجة ${app.applicantName}'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'الدرجة (من ١٠٠)'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حفظ'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('مينفعش تدرّج — لازم تكون محكّم')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          tooltip: 'النتائج',
          icon: const Icon(Icons.leaderboard),
          onPressed: () => context.go(
            Routes.competitionResults(competitionId, competitionName),
          ),
        ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل المتقدّمين',
          onRetry: () =>
              ref.invalidate(competitionApplicationsProvider(competitionId)),
        ),
        data: (List<CompetitionApplicationRow> items) => items.isEmpty
            ? const EmptyState(
                message: 'مفيش متقدّمين لسه',
                icon: Icons.how_to_reg,
              )
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
                              tooltip: 'قبول',
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
                              tooltip: 'رفض',
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
                            label: const Text('درجة'),
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
