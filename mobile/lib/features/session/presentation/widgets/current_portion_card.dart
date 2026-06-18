import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/portion.dart';

/// كارت المقطع الحالي للحلقة — يعرض المقطع أو زرّ تحديده.
class CurrentPortionCard extends StatelessWidget {
  const CurrentPortionCard({
    required this.portion,
    required this.onSetPortion,
    super.key,
  });

  final Portion? portion;
  final VoidCallback onSetPortion;

  @override
  Widget build(BuildContext context) {
    final Portion? p = portion;
    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: p == null ? _Empty(onSetPortion: onSetPortion) : _Current(p),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onSetPortion});

  final VoidCallback onSetPortion;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Column(
      children: <Widget>[
        Text(
          l.sesNoPortionYet,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: l.sesSetPortion,
          icon: Icons.menu_book,
          onPressed: onSetPortion,
        ),
      ],
    );
  }
}

class _Current extends StatelessWidget {
  const _Current(this.portion);

  final Portion portion;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Row(
      children: <Widget>[
        const Icon(Icons.menu_book, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l.sesCurrentPortion,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                portion.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
