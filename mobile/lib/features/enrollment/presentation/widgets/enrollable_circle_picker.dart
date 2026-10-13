import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_modal_sheet.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/enrollable_circle.dart';
import '../controllers/enrollable_circles_controller.dart';

/// يفتح اختيار الحلقة للتسجيل: مجمّعة بالمنهج ← المستوى، والحلقات
/// المكتملة ظاهرة لكن مقفولة ("مكتملة") عشان محدش يسجّل فوق السعة.
Future<EnrollableCircle?> showEnrollableCirclePicker(BuildContext context) =>
    showAppModalSheet<EnrollableCircle>(
      context: context,
      title: 'اختار الحلقة',
      builder: (_) => const EnrollableCirclePicker(),
    );

class EnrollableCirclePicker extends ConsumerStatefulWidget {
  const EnrollableCirclePicker({super.key});

  @override
  ConsumerState<EnrollableCirclePicker> createState() =>
      _EnrollableCirclePickerState();
}

class _EnrollableCirclePickerState
    extends ConsumerState<EnrollableCirclePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<EnrollableCircle>> state = ref.watch(
      enrollableCirclesProvider,
    );
    return state.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace _) => AppErrorView(
        message: 'تعذّر تحميل الحلقات — جرّب تاني',
        onRetry: () => ref.invalidate(enrollableCirclesProvider),
      ),
      data: (List<EnrollableCircle> circles) {
        if (circles.isEmpty) {
          return const EmptyState(
            icon: Icons.groups_outlined,
            message: 'ضيف منهج ومستوى وحلقة من إعدادات المناهج الأول',
          );
        }
        final String q = _query.trim().toLowerCase();
        final Map<String, List<EnrollableCircle>> groups =
            groupEnrollableCircles(
              circles.where(
                (EnrollableCircle c) =>
                    q.isEmpty ||
                    c.name.toLowerCase().contains(q) ||
                    c.groupLabel.toLowerCase().contains(q),
              ),
            );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(
              label: 'بحث',
              prefixIcon: Icons.search,
              onChanged: (String v) => setState(() => _query = v),
            ),
            if (groups.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'مفيش نتائج — جرّب اسم تاني',
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * .5,
              child: ListView(
                children: <Widget>[
                  for (final MapEntry<String, List<EnrollableCircle>> g
                      in groups.entries) ...<Widget>[
                    AppSectionHeader(
                      title: g.key,
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        AppSpacing.md,
                        0,
                        AppSpacing.xs,
                      ),
                    ),
                    for (final EnrollableCircle c in g.value)
                      _CircleOptionTile(key: ValueKey<String>(c.id), circle: c),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CircleOptionTile extends StatelessWidget {
  const _CircleOptionTile({required this.circle, super.key});

  final EnrollableCircle circle;

  @override
  Widget build(BuildContext context) {
    final int? max = circle.maxSize;
    final String capacity = max == null
        ? '${arabicNumber(circle.activeCount)} طالب'
        : '${arabicNumber(circle.activeCount)}/${arabicNumber(max)} طالب';
    final bool full = circle.isFull;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: !full,
      title: Text(circle.name),
      subtitle: Text(capacity),
      trailing: full
          ? const AppStatusBadge(label: 'مكتملة', kind: AppStatusKind.warning)
          : null,
      onTap: full ? null : () => Navigator.of(context).pop(circle),
    );
  }
}
