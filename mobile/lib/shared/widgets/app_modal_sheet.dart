import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_section_header.dart';

/// يفتح bottom sheet موحّد (drag handle + زوايا xl من الثيم) مع تعامل صحيح
/// مع لوحة المفاتيح (viewInsets). يستبدل البويلربليت المكرّر في `*_sheet.dart`.
///
/// بيتفتح على الـ root navigator عشان يغطّي شريط التنقّل السفلي بتاع القشرة
/// (StatefulShellRoute) بدل ما يتحط تحته. الـ sheets بتقفل نفسها بالـ context
/// بتاع الـ builder، فمفيش اعتماد على الـ navigator المتداخل.
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isScrollControlled = true,
  bool scrollable = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: isScrollControlled,
    builder: (BuildContext ctx) => AppModalSheet(
      title: title,
      scrollable: scrollable,
      child: Builder(builder: builder),
    ),
  );
}

/// محتوى الـ sheet: عنوان اختياري + جسم قابل للتمرير + هامش لوحة المفاتيح.
class AppModalSheet extends StatelessWidget {
  const AppModalSheet({
    required this.child,
    this.title,
    this.scrollable = true,
    super.key,
  });

  final Widget child;
  final String? title;
  final bool scrollable;

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
            child: scrollable
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: child,
                  )
                : Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: child,
                  ),
          ),
        ],
      ),
    );
  }
}
