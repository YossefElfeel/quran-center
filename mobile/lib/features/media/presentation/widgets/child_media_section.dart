import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../shared/theme/tokens.dart';
import '../../data/media_repository.dart';
import '../../domain/image_watermark.dart';
import '../../domain/media_item.dart';
import '../controllers/child_media_controller.dart';

/// قسم وسائط الطفل: معرض (مفلتر بالموافقة عبر RLS) + رفع للأدوار المصرّح لها.
/// الصور بتتعالج على الجهاز (علامة مائية + ضغط) قبل الرفع. رفع الفيديو مؤجّل
/// (ضغط/علامة الفيديو على الجهاز محتاج ffmpeg) — العرض بيفتح الفيديو خارجيًا.
class ChildMediaSection extends ConsumerWidget {
  const ChildMediaSection({required this.studentPersonId, super.key});

  final String studentPersonId;

  static const Set<String> _uploaderRoles = <String>{
    'teacher',
    'admin',
    'super_admin',
  };

  Future<void> _pickAndUpload(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final AppL10n l = AppL10n.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 90,
      );
      if (picked == null) return;
      final Uint8List raw = await picked.readAsBytes();
      final DateTime now = DateTime.now();
      final String stamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      final Uint8List processed = watermarkAndCompressImage(
        bytes: raw,
        watermark: 'Quran Center • $stamp',
      );
      messenger.showSnackBar(SnackBar(content: Text(l.ppMediaUploading)));
      await ref
          .read(mediaRepositoryProvider)
          .uploadMedia(
            studentPersonId: studentPersonId,
            type: 'photo',
            bytes: processed,
            watermarked: true,
          );
      ref.invalidate(childMediaProvider(studentPersonId));
      messenger.showSnackBar(SnackBar(content: Text(l.ppMediaUploaded)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.ppMediaUploadError)));
    }
  }

  void _showSourceSheet(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l.ppMediaFromCamera),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickAndUpload(context, ref, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l.ppMediaFromGallery),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _pickAndUpload(context, ref, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<MediaItem>> state = ref.watch(
      childMediaProvider(studentPersonId),
    );
    final List<String> roles =
        ref.watch(currentRolesProvider).asData?.value ?? const <String>[];
    final bool canUpload = roles.any(_uploaderRoles.contains);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  l.ppMediaSection,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (canUpload)
                  IconButton(
                    tooltip: l.ppMediaAdd,
                    icon: const Icon(Icons.add_a_photo),
                    onPressed: () => _showSourceSheet(context, ref),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            state.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace _) => Text(l.ppMediaLoadError),
              data: (List<MediaItem> items) {
                if (items.isEmpty) {
                  return Text(
                    l.ppMediaEmpty,
                    style: const TextStyle(color: AppColors.textSecondary),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.xs,
                    mainAxisSpacing: AppSpacing.xs,
                  ),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) => _MediaTile(
                    key: ValueKey<String>(items[i].id),
                    item: items[i],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaTile extends ConsumerWidget {
  const _MediaTile({required this.item, super.key});

  final MediaItem item;

  Future<void> _openVideo(WidgetRef ref) async {
    final String url = await ref.read(mediaSignedUrlProvider(item.id).future);
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _openPhoto(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (BuildContext _) =>
          Dialog(child: InteractiveViewer(child: Image.network(url))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.isVideo) {
      return _TileFrame(
        onTap: () => _openVideo(ref),
        child: const ColoredBox(
          color: Colors.black12,
          child: Center(child: Icon(Icons.play_circle_fill, size: 30)),
        ),
      );
    }
    final AsyncValue<String> url = ref.watch(mediaSignedUrlProvider(item.id));
    return _TileFrame(
      onTap: url.asData != null
          ? () => _openPhoto(context, url.asData!.value)
          : null,
      child: url.when(
        skipLoadingOnReload: true,
        loading: () => const ColoredBox(
          color: Colors.black12,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (Object e, StackTrace _) => const _BrokenTile(),
        data: (String u) => RepaintBoundary(
          child: Image.network(
            u,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _BrokenTile(),
          ),
        ),
      ),
    );
  }
}

class _TileFrame extends StatelessWidget {
  const _TileFrame({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadii.sm),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.expand(child: child),
      ),
    ),
  );
}

class _BrokenTile extends StatelessWidget {
  const _BrokenTile();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Colors.black12,
    child: Center(child: Icon(Icons.broken_image, size: 22)),
  );
}
