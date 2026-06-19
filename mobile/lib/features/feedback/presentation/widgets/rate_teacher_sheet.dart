import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/feedback_repository.dart';

/// شيت تقييم المحفّظ (نجوم + تعليق) — خاص للمدير/المشرف، المعلّم مايشوفوش.
class RateTeacherSheet extends ConsumerStatefulWidget {
  const RateTeacherSheet({required this.studentPersonId, super.key});

  final String studentPersonId;

  @override
  ConsumerState<RateTeacherSheet> createState() => _RateTeacherSheetState();
}

class _RateTeacherSheetState extends ConsumerState<RateTeacherSheet> {
  int _stars = 5;
  final TextEditingController _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final String? err = await ref
        .read(feedbackRepositoryProvider)
        .rateChildTeacher(
          studentPersonId: widget.studentPersonId,
          stars: _stars,
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    final AppL10n l = AppL10n.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(err ?? l.fbkRateThanks)));
    if (err == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l.fbkRateTeacherTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.fbkRatePrivateNote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 1; i <= 5; i++)
                IconButton(
                  icon: Icon(
                    i <= _stars ? Icons.star : Icons.star_border,
                    color: AppColors.accent,
                    size: 36,
                  ),
                  onPressed: () => setState(() => _stars = i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _comment,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l.fbkRateCommentLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? l.fbkSending : l.fbkSubmitRating,
            icon: Icons.send,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
