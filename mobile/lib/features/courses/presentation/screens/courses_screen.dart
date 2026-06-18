import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/course.dart';
import '../controllers/courses_controller.dart';

/// مكتبة الكورسات المجانية — يفتح الفيديو، والأدمن يضيف.
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final Uri uri = Uri.tryParse(url) ?? Uri();
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('مش قادرين نفتح الفيديو')));
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final TextEditingController title = TextEditingController();
    final TextEditingController url = TextEditingController();
    final TextEditingController desc = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('كورس جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'العنوان'),
            ),
            TextField(
              controller: url,
              decoration: const InputDecoration(labelText: 'رابط الفيديو'),
            ),
            TextField(
              controller: desc,
              decoration: const InputDecoration(labelText: 'وصف (اختياري)'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    final String t = title.text;
    final String u = url.text;
    final String d = desc.text;
    title.dispose();
    url.dispose();
    desc.dispose();
    if (ok == true) {
      await ref
          .read(coursesProvider.notifier)
          .add(title: t, videoUrl: u, description: d);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Course>> state = ref.watch(coursesProvider);
    final List<String> roles =
        ref.watch(currentRolesProvider).asData?.value ?? const <String>[];
    final bool isAdmin =
        roles.contains('admin') || roles.contains('super_admin');
    return AppScaffold(
      title: 'الكورسات',
      actions: <Widget>[
        if (isAdmin)
          IconButton(
            tooltip: 'كورس جديد',
            icon: const Icon(Icons.add),
            onPressed: () => _add(context, ref),
          ),
      ],
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الكورسات',
          onRetry: () => ref.invalidate(coursesProvider),
        ),
        data: (List<Course> items) => items.isEmpty
            ? const EmptyState(
                message: 'لسه مفيش كورسات',
                icon: Icons.ondemand_video,
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
                      Icons.play_circle_fill,
                      color: AppColors.primary,
                      size: 36,
                    ),
                    title: Text(items[i].title),
                    subtitle: items[i].description != null
                        ? Text(items[i].description!)
                        : null,
                    onTap: () => _open(context, items[i].videoUrl),
                  ),
                ),
              ),
      ),
    );
  }
}
