import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
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
    final AsyncValue<List<CertificateRow>> state = ref.watch(
      childCertificatesProvider(studentPersonId),
    );
    return state.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (List<CertificateRow> certs) {
        if (certs.isEmpty) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'الشهادات',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final CertificateRow c in certs)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: AppColors.accent,
                    ),
                    title: Text(c.kind.labelAr),
                    subtitle: Text(_date(c.issuedAt)),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('اعرض'),
                      onPressed: () => context.go(
                        Routes.certificatePreview(
                          childName,
                          c.kind.labelAr,
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
