import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/guardian_link_row.dart';
import '../controllers/guardian_links_controller.dart';
import '../widgets/add_guardian_link_sheet.dart';

/// الأدمن — ربط أولياء الأمور بالأطفال (عشان يدخلوا بوابة المتابعة).
class GuardianLinksScreen extends ConsumerWidget {
  const GuardianLinksScreen({super.key});

  void _add(BuildContext context) {
    showModalBottomSheet<void>(
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
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.famLinksLoadError,
          onRetry: () => ref.invalidate(guardianLinksControllerProvider),
        ),
        data: (List<GuardianLinkRow> items) => items.isEmpty
            ? EmptyState(message: l.famNoLinks, icon: Icons.link_off)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) {
                  final GuardianLinkRow r = items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.md,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.link, color: AppColors.primary),
                      title: Text(r.guardianName),
                      subtitle: Text(
                        l.famLinkRelationSubtitle(r.relationAr, r.childName),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
