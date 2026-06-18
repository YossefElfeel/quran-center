import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../shared/theme/tokens.dart';
import '../../domain/journey_stop.dart';
import '../controllers/child_extras_controller.dart';

/// رحلة الطفل عبر الحلقات + حق المحفّظ (مين حفّظه وأي مدى).
class ChildJourneySection extends ConsumerWidget {
  const ChildJourneySection({required this.studentPersonId, super.key});

  final String studentPersonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppL10n l = AppL10n.of(context);
    final AsyncValue<List<JourneyStop>> state = ref.watch(
      childJourneyProvider(studentPersonId),
    );
    return state.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (List<JourneyStop> stops) {
        if (stops.isEmpty) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l.ppChildJourney,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final JourneyStop s in stops) _StopTile(stop: s),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({required this.stop});

  final JourneyStop stop;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final String range = (stop.fromPoint != null && stop.toPoint != null)
        ? '${stop.fromPoint} ← ${stop.toPoint}'
        : (stop.fromPoint ?? '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            stop.ongoing ? Icons.play_circle : Icons.check_circle,
            size: 18,
            color: stop.ongoing ? AppColors.accent : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l.ppJourneyStopTitle(stop.circleName, stop.teacherName),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (range.isNotEmpty)
                  Text(
                    range,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
