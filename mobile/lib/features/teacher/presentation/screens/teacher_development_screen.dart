import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/teacher_dev_entry.dart';
import '../controllers/teacher_controllers.dart';

/// شاشة المعلّم: مؤشّر أدائه + تطوّره (يضيف قيود يعتمدها المشرف).
class TeacherDevelopmentScreen extends ConsumerWidget {
  const TeacherDevelopmentScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final AppL10n l = AppL10n.of(context);
    final TextEditingController c = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.tchNewDevEntryTitle),
        content: AppTextField(
          controller: c,
          autofocus: true,
          maxLines: 4,
          label: l.tchDevEntryHint,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.tchSend),
          ),
        ],
      ),
    );
    final String text = c.text;
    c.dispose();
    if (ok == true) {
      await ref.read(myDevelopmentProvider.notifier).add(text);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<TeacherDevEntry>> state = ref.watch(
      myDevelopmentProvider,
    );
    return AppScaffold(
      title: l.navMyProfileDev,
      actions: <Widget>[
        IconButton(
          tooltip: l.tchProfileTitle,
          icon: const Icon(Icons.badge),
          onPressed: () => context.push(Routes.teacherProfile),
        ),
        IconButton(
          tooltip: l.tchNewEntryTooltip,
          icon: const Icon(Icons.add),
          onPressed: () => _add(context, ref),
        ),
      ],
      body: Column(
        children: <Widget>[
          const _PassRateCard(),
          Expanded(
            child: state.when(
              loading: () => const AppListSkeleton(),
              error: (Object e, StackTrace _) => AppErrorView(
                message: l.tchDevLoadFailed,
                onRetry: () => ref.invalidate(myDevelopmentProvider),
              ),
              data: (List<TeacherDevEntry> items) => items.isEmpty
                  ? EmptyState(
                      message: l.tchNoDevEntries,
                      icon: Icons.trending_up,
                    )
                  : AppRefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(myDevelopmentProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        itemCount: items.length,
                        itemBuilder: (BuildContext context, int i) =>
                            _DevTile(entry: items[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassRateCard extends ConsumerWidget {
  const _PassRateCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    final AsyncValue<double> rate = ref.watch(myPassRateProvider);
    return AppListCard(
      margin: const EdgeInsets.all(AppSpacing.md),
      leadingIcon: Icons.insights,
      title: l.tchPassRateTitle,
      trailing: rate.maybeWhen(
        orElse: () => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        data: (double r) => Text(
          l.tchPassRatePercent(arabicNumber((r * 100).round())),
          style: AppTextStyles.titleLg.copyWith(
            fontWeight: FontWeight.bold,
            color: p.primary,
          ),
        ),
      ),
    );
  }
}

class _DevTile extends StatelessWidget {
  const _DevTile({required this.entry});

  final TeacherDevEntry entry;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return AppListCard(
      leadingIcon: entry.isApproved ? Icons.verified : Icons.hourglass_top,
      iconColor: entry.isApproved ? p.success : p.accent,
      title: entry.progress ?? '—',
      subtitle:
          '${arabicNumber(entry.month.month)}/${arabicNumber(entry.month.year)}',
      trailing: AppStatusBadge(
        label: entry.isApproved ? l.tchApproved : l.tchPendingApproval,
        kind: entry.isApproved ? AppStatusKind.success : AppStatusKind.warning,
      ),
    );
  }
}
