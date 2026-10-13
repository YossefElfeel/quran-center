import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/arabic_date.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_inline_banner.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_paged_list.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/teacher_repository.dart';
import '../../domain/teacher_dev_entry.dart';
import '../controllers/teacher_controllers.dart';
import '../widgets/add_dev_entry_sheet.dart';

/// شاشة المعلّم: مؤشّر أدائه + تطوّره (يضيف قيود يعتمدها المشرف).
class TeacherDevelopmentScreen extends ConsumerStatefulWidget {
  const TeacherDevelopmentScreen({super.key});

  @override
  ConsumerState<TeacherDevelopmentScreen> createState() =>
      _TeacherDevelopmentScreenState();
}

class _TeacherDevelopmentScreenState
    extends ConsumerState<TeacherDevelopmentScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(myDevelopmentProvider);
    }
  }

  void _addEntry(BuildContext context) {
    showAppModalSheet<void>(
      context: context,
      title: AppL10n.of(context).tchNewDevEntryTitle,
      builder: (BuildContext _) => const AddDevEntrySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => _addEntry(context),
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
                      action: TextButton(
                        onPressed: () => ref.invalidate(myDevelopmentProvider),
                        child: Text(l.commonRefreshData),
                      ),
                    )
                  : AppRefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(myDevelopmentProvider),
                      child: AppPagedList<TeacherDevEntry>(
                        items: items,
                        pageSize: TeacherRepository.developmentPageSize,
                        loadPage: (int offset) => ref
                            .read(teacherRepositoryProvider)
                            .fetchMyDevelopment(offset: offset),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        itemBuilder:
                            (BuildContext context, TeacherDevEntry e, int i) =>
                                _DevTile(entry: e),
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
      subtitle: l.tchViewDetails,
      onTap: () => context.push(Routes.teacherPassRate),
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

class _DevTile extends ConsumerWidget {
  const _DevTile({required this.entry});

  final TeacherDevEntry entry;

  String _monthLabel() =>
      '${arabicNumber(entry.month.month)}/${arabicNumber(entry.month.year)}';

  void _openDetail(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    showAppModalSheet<void>(
      context: context,
      title: l.tchDevDetailTitle,
      builder: (BuildContext context) {
        final AppPalette p = context.palette;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _MetaChip(icon: Icons.event, label: _monthLabel()),
                const SizedBox(width: AppSpacing.sm),
                AppStatusBadge(
                  label: entry.isApproved
                      ? l.tchApproved
                      : l.tchPendingApproval,
                  kind: entry.isApproved
                      ? AppStatusKind.success
                      : AppStatusKind.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.tchDevProgressLabel,
              style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              entry.progress ?? '—',
              style: AppTextStyles.bodyLg.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            AppInlineBanner(
              message: entry.isApproved
                  ? l.tchDevApprovedNote
                  : l.tchDevSubmittedNote,
              kind: entry.isApproved
                  ? AppBannerKind.success
                  : AppBannerKind.info,
            ),
            if (entry.status == 'returned') ...<Widget>[
              Text(l.tchRevisionRequested(entry.returnReason ?? '')),
              AppButton(
                label: l.tchEditAndResubmit,
                onPressed: () => showAppModalSheet<void>(
                  context: context,
                  title: l.tchEditDevTitle,
                  builder: (_) => _ResubmitDev(entry: entry),
                ),
              ),
            ],
            if (entry.approvedAt != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.tchApprovedAt(arabicDateTimeLabel(entry.approvedAt!)),
                style: AppTextStyles.labelSm.copyWith(color: p.textSecondary),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return AppListCard(
      leadingIcon: entry.isApproved ? Icons.verified : Icons.hourglass_top,
      iconColor: entry.isApproved ? p.success : p.accent,
      title: entry.progress ?? '—',
      subtitle: _monthLabel(),
      onTap: () => _openDetail(context, ref),
      trailing: AppStatusBadge(
        label: entry.isApproved ? l.tchApproved : l.tchPendingApproval,
        kind: entry.isApproved ? AppStatusKind.success : AppStatusKind.warning,
      ),
    );
  }
}

/// شريحة معلومة صغيرة (أيقونة + نص) للشهر داخل تفاصيل القيد.
class _ResubmitDev extends ConsumerStatefulWidget {
  const _ResubmitDev({required this.entry});
  final TeacherDevEntry entry;
  @override
  ConsumerState<_ResubmitDev> createState() => _ResubmitDevState();
}

class _ResubmitDevState extends ConsumerState<_ResubmitDev> {
  late final TextEditingController _text = TextEditingController(
    text: widget.entry.progress,
  );
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  bool _busy = false;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(widget.entry.returnReason ?? ''),
          AppTextField(
            controller: _text,
            label: l.tchDevFieldLabel,
            maxLines: 5,
            validator: (String? v) =>
                v == null || v.trim().isEmpty ? l.tchDevEditRequired : null,
          ),
          AppButton(
            label: l.tchResubmit,
            isLoading: _busy,
            onPressed: () async {
              if (_busy || !_form.currentState!.validate()) return;
              setState(() => _busy = true);
              try {
                await ref
                    .read(teacherRepositoryProvider)
                    .resubmitDevelopment(widget.entry.id, _text.text.trim());
                ref.invalidate(myDevelopmentProvider);
                if (context.mounted) {
                  AppSnackbar.success(context, l.commonSentForApproval);
                  Navigator.of(context).pop();
                }
              } catch (_) {
                if (context.mounted) {
                  AppSnackbar.error(context, l.tchResubmitFailed);
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: p.primary.withValues(alpha: AppOpacity.badgeTint),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: p.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTextStyles.labelSm.copyWith(color: p.primary)),
        ],
      ),
    );
  }
}
