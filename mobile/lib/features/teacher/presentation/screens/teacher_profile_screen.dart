import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/teacher_profile.dart';
import '../controllers/teacher_controllers.dart';

/// محرّر ملف المعلّم — سيرة + مؤهّلات + شهادات (كل سطر بند).
class TeacherProfileScreen extends ConsumerStatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  ConsumerState<TeacherProfileScreen> createState() =>
      _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends ConsumerState<TeacherProfileScreen> {
  final TextEditingController _cv = TextEditingController();
  final TextEditingController _quals = TextEditingController();
  final TextEditingController _certs = TextEditingController();
  bool _prefilled = false;
  bool _saving = false;

  @override
  void dispose() {
    _cv.dispose();
    _quals.dispose();
    _certs.dispose();
    super.dispose();
  }

  List<String> _lines(String s) => s
      .split('\n')
      .map((String l) => l.trim())
      .where((String l) => l.isNotEmpty)
      .toList();

  Future<void> _save() async {
    final AppL10n l = AppL10n.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(myTeacherProfileProvider.notifier)
          .save(
            cv: _cv.text.trim().isEmpty ? null : _cv.text.trim(),
            qualifications: _lines(_quals.text),
            certificates: _lines(_certs.text),
          );
      if (!mounted) return;
      AppSnackbar.success(context, l.tchProfileSaved);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, l.tchProfileSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<TeacherProfile?>>(myTeacherProfileProvider, (
      AsyncValue<TeacherProfile?>? prev,
      AsyncValue<TeacherProfile?> next,
    ) {
      final TeacherProfile? p = next.asData?.value;
      if (p != null && !_prefilled) {
        _cv.text = p.cv ?? '';
        _quals.text = p.qualifications.join('\n');
        _certs.text = p.certificates.join('\n');
        _prefilled = true;
      }
    });
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<TeacherProfile?> state = ref.watch(
      myTeacherProfileProvider,
    );
    return AppScaffold(
      title: l.tchProfileTitle,
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.tchProfileLoadFailed,
          onRetry: () => ref.invalidate(myTeacherProfileProvider),
        ),
        data: (TeacherProfile? _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            AppTextField(controller: _cv, maxLines: 6, label: l.tchCvLabel),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _quals,
              maxLines: 5,
              label: l.tchQualificationsLabel,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _certs,
              maxLines: 5,
              label: l.tchCertificatesLabel,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _saving ? l.tchSaving : l.tchSaveProfile,
              icon: Icons.save,
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
