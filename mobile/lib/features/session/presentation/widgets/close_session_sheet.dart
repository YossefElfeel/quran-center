import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/surah_option.dart';
import '../controllers/surahs_controller.dart';
import '../controllers/today_session_controller.dart';
import 'portion_range_row.dart';

/// شيت قفل الحصة بخطة: تحديد مراجعة الحصة الجاية (اختياري) + قفل الحصة.
class CloseSessionSheet extends ConsumerStatefulWidget {
  const CloseSessionSheet({required this.circleId, super.key});

  final String circleId;

  @override
  ConsumerState<CloseSessionSheet> createState() => _CloseSessionSheetState();
}

class _CloseSessionSheetState extends ConsumerState<CloseSessionSheet> {
  final TextEditingController _revName = TextEditingController();
  final TextEditingController _revAyahStart = TextEditingController();
  final TextEditingController _revAyahEnd = TextEditingController();
  int? _revSurahStart;
  int? _revSurahEnd;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _revName.dispose();
    _revAyahStart.dispose();
    _revAyahEnd.dispose();
    super.dispose();
  }

  Future<void> _close(List<SurahOption> surahs) async {
    final String name = _revName.text.trim();
    final int? as = int.tryParse(_revAyahStart.text.trim());
    final int? ae = int.tryParse(_revAyahEnd.text.trim());
    final bool anyRevision =
        name.isNotEmpty ||
        as != null ||
        ae != null ||
        _revSurahStart != null ||
        _revSurahEnd != null;
    if (anyRevision) {
      final String? err = portionRangeError(
        surahs: surahs,
        name: name,
        surahStart: _revSurahStart,
        ayahStart: as,
        surahEnd: _revSurahEnd,
        ayahEnd: ae,
      );
      if (err != null) {
        setState(() => _error = err);
        return;
      }
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref
          .read(todaySessionControllerProvider(widget.circleId).notifier)
          .closeWithPlan(
            revisionName: anyRevision ? name : null,
            revSurahStart: anyRevision ? _revSurahStart : null,
            revAyahStart: anyRevision ? as : null,
            revSurahEnd: anyRevision ? _revSurahEnd : null,
            revAyahEnd: anyRevision ? ae : null,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مش قادرين نقفل الحصة — جرّب تاني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<SurahOption>> surahsAsync = ref.watch(surahsProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: surahsAsync.when(
        loading: () => const SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (Object e, StackTrace _) =>
            const Text('مش قادرين نحمّل السور', textAlign: TextAlign.center),
        data: (List<SurahOption> list) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'اقفل الحصة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'هيراجعوا إيه الحصة الجاية؟ (اختياري)',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _revName,
                decoration: const InputDecoration(labelText: 'اسم المراجعة'),
              ),
              const SizedBox(height: AppSpacing.sm),
              PortionRangeRow(
                title: 'من',
                surahs: list,
                surah: _revSurahStart,
                onSurah: (int? v) => setState(() => _revSurahStart = v),
                ayahController: _revAyahStart,
              ),
              const SizedBox(height: AppSpacing.sm),
              PortionRangeRow(
                title: 'لـ',
                surahs: list,
                surah: _revSurahEnd,
                onSurah: (int? v) => setState(() => _revSurahEnd = v),
                ayahController: _revAyahEnd,
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: _saving ? 'بنقفل…' : 'اقفل الحصة',
                icon: Icons.check_circle,
                onPressed: _saving ? null : () => _close(list),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
