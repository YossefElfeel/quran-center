import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_async_form_sheet.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_paged_list.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/dispose_with.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/competition_repository.dart';
import '../../domain/competition_models.dart';
import '../controllers/competition_controllers.dart';

/// قايمة المسابقات (الأدمن يضيف؛ الكل يفتح).
class CompetitionsScreen extends ConsumerWidget {
  const CompetitionsScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final AppL10n l = AppL10n.of(context);
    final TextEditingController name = TextEditingController();
    await showAppModalSheet<void>(
      context: context,
      title: l.cmpNewCompetition,
      builder: (BuildContext context) => DisposeWith(
        notifiers: <ChangeNotifier>[name],
        child: AppAsyncFormSheet(
          submitLabel: l.add,
          successMessage: l.cmpCompetitionAdded,
          onSubmit: () =>
              ref.read(competitionsProvider.notifier).create(name.text.trim()),
          fields: [
            AppTextField(
              controller: name,
              autofocus: true,
              label: l.cmpCompetitionName,
              validator: (v) =>
                  (v?.trim().length ?? 0) < 2 ? l.cmpNameRequired : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final roles = ref.watch(currentRolesProvider).asData?.value ?? <String>[];
    final isAdmin = roles.any((r) => r == 'admin' || r == 'super_admin');
    final AsyncValue<List<CompetitionRow>> state = ref.watch(
      competitionsProvider,
    );
    return AppScaffold(
      title: l.navCompetitions,
      actions: <Widget>[
        if (isAdmin)
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
            ? EmptyState(
                message: l.cmpEmpty,
                icon: Icons.emoji_events,
                action: TextButton(
                  onPressed: () {
                    if (isAdmin) {
                      _add(context, ref);
                    } else {
                      ref.invalidate(competitionsProvider);
                    }
                  },
                  child: Text(isAdmin ? l.cmpNewCompetition : l.commonRefresh),
                ),
              )
            : AppRefreshIndicator(
                onRefresh: () async => ref.invalidate(competitionsProvider),
                child: AppPagedList<CompetitionRow>(
                  items: items,
                  pageSize: CompetitionRepository.pageSize,
                  loadPage: (int offset) => ref
                      .read(competitionRepositoryProvider)
                      .fetchCompetitions(offset: offset),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemBuilder:
                      (BuildContext context, CompetitionRow c, int i) =>
                          AppListCard(
                            key: ValueKey<String>(c.id),
                            leadingIcon: Icons.emoji_events,
                            iconColor: context.palette.accent,
                            title: c.name,
                            onTap: () => context.push(
                              Routes.competitionDetail(c.id, c.name),
                            ),
                          ),
                ),
              ),
      ),
    );
  }
}
