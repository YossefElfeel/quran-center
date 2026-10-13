import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/tokens.dart';
import 'app_list_card.dart';

/// هيكل تحميل (skeleton) لشاشات القوائم — بديل أنيق للـ spinner.
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({
    this.itemCount = 7,
    this.shrinkWrap = false,
    super.key,
  });

  final int itemCount;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) => const AppListCard(
          title:
              'عنصر تجريبي للتحميل', // l10n-ignore: skeleton placeholder shape, not shown as text
          subtitle:
              'سطر فرعي قصير للوصف', // l10n-ignore: skeleton placeholder shape, not shown as text
          leadingIcon: Icons.circle,
        ),
      ),
    );
  }
}
