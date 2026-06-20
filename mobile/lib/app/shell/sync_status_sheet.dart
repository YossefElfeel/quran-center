import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../core/db/local_db.dart';
import '../../core/sync/outbox_op.dart';
import '../../core/sync/outbox_store.dart';
import '../../core/sync/sync_status_provider.dart';
import '../../core/utils/arabic_numerals.dart';
import '../../features/session/data/session_sync.dart';
import '../../shared/theme/app_text_styles.dart';
import '../../shared/theme/tokens.dart';

/// شيت "حالة المزامنة": يعرض العمليات المعلّقة والفاشلة (dead-letter) مع إعادة
/// المحاولة/التجاهل — عشان المستخدم يعرف إن في تسميع/حضور ما اتزامنش بدل ما
/// يضيع بصمت.
class SyncStatusSheet extends ConsumerStatefulWidget {
  const SyncStatusSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => const SyncStatusSheet(),
    );
  }

  @override
  ConsumerState<SyncStatusSheet> createState() => _SyncStatusSheetState();
}

class _SyncStatusSheetState extends ConsumerState<SyncStatusSheet> {
  late Future<List<DeadLetterEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DeadLetterEntry>> _load() =>
      ref.read(localDbProvider).deadLetters();

  void _reload() => setState(() => _future = _load());

  Future<void> _retry(String id) async {
    await ref.read(localDbProvider).requeue(id);
    await ref.read(outboxSyncProvider.notifier).flush();
    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppL10n.of(context).syncRetried)));
  }

  Future<void> _retryAll(List<DeadLetterEntry> items) async {
    final LocalDb db = ref.read(localDbProvider);
    for (final DeadLetterEntry e in items) {
      await db.requeue(e.id);
    }
    await ref.read(outboxSyncProvider.notifier).flush();
    _reload();
  }

  Future<void> _discard(String id) async {
    await ref.read(localDbProvider).discard(id);
    _reload();
  }

  String _opLabel(AppL10n l, OutboxOpType type) => switch (type) {
    OutboxOpType.tasmeeRecord => l.syncOpTasmee,
    OutboxOpType.attendanceMark => l.syncOpAttendance,
  };

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    final SyncStatus? status = ref.watch(syncStatusProvider).asData?.value;
    // أعِد تحميل القائمة لما عدد الفاشلة يتغيّر (مثلًا اتزامنت في الخلفية).
    ref.listen<AsyncValue<SyncStatus>>(syncStatusProvider, (
      AsyncValue<SyncStatus>? prev,
      AsyncValue<SyncStatus> next,
    ) {
      if (prev?.asData?.value.dead != next.asData?.value.dead) _reload();
    });

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
            l.syncStatusTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (status != null && status.hasPending) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.syncPending(arabicNumber(status.pending)),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<List<DeadLetterEntry>>(
            future: _future,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<DeadLetterEntry>> snap,
                ) {
                  final List<DeadLetterEntry> items =
                      snap.data ?? const <DeadLetterEntry>[];
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: Text(
                        l.syncNoFailures,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd,
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton.icon(
                          onPressed: () => _retryAll(items),
                          icon: const Icon(Icons.refresh),
                          label: Text(l.syncRetryAll),
                        ),
                      ),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int i) {
                            final DeadLetterEntry e = items[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.error_outline),
                              title: Text(_opLabel(l, e.type)),
                              subtitle: e.lastError == null
                                  ? null
                                  : Text(
                                      e.lastError!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    tooltip: l.syncRetry,
                                    icon: const Icon(Icons.refresh),
                                    onPressed: () => _retry(e.id),
                                  ),
                                  IconButton(
                                    tooltip: l.syncDismiss,
                                    icon: const Icon(Icons.close),
                                    onPressed: () => _discard(e.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
          ),
        ],
      ),
    );
  }
}
