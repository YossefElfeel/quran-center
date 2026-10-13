import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_confirm_sheet.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../user_invite/presentation/screens/invite_user_screen.dart';
import '../../domain/guardian_link_row.dart';
import '../controllers/guardian_links_controller.dart';
import '../widgets/add_guardian_link_sheet.dart';
import '../widgets/edit_guardian_sheet.dart';

/// الأدمن — ربط أولياء الأمور بالأطفال (عشان يدخلوا بوابة المتابعة).
class GuardianLinksScreen extends ConsumerWidget {
  const GuardianLinksScreen({super.key});

  void _add(BuildContext context) {
    showAppModalSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => const AddGuardianLinkSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<GuardianLinkRow>> state = ref.watch(
      guardianLinksControllerProvider,
    );
    return AppScaffold(
      title: l.famGuardianLinksTitle,
      actions: <Widget>[
        IconButton(
          tooltip: l.famNewLink,
          icon: const Icon(Icons.add),
          onPressed: () => _add(context),
        ),
      ],
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.famLinksLoadError,
          onRetry: () => ref.invalidate(guardianLinksControllerProvider),
        ),
        data: (List<GuardianLinkRow> items) => items.isEmpty
            ? EmptyState(
                message: l.famNoLinks,
                icon: Icons.link_off,
                action: AppButton(
                  label: l.famNewLink,
                  onPressed: () => _add(context),
                ),
              )
            : AppRefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(guardianLinksControllerProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) {
                    final GuardianLinkRow r = items[i];
                    return AppListCard(
                      leadingIcon: Icons.link,
                      title: r.guardianName,
                      subtitle:
                          '${r.relationAr}: ${r.childName}\nدخول ${r.hasLogin ? '✓' : '✗'} · أسرة ${r.householdId != null ? '✓' : '✗'} · ${r.subscriptionActive ? 'الاشتراك نشط' : 'اشتراك محتاج تجديد'} · ${r.childrenCount} أطفال',
                      onTap: () => showAppModalSheet<void>(
                        context: context,
                        title: r.guardianName,
                        builder: (BuildContext sheetContext) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            AppButton(
                              label: 'تعديل البيانات / الأسرة',
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                showAppModalSheet<void>(
                                  context: context,
                                  title: 'تعديل ولي الأمر',
                                  builder: (_) => EditGuardianSheet(row: r),
                                );
                              },
                            ),
                            if (!r.hasLogin)
                              AppButton(
                                label: 'إنشاء دعوة دخول',
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => InviteUserScreen(
                                      existingPersonId: r.guardianId,
                                      existingName: r.guardianName,
                                      existingRole: 'parent',
                                    ),
                                  ),
                                ),
                              ),
                            if (r.householdId != null)
                              AppButton(
                                label: 'سجّل دفعة / إدارة الأسرة',
                                onPressed: () => context.push(
                                  '/admin/household/${r.householdId}/members?name=${Uri.encodeComponent(r.householdName ?? 'الأسرة')}',
                                ),
                              ),
                            TextButton(
                              onPressed: () async {
                                if (!await showAppConfirmSheet(
                                  context: sheetContext,
                                  title: 'إلغاء ربط ولي الأمر بالطفل؟',
                                  confirmLabel: 'إلغاء الربط',
                                  message: 'الحساب والأسرة هيفضلوا موجودين',
                                )) {
                                  return;
                                }
                                try {
                                  await ref
                                      .read(supabaseClientProvider)
                                      .from('guardian_link')
                                      .delete()
                                      .eq('guardian_person_id', r.guardianId)
                                      .eq('student_person_id', r.studentId);
                                  ref.invalidate(
                                    guardianLinksControllerProvider,
                                  );
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                } catch (_) {
                                  if (sheetContext.mounted) {
                                    AppSnackbar.error(
                                      sheetContext,
                                      'تعذّر إلغاء الربط',
                                    );
                                  }
                                }
                              },
                              child: const Text('إلغاء ربط الطفل'),
                            ),
                          ],
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
