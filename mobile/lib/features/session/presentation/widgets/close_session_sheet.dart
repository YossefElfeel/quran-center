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
      AppSnackbar.error(context, AppL10n.of(context).sesCloseSessionError);
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
                l.sesCloseSession,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l.sesCloseRevisionPrompt,
                style: TextStyle(color: context.palette.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _revName, label: l.sesRevisionNameLabel),
              const SizedBox(height: AppSpacing.sm),
              PortionRangeRow(
                title: l.sesRangeFrom,
                surahs: list,
                surah: _revSurahStart,
                onSurah: (int? v) => setState(() => _revSurahStart = v),
                ayahController: _revAyahStart,
              ),
              const SizedBox(height: AppSpacing.sm),
              PortionRangeRow(
                title: l.sesRangeTo,
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
                  style: TextStyle(color: context.palette.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: _saving ? l.sesClosing : l.sesCloseSession,
                icon: Icons.check_circle,
                isLoading: _saving,
                onPressed: _saving ? null : () => _close(list),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
