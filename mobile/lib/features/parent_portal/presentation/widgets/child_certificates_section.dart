import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/presentation/domain_labels.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../documents/data/certificate_repository.dart';
import '../../../documents/presentation/controllers/child_certificates_controller.dart';

/// شهادات الطفل المُصدَرة — عرض/طباعة من ولي الأمر.
class ChildCertificatesSection extends ConsumerWidget {
  const ChildCertificatesSection({
    required this.studentPersonId,
    required this.childName,
    super.key,
  });

  final String studentPersonId;
  final String childName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<CertificateRow>> state = ref.watch(
      childCertificatesProvider(studentPersonId),
    );
    return state.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (List<CertificateRow> certs) {
        if (certs.isEmpty) return const SizedBox.shrink();
        return AppCard(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l.ppCertificates,
                  style: AppTextStyles.labelSm.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final CertificateRow c in certs)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.workspace_premium,
                      color: context.palette.accent,
                    ),
                    title: Text(c.kind.label(AppL10n.of(context))),
                    subtitle: Text(_date(c.issuedAt)),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(l.ppView),
                      onPressed: () => context.push(
                        Routes.certificatePreview(
                          childName,
                          c.kind.label(AppL10n.of(context)),
                          _date(c.issuedAt),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _date(DateTime d) =>
      '${arabicNumber(d.day)}/${arabicNumber(d.month)}/${arabicNumber(d.year)}';
}
