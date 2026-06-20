import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_inline_banner.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/teacher_document.dart';
import '../../domain/teacher_profile.dart';
import '../controllers/teacher_controllers.dart';
import '../controllers/teacher_docs_controller.dart';

/// ملف المعلّم المخصّص — نبذة عنه + مؤهّلاته + رفع سيرته الذاتية وشهاداته.
class TeacherProfileScreen extends ConsumerStatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  ConsumerState<TeacherProfileScreen> createState() =>
      _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends ConsumerState<TeacherProfileScreen> {
  final TextEditingController _about = TextEditingController();
  final TextEditingController _quals = TextEditingController();
  List<String> _existingCerts = const <String>[];
  bool _prefilled = false;
  bool _saving = false;

  @override
  void dispose() {
    _about.dispose();
    _quals.dispose();
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
            cv: _about.text.trim().isEmpty ? null : _about.text.trim(),
            qualifications: _lines(_quals.text),
            // الشهادات بقت مستندات مرفوعة — بنحافظ على القديمة النصّية لو موجودة.
            certificates: _existingCerts,
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

  String _mimeFor(String ext) => switch (ext.toLowerCase()) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    _ => 'application/octet-stream',
  };

  Future<void> _pickAndUpload(String kind) async {
    final AppL10n l = AppL10n.of(context);
    final FilePickerResult? res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final PlatformFile? f = res?.files.isNotEmpty ?? false
        ? res!.files.first
        : null;
    if (f == null || f.bytes == null) return;
    final String ext = (f.extension ?? 'pdf').toLowerCase();
    try {
      await ref
          .read(myTeacherDocumentsProvider.notifier)
          .upload(
            kind: kind,
            title: f.name,
            bytes: f.bytes!,
            ext: ext,
            mime: _mimeFor(ext),
          );
      if (mounted) AppSnackbar.success(context, l.tchDocUploaded);
    } catch (_) {
      if (mounted) AppSnackbar.error(context, l.tchDocUploadFailed);
    }
  }

  Future<void> _view(TeacherDocument doc) async {
    final AppL10n l = AppL10n.of(context);
    try {
      final String url = await ref.read(
        teacherDocSignedUrlProvider(doc.storagePath).future,
      );
      final Uri? uri = Uri.tryParse(url);
      final bool ok =
          uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) AppSnackbar.error(context, l.tchCantOpenDoc);
    } catch (_) {
      if (mounted) AppSnackbar.error(context, l.tchCantOpenDoc);
    }
  }

  Future<void> _delete(TeacherDocument doc) async {
    final AppL10n l = AppL10n.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.tchDeleteDocConfirm),
        content: Text(doc.title),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(myTeacherDocumentsProvider.notifier).remove(doc);
      if (mounted) AppSnackbar.success(context, l.tchDocDeleted);
    } catch (_) {
      if (mounted) AppSnackbar.error(context, l.tchDocUploadFailed);
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
        _about.text = p.cv ?? '';
        _quals.text = p.qualifications.join('\n');
        _existingCerts = p.certificates;
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
            AppInlineBanner(
              message: l.tchProfileIntro,
              kind: AppBannerKind.info,
            ),
            const SizedBox(height: AppSpacing.md),
            AppSectionHeader(title: l.tchAboutMeLabel),
            AppTextField(
              controller: _about,
              maxLines: 5,
              label: l.tchAboutMeHint,
            ),
            const SizedBox(height: AppSpacing.md),
            AppSectionHeader(title: l.tchQualificationsLabel),
            AppTextField(
              controller: _quals,
              maxLines: 4,
              label: l.tchQualsHint,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: _saving ? l.tchSaving : l.tchSaveProfile,
              icon: Icons.save,
              isLoading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _DocumentsSection(),
          ],
        ),
      ),
    );
  }
}

/// قسم المستندات (السيرة + الشهادات) — يقرا myTeacherDocuments.
class _DocumentsSection extends ConsumerWidget {
  const _DocumentsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final _TeacherProfileScreenState parent = context
        .findAncestorStateOfType<_TeacherProfileScreenState>()!;
    final AsyncValue<List<TeacherDocument>> docs = ref.watch(
      myTeacherDocumentsProvider,
    );
    return docs.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace _) => AppErrorView(
        message: l.tchDocsLoadFailed,
        onRetry: () => ref.invalidate(myTeacherDocumentsProvider),
      ),
      data: (List<TeacherDocument> items) {
        final TeacherDocument? cv = items
            .where((TeacherDocument d) => d.isCv)
            .firstOrNull;
        final List<TeacherDocument> certs = items
            .where((TeacherDocument d) => !d.isCv)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppSectionHeader(title: l.tchCvSection),
            if (cv == null)
              _UploadButton(
                label: l.tchUploadCv,
                onTap: () => parent._pickAndUpload('cv'),
              )
            else
              _DocCard(
                doc: cv,
                onView: () => parent._view(cv),
                onReplace: () => parent._pickAndUpload('cv'),
                onDelete: () => parent._delete(cv),
              ),
            const SizedBox(height: AppSpacing.lg),
            AppSectionHeader(title: l.tchCertsSection),
            if (certs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  l.tchNoCerts,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              )
            else
              for (final TeacherDocument d in certs)
                _DocCard(
                  doc: d,
                  onView: () => parent._view(d),
                  onDelete: () => parent._delete(d),
                ),
            const SizedBox(height: AppSpacing.sm),
            _UploadButton(
              label: l.tchAddCertificate,
              icon: Icons.add,
              onTap: () => parent._pickAndUpload('certificate'),
            ),
          ],
        );
      },
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({
    required this.label,
    required this.onTap,
    this.icon = Icons.upload_file,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: AppButton(
        label: label,
        icon: icon,
        variant: AppButtonVariant.tonal,
        onPressed: onTap,
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.doc,
    required this.onView,
    required this.onDelete,
    this.onReplace,
  });

  final TeacherDocument doc;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: AppCard(
        onTap: onView,
        child: Row(
          children: <Widget>[
            Icon(
              doc.isPdf ? Icons.picture_as_pdf : Icons.image,
              color: doc.isPdf ? p.error : p.primary,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                doc.title,
                style: AppTextStyles.bodyLg.copyWith(color: p.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onReplace != null)
              IconButton(
                tooltip: l.tchReplace,
                icon: Icon(Icons.sync, color: p.textSecondary),
                onPressed: onReplace,
              ),
            IconButton(
              tooltip: l.delete,
              icon: Icon(Icons.delete_outline, color: p.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
