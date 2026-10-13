import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_async_form_sheet.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_list_card.dart';
import '../../../../shared/widgets/app_list_skeleton.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_refresh_indicator.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/dispose_with.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/course.dart';
import '../controllers/courses_controller.dart';

/// مكتبة الكورسات المجانية — يفتح الفيديو، والأدمن يضيف.
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final AppL10n l = AppL10n.of(context);
    try {
      final Uri? uri = Uri.tryParse(url);
      final bool ok =
          uri != null &&
          uri.hasScheme &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        AppSnackbar.error(context, l.videoOpenError);
      }
    } catch (_) {
      if (context.mounted) AppSnackbar.error(context, l.videoOpenError);
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final AppL10n l = AppL10n.of(context);
    final TextEditingController title = TextEditingController();
    final TextEditingController url = TextEditingController();
    final TextEditingController desc = TextEditingController();
    await showAppModalSheet<void>(
      context: context,
      title: l.courseNew,
      builder: (BuildContext context) => DisposeWith(
        notifiers: <ChangeNotifier>[title, url, desc],
        child: AppAsyncFormSheet(
          submitLabel: l.add,
          successMessage: 'الكورس اتضاف',
          onSubmit: () => ref
              .read(coursesProvider.notifier)
              .add(
                title: title.text.trim(),
                videoUrl: url.text.trim(),
                description: desc.text.trim(),
              ),
          fields: <Widget>[
            AppTextField(
              controller: title,
              label: l.courseTitleLabel,
              validator: (v) =>
                  (v?.trim().length ?? 0) < 2 ? 'اكتب عنوان الكورس' : null,
            ),
            AppTextField(
              controller: url,
              label: l.courseUrlLabel,
              keyboardType: TextInputType.url,
              validator: (v) {
                final uri = Uri.tryParse(v?.trim() ?? '');
                return uri == null ||
                        !['http', 'https'].contains(uri.scheme) ||
                        uri.host.isEmpty
                    ? 'اكتب رابط HTTP أو HTTPS صحيحًا'
                    : null;
              },
            ),
            AppTextField(
              controller: desc,
              label: l.courseDescLabel,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<Course>> state = ref.watch(coursesProvider);
    final List<String> roles =
        ref.watch(currentRolesProvider).asData?.value ?? const <String>[];
    final bool isAdmin =
        roles.contains('admin') || roles.contains('super_admin');
    return AppScaffold(
      title: l.navCourses,
      actions: <Widget>[
        if (isAdmin)
          IconButton(
            tooltip: l.courseNew,
            icon: const Icon(Icons.add),
            onPressed: () => _add(context, ref),
          ),
      ],
      body: state.when(
        loading: () => const AppListSkeleton(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: l.coursesLoadError,
          onRetry: () => ref.invalidate(coursesProvider),
        ),
        data: (List<Course> items) => items.isEmpty
            ? EmptyState(
                message: l.noCourses,
                icon: Icons.ondemand_video,
                action: TextButton(
                  onPressed: () {
                    if (isAdmin) {
                      _add(context, ref);
                    } else {
                      ref.invalidate(coursesProvider);
                    }
                  },
                  child: Text(isAdmin ? l.courseNew : 'تحديث'),
                ),
              )
            : AppRefreshIndicator(
                onRefresh: () async => ref.invalidate(coursesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int i) => AppListCard(
                    leadingIcon: Icons.play_circle_fill,
                    title: items[i].title,
                    subtitle: items[i].description,
                    onTap: () => _open(context, items[i].videoUrl),
                  ),
                ),
              ),
      ),
    );
  }
}
