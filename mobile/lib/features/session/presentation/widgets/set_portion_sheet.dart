import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/surah_option.dart';
import '../controllers/surahs_controller.dart';
import '../controllers/today_session_controller.dart';

/// شيت تحديد مقطع الحفظ الحالي للحلقة (اسم + نطاق سور/آيات).
class SetPortionSheet extends ConsumerStatefulWidget {
  const SetPortionSheet({required this.circleId, super.key});

  final String circleId;

  @override
  ConsumerState<SetPortionSheet> createState() => _SetPortionSheetState();
}

class _SetPortionSheetState extends ConsumerState<SetPortionSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _ayahStart = TextEditingController();
  final TextEditingController _ayahEnd = TextEditingController();
  int? _surahStart;
  int? _surahEnd;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _ayahStart.dispose();
    _ayahEnd.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    final int? ss = _surahStart;
    final int? se = _surahEnd;
    final int? as = int.tryParse(_ayahStart.text.trim());
    final int? ae = int.tryParse(_ayahEnd.text.trim());
    if (name.isEmpty ||
        ss == null ||
        se == null ||
        as == null ||
        ae == null ||
        as <= 0 ||
        ae <= 0) {
      setState(() => _error = 'املا كل الخانات صح');
      return;
    }
    if (se < ss || (se == ss && ae < as)) {
      setState(() => _error = 'نهاية المقطع لازم تكون بعد بدايتها');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref
          .read(todaySessionControllerProvider(widget.circleId).notifier)
          .setPortion(
            name: name,
            surahStart: ss,
            ayahStart: as,
            surahEnd: se,
            ayahEnd: ae,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مش قادرين نحفظ المقطع — جرّب تاني')),
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
                'مقطع الحفظ الحالي',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'اسم المقطع (مثلاً: أول البقرة)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _RangeRow(
                title: 'من',
                surahs: list,
                surah: _surahStart,
                onSurah: (int? v) => setState(() => _surahStart = v),
                ayahController: _ayahStart,
              ),
              const SizedBox(height: AppSpacing.sm),
              _RangeRow(
                title: 'لـ',
                surahs: list,
                surah: _surahEnd,
                onSurah: (int? v) => setState(() => _surahEnd = v),
                ayahController: _ayahEnd,
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
                label: _saving ? 'بنحفظ…' : 'حفظ',
                icon: Icons.check,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({
    required this.title,
    required this.surahs,
    required this.surah,
    required this.onSurah,
    required this.ayahController,
  });

  final String title;
  final List<SurahOption> surahs;
  final int? surah;
  final ValueChanged<int?> onSurah;
  final TextEditingController ayahController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 28,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: DropdownButton<int>(
            isExpanded: true,
            value: surah,
            hint: const Text('السورة'),
            items: surahs
                .map(
                  (SurahOption s) => DropdownMenuItem<int>(
                    value: s.number,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: onSurah,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: TextField(
            controller: ayahController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'الآية'),
          ),
        ),
      ],
    );
  }
}
