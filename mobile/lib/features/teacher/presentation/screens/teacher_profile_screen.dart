import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../domain/teacher_profile.dart';
import '../controllers/teacher_controllers.dart';

/// محرّر ملف المعلّم — سيرة + مؤهّلات + شهادات (كل سطر بند).
class TeacherProfileScreen extends ConsumerStatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  ConsumerState<TeacherProfileScreen> createState() =>
      _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends ConsumerState<TeacherProfileScreen> {
  final TextEditingController _cv = TextEditingController();
  final TextEditingController _quals = TextEditingController();
  final TextEditingController _certs = TextEditingController();
  bool _prefilled = false;
  bool _saving = false;

  @override
  void dispose() {
    _cv.dispose();
    _quals.dispose();
    _certs.dispose();
    super.dispose();
  }

  List<String> _lines(String s) => s
      .split('\n')
      .map((String l) => l.trim())
      .where((String l) => l.isNotEmpty)
      .toList();

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(myTeacherProfileProvider.notifier)
          .save(
            cv: _cv.text.trim().isEmpty ? null : _cv.text.trim(),
            qualifications: _lines(_quals.text),
            certificates: _lines(_certs.text),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اتسجّل ملفّك')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مش قادرين نحفظ — جرّب تاني')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<TeacherProfile?>>(myTeacherProfileProvider, (
      AsyncValue<TeacherProfile?>? prev,
      AsyncValue<TeacherProfile?> next,
    ) {
      final TeacherProfile? p = next.asData?.value;
      if (p != null && !_prefilled) {
        _cv.text = p.cv ?? '';
        _quals.text = p.qualifications.join('\n');
        _certs.text = p.certificates.join('\n');
        _prefilled = true;
      }
    });
    final AsyncValue<TeacherProfile?> state = ref.watch(
      myTeacherProfileProvider,
    );
    return AppScaffold(
      title: 'ملفّي',
      body: state.when(
        loading: () => const AppLoader(),
        error: (Object e, StackTrace _) => AppErrorView(
          message: 'مش قادرين نحمّل الملف',
          onRetry: () => ref.invalidate(myTeacherProfileProvider),
        ),
        data: (TeacherProfile? _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            TextField(
              controller: _cv,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'السيرة الذاتية',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _quals,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'المؤهّلات (كل سطر مؤهّل)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _certs,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'الشهادات/الإجازات (كل سطر بند)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _saving ? 'بنحفظ…' : 'حفظ الملف',
              icon: Icons.save,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
