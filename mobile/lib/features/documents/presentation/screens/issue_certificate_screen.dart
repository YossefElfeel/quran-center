import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/certificate_repository.dart';
import '../../domain/certificate_kind.dart';
import '../../domain/eligible_student.dart';
import '../controllers/issue_certificate_controller.dart';

/// المشرف/الأدمن: إصدار شهادة لطالب مؤهّل (الأهلية متفروضة سيرفر-سايد).
class IssueCertificateScreen extends ConsumerWidget {
  const IssueCertificateScreen({super.key});

  static const List<CertificateKind> _kinds = <CertificateKind>[
    CertificateKind.juzAmma,
    CertificateKind.half,
    CertificateKind.full,
  ];

  Future<void> _issue(
    BuildContext context,
    WidgetRef ref,
    EligibleStudent s,
  ) async {
    final AppL10n l = AppL10n.of(context);
    final CertificateKind? kind = await showDialog<CertificateKind>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(l.docCertificateForTitle(s.name)),
        children: <Widget>[
          for (final CertificateKind k in _kinds)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(k),
              child: Text(k.labelAr),
            ),
        ],
      ),
    );
    if (kind == null) return;
    try {
      await ref
          .read(certificateRepositoryProvider)
          .issueCertificate(studentPersonId: s.id, kind: kind);
      ref.invalidate(eligibleStudentsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.docIssuedSnack(kind.labelAr, s.name))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.docIssueError)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<EligibleStudent>> state = ref.watch(
      eligibleStudentsProvider,
    );
    return AppScaffold(
      title: l.docIssueCertificatesTitle,
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.docEligibleLoadError,
          onRetry: () => ref.invalidate(eligibleStudentsProvider),
        ),
        data: (List<EligibleStudent> items) => items.isEmpty
            ? EmptyState(
                message: l.docNoEligibleStudents,
                icon: Icons.workspace_premium_outlined,
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int i) => Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs,
                    horizontal: AppSpacing.md,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: AppColors.accent,
                    ),
                    title: Text(items[i].name),
                    trailing: FilledButton(
                      onPressed: () => _issue(context, ref, items[i]),
                      child: Text(l.docIssue),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
