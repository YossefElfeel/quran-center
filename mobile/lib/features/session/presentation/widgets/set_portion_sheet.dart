import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/surah_option.dart';
import '../controllers/surahs_controller.dart';
import '../controllers/today_session_controller.dart';
import 'portion_range_row.dart';
import 'surah_load_error.dart';

/// شيت تحديد مقطع الحفظ — أول مقطع (setPortion) أو مقطع الانتقال (advance).
class SetPortionSheet extends ConsumerStatefulWidget {
  const SetPortionSheet({
    required this.circleId,
    this.advanceMode = false,
    super.key,
  });

  final String circleId;
  final bool advanceMode;

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

  Future<void> _save(List<SurahOption> surahs) async {
    final String name = _name.text.trim();
    final int? as = int.tryParse(_ayahStart.text.trim());
    final int? ae = int.tryParse(_ayahEnd.text.trim());
    final String? err = portionRangeError(
      surahs: surahs,
      name: name,
      surahStart: _surahStart,
      ayahStart: as,
      surahEnd: _surahEnd,
      ayahEnd: ae,
    );
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final TodaySessionController notifier = ref.read(
        todaySessionControllerProvider(widget.circleId).notifier,
      );
      if (widget.advanceMode) {
        await notifier.advance(
          name: name,
          surahStart: _surahStart!,
          ayahStart: as!,
          surahEnd: _surahEnd!,
          ayahEnd: ae!,
        );
      } else {
        await notifier.setPortion(
          name: name,
          surahStart: _surahStart!,
          ayahStart: as!,
          surahEnd: _surahEnd!,
          ayahEnd: ae!,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, AppL10n.of(context).sesPortionSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
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
        error: (Object e, StackTrace _) => const SurahLoadError(),
        data: (List<SurahOption> list) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                widget.advanceMode
                    ? l.sesNewAdvancePortion
                    : l.sesCurrentPortion,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _name, label: l.sesPortionNameLabel),
              const SizedBox(height: AppSpacing.md),
              PortionRangeRow(
                title: l.sesRangeFrom,
                surahs: list,
                surah: _surahStart,
                onSurah: (int? v) => setState(() => _surahStart = v),
                ayahController: _ayahStart,
              ),
              const SizedBox(height: AppSpacing.sm),
              PortionRangeRow(
                title: l.sesRangeTo,
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
                  style: TextStyle(color: context.palette.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: _saving ? l.sesPortionSaving : l.sesPortionSave,
                icon: Icons.check,
                isLoading: _saving,
                onPressed: _saving ? null : () => _save(list),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
