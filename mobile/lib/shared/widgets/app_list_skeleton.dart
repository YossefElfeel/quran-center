import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/tokens.dart';
import 'app_list_card.dart';

/// هيكل تحميل (skeleton) لشاشات القوائم — بديل أنيق للـ spinner.
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({this.itemCount = 7, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) => const AppListCard(
          title: 'عنصر تجريبي للتحميل',
          subtitle: 'سطر فرعي قصير للوصف',
          leadingIcon: Icons.circle,
        ),
      ),
    );
  }
}
