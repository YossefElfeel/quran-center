import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/competition_models.dart';
import '../controllers/competition_controllers.dart';

/// قايمة المسابقات (الأدمن يضيف؛ الكل يفتح).
class CompetitionsScreen extends ConsumerWidget {
  const CompetitionsScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final AppL10n l = AppL10n.of(context);
    final TextEditingController name = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.cmpNewCompetition),
        content: AppTextField(
          controller: name,
          autofocus: true,
          label: l.cmpCompetitionName,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.add),
          ),
        ],
      ),
    );
    final String text = name.text;
    name.dispose();
    if (ok == true) await ref.read(competitionsProvider.notifier).create(text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<CompetitionRow>> state = ref.watch(
      competitionsProvider,
    );
    return AppScaffold(
      title: l.navCompetitions,
      actions: <Widget>[
        IconButton(
          tooltip: l.cmpNewCompetition,
          icon: const Icon(Icons.add),
          onPressed: () => _add(context, ref),
        ),
      ],
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.cmpLoadError,
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (List<CompetitionRow> items) => items.isEmpty
            ? EmptyState(message: l.cmpEmpty, icon: Icons.emoji_events)
            : AppRefreshIndicator(
                onRefresh: () async => ref.invalidate(competitionsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) => AppListCard(
                    leadingIcon: Icons.emoji_events,
                    iconColor: context.palette.accent,
                    title: items[i].name,
                    onTap: () => context.push(
                      Routes.competitionDetail(items[i].id, items[i].name),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
