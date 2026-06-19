import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_section_header.dart';

/// يفتح bottom sheet موحّد (drag handle + زوايا xl من الثيم) مع تعامل صحيح
/// مع لوحة المفاتيح (viewInsets). يستبدل البويلربليت المكرّر في `*_sheet.dart`.
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    builder: (BuildContext ctx) => AppModalSheet(
      title: title,
      child: Builder(builder: builder),
    ),
  );
}

/// محتوى الـ sheet: عنوان اختياري + جسم قابل للتمرير + هامش لوحة المفاتيح.
class AppModalSheet extends StatelessWidget {
  const AppModalSheet({required this.child, this.title, super.key});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final String? title = this.title;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (title != null)
            AppSectionHeader(
              title: title,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
