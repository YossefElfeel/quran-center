import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
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
    if (err == null) {
      AppSnackbar.success(context, l.fbkRateThanks);
      Navigator.of(context).pop();
    } else {
      AppSnackbar.error(context, err);
    }
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
            style: TextStyle(
              fontSize: 12,
              color: context.palette.textSecondary,
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
                    color: context.palette.accent,
                    size: 36,
                  ),
                  onPressed: () => setState(() => _stars = i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _comment,
            minLines: 2,
            maxLines: 4,
            label: l.fbkRateCommentLabel,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _saving ? l.fbkSending : l.fbkSubmitRating,
            icon: Icons.send,
            isLoading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
