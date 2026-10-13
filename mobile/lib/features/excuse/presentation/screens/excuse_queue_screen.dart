import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/utils/arabic_date.dart';
import '../../../../shared/theme/app_icons.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_paged_list.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_segmented_control.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/excuse_repository.dart';
import '../../domain/pending_excuse.dart';
import '../controllers/pending_excuses_controller.dart';
import '../excuse_labels.dart';
import '../widgets/excuse_decision_tile.dart';

/// طابور المشرف: أعذار الغياب المستنية موافقة + سجل اللي اتقرّر قبل كده.
class ExcuseQueueScreen extends ConsumerStatefulWidget {
  const ExcuseQueueScreen({super.key});

  @override
  ConsumerState<ExcuseQueueScreen> createState() => _ExcuseQueueScreenState();
}

class _ExcuseQueueScreenState extends ConsumerState<ExcuseQueueScreen> {
  /// false = المعلّقة، true = السابقة.
  bool _history = false;

  void _openDetails(BuildContext context, PendingExcuse excuse) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    showAppModalSheet<void>(
      context: context,
      title: l.excDetailsTitle,
      builder: (BuildContext _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            excuse.studentName,
            style: AppTextStyles.titleLg.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            excuse.circleName,
            style: AppTextStyles.bodyMd.copyWith(color: p.textSecondary),
          ),
          if (excuse.absenceDate != null)
            Text(
              l.fyExcuseAbsenceDay(excuseDateLabel(excuse.absenceDate!)),
              style: AppTextStyles.bodyMd.copyWith(color: p.textSecondary),
            ),
          Text(
            excuseRequestedLine(l, excuse),
            style: AppTextStyles.bodyMd.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppStatusBadge(
            label: excuse.isPending
                ? l.excPending
                : excuse.isApproved
                ? l.excApproved
                : l.excRejected,
            kind: excuse.isPending
                ? AppStatusKind.warning
                : excuse.isApproved
                ? AppStatusKind.success
                : AppStatusKind.error,
            icon: excuse.isPending
                ? Icons.schedule
                : excuse.isApproved
                ? AppIcons.approved
                : AppIcons.rejected,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l.excSubmittedAt(arabicDateTimeLabel(excuse.createdAt)),
            style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
          ),
          if (excuse.decidedAt != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.excDecidedAt(arabicDateTimeLabel(excuse.decidedAt!)),
              style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
            ),
          ],
          const Divider(height: AppSpacing.xl),
          Text(
            l.excReasonLabel,
            style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            excuse.reason?.trim().isNotEmpty == true
                ? excuse.reason!
                : l.excNoReason,
            style: AppTextStyles.bodyLg.copyWith(color: p.textPrimary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return AppScaffold(
      title: l.excQueueTitle,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm + 4,
          ),
          child: AppSegmentedControl<bool>(
            segments: <({bool value, String label})>[
              (value: false, label: l.fyExcusePendingTab),
              (value: true, label: l.fyExcuseHistoryTab),
            ],
            selected: _history,
            onChanged: (bool v) => setState(() => _history = v),
          ),
        ),
      ),
      body: _history ? _buildHistory(context) : _buildPending(context),
    );
  }

  Widget _buildPending(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<PendingExcuse>> state = ref.watch(
      pendingExcusesControllerProvider,
    );
    return state.when(
      loading: () => const AppListSkeleton(),
      error: (Object e, StackTrace _) => AppErrorView(
        message: l.excLoadError,
        onRetry: () => ref.invalidate(pendingExcusesControllerProvider),
      ),
      data: (List<PendingExcuse> items) {
        if (items.isEmpty) {
          return EmptyState(
            message: l.excEmpty,
            icon: Icons.event_available,
            action: TextButton(
              onPressed: () => ref.invalidate(pendingExcusesControllerProvider),
              child: Text(l.commonRefreshData),
            ),
          );
        }
        final PendingExcusesController notifier = ref.read(
          pendingExcusesControllerProvider.notifier,
        );
        return AppRefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(pendingExcusesControllerProvider),
          child: AppPagedList<PendingExcuse>(
            items: items,
            loadPage: (offset) =>
                ref.read(excuseRepositoryProvider).fetchPending(offset: offset),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemBuilder: (BuildContext context, PendingExcuse item, int i) =>
                ExcuseDecisionTile(
                  key: ValueKey<String>(item.id),
                  excuse: item,
                  onApprove: () => notifier.decide(item, approve: true),
                  onReject: () => notifier.decide(item, approve: false),
                  onTap: () => _openDetails(context, item),
                ),
          ),
        );
      },
    );
  }

  Widget _buildHistory(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<PendingExcuse>> state = ref.watch(
      decidedExcusesProvider,
    );
    return state.when(
      loading: () => const AppListSkeleton(),
      error: (Object e, StackTrace _) => AppErrorView(
        message: l.excLoadError,
        onRetry: () => ref.invalidate(decidedExcusesProvider),
      ),
      data: (List<PendingExcuse> items) {
        if (items.isEmpty) {
          return EmptyState(
            message: l.fyExcuseHistoryEmpty,
            icon: Icons.history,
            action: TextButton(
              onPressed: () => ref.invalidate(decidedExcusesProvider),
              child: Text(l.commonRefreshData),
            ),
          );
        }
        return AppRefreshIndicator(
          onRefresh: () async => ref.invalidate(decidedExcusesProvider),
          child: AppPagedList<PendingExcuse>(
            items: items,
            loadPage: (offset) =>
                ref.read(excuseRepositoryProvider).fetchDecided(offset: offset),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemBuilder: (BuildContext context, PendingExcuse item, int i) =>
                ExcuseDecisionTile(
                  key: ValueKey<String>(item.id),
                  excuse: item,
                  // مقرّر بالفعل — التايل بيعرض بادج القرار بدل الأزرار.
                  onApprove: () async {},
                  onReject: () async {},
                  onTap: () => _openDetails(context, item),
                ),
          ),
        );
      },
    );
  }
}
