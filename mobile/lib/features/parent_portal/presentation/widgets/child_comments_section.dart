import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/arabic_numerals.dart';
import '../../../../shared/theme/tokens.dart';
import '../../domain/parent_comment.dart';
import '../controllers/child_comments_controller.dart';

/// قسم تعليقات ولي الأمر على الكارت: كتابة تعليق + عرض السابق.
class ChildCommentsSection extends ConsumerWidget {
  const ChildCommentsSection({required this.studentPersonId, super.key});

  final String studentPersonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ParentComment>> state = ref.watch(
      childCommentsControllerProvider(studentPersonId),
    );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'تعليقاتك للمعلّم',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            _CommentComposer(studentPersonId: studentPersonId),
            const SizedBox(height: AppSpacing.sm),
            state.when(
              loading: () => const LinearProgressIndicator(),
              error: (Object e, StackTrace _) =>
                  const Text('مش قادرين نحمّل التعليقات'),
              data: (List<ParentComment> items) => items.isEmpty
                  ? const Text(
                      'لسه مفيش تعليقات',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  : Column(
                      children: <Widget>[
                        for (final ParentComment c in items)
                          _CommentTile(key: ValueKey<String>(c.id), comment: c),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentComposer extends ConsumerStatefulWidget {
  const _CommentComposer({required this.studentPersonId});

  final String studentPersonId;

  @override
  ConsumerState<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends ConsumerState<_CommentComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(
            childCommentsControllerProvider(widget.studentPersonId).notifier,
          )
          .add(text);
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مش قادرين نضيف التعليق — جرّب تاني')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'اكتب تعليق للمعلّم…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filled(
          onPressed: _sending ? null : _send,
          icon: const Icon(Icons.send),
          tooltip: 'إرسال',
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, super.key});

  final ParentComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.person,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                comment.authorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                _shortDate(comment.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(comment.body),
          const Divider(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// تاريخ مختصر بأرقام عربية (يوم/شهر/سنة) من غير حاجة لتهيئة locale.
String _shortDate(DateTime d) {
  final DateTime l = d.toLocal();
  return '${arabicNumber(l.day)}/${arabicNumber(l.month)}/${arabicNumber(l.year)}';
}
