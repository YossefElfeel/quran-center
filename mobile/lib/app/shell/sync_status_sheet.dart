import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import '../../core/db/local_db.dart';
import '../../core/sync/outbox_op.dart';
import '../../core/sync/outbox_store.dart';
import '../../core/sync/sync_status_provider.dart';
import '../../core/utils/arabic_numerals.dart';
import '../../features/session/data/session_sync.dart';
import '../../features/session/domain/session_write_block.dart';
import '../../features/session/presentation/session_write_block_label.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_confirm_sheet.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_modal_sheet.dart';
import '../../shared/widgets/app_snackbar.dart';

typedef QueueDetails = (List<OutboxOp>, List<DeadLetterEntry>);

class SyncStatusSheet extends ConsumerStatefulWidget {
  const SyncStatusSheet({super.key});
  static Future<void> show(BuildContext context) => showAppModalSheet<void>(
    context: context,
    title: AppL10n.of(context).syncStatusTitle,
    scrollable: false,
    builder: (_) => const SyncStatusSheet(),
  );
  @override
  ConsumerState<SyncStatusSheet> createState() => _SyncStatusSheetState();
}

class _SyncStatusSheetState extends ConsumerState<SyncStatusSheet> {
  late Future<QueueDetails> _future;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<QueueDetails> _load() async {
    final db = ref.read(localDbProvider);
    return (await db.pending(limit: 1000), await db.deadLetters(limit: 1000));
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _future = _load();
      });
    }
  }

  Future<void> _perform(
    Future<bool> Function() action, {
    String? success,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final done = await action();
      if (mounted && done) {
        _reload();
        if (success != null) AppSnackbar.success(context, success);
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, AppL10n.of(context).syncQueueUpdateError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String label(AppL10n l, OutboxOpType type) => switch (type) {
    OutboxOpType.sessionOpen => l.syncOpSessionOpen,
    OutboxOpType.sessionClose => l.syncOpSessionClose,
    OutboxOpType.tasmeeRecord => l.syncOpTasmee,
    OutboxOpType.attendanceMark => l.syncOpAttendanceMark,
  };
  String reason(AppL10n l, String? error) {
    if (error == null) return l.syncReasonServerRejected;
    if (error.contains('dependent')) {
      return l.syncReasonDependent;
    }
    if (error.contains('freeze')) return l.sesWritesFrozen;
    if (error.contains('maintenance')) return l.sesWritesMaintenance;
    if (error.contains('42501') || error.contains('permission')) {
      return l.syncReasonPermission;
    }
    return l.syncReasonGeneric;
  }

  Future<bool> _flush() async {
    await ref.read(outboxSyncProvider.notifier).flush();
    final db = ref.read(localDbProvider);
    final pending = await db.pendingCount(), dead = await db.deadLetterCount();
    final SessionWriteBlock? blocked = ref.read(
      sessionWritesBlockStateProvider,
    );
    if (mounted) {
      final l = AppL10n.of(context);
      AppSnackbar.info(
        context,
        blocked != null && pending > 0
            ? blocked.label(l)
            : dead > 0
            ? l.syncFlushNeedsReview
            : pending > 0
            ? l.syncFlushStillPending
            : l.syncFlushAllSynced,
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    ref.listen<AsyncValue<SyncStatus>>(syncStatusProvider, (previous, next) {
      if (previous?.value != next.value) _reload();
    });
    final SessionWriteBlock? blocked = ref.watch(
      sessionWritesBlockStateProvider,
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (blocked != null) ...<Widget>[
            AppCard(
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.pause_circle_outline,
                    color: context.palette.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${blocked.label(l)}\n${l.syncBlockedSaved}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          AppButton(
            label: l.syncNow,
            icon: Icons.sync,
            isLoading: _busy,
            onPressed: () => _perform(_flush),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * .55,
            child: FutureBuilder<QueueDetails>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return AppErrorView(
                    message: l.syncReadQueueError,
                    onRetry: _reload,
                  );
                }
                final (pending, dead) = snapshot.data!;
                return ListView(
                  children: <Widget>[
                    if (pending.isNotEmpty)
                      Text(l.syncPending(arabicNumber(pending.length))),
                    for (final op in pending)
                      ListTile(
                        leading: const Icon(Icons.schedule),
                        title: Text(op.displayLabel ?? label(l, op.type)),
                        subtitle: Text(l.syncSavedOnDeviceAwaiting),
                      ),
                    if (dead.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l.syncNoFailures,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (dead.isNotEmpty)
                      TextButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _perform(() async {
                                final db = ref.read(localDbProvider);
                                for (final entry in dead) {
                                  await db.requeue(entry.id);
                                }
                                return _flush();
                              }),
                        icon: const Icon(Icons.refresh),
                        label: Text(l.syncRetryAll),
                      ),
                    for (final entry in dead)
                      ListTile(
                        leading: const Icon(Icons.error_outline),
                        title: Text(entry.displayLabel ?? label(l, entry.type)),
                        subtitle: Text(reason(l, entry.lastError)),
                        trailing: Wrap(
                          children: <Widget>[
                            IconButton(
                              tooltip: l.syncRetry,
                              onPressed: _busy
                                  ? null
                                  : () => _perform(() async {
                                      await ref
                                          .read(localDbProvider)
                                          .requeue(entry.id);
                                      return _flush();
                                    }),
                              icon: const Icon(Icons.refresh),
                            ),
                            IconButton(
                              tooltip: l.syncDismiss,
                              onPressed: _busy
                                  ? null
                                  : () => _perform(() async {
                                      if (!await showAppConfirmSheet(
                                        context: context,
                                        title:
                                            entry.type ==
                                                OutboxOpType.tasmeeRecord
                                            ? l.syncDeleteScoreTitle
                                            : l.syncDeleteRecordTitle,
                                        message: l.syncDeleteRecordMessage,
                                        confirmLabel: l.syncDeletePermanently,
                                        destructive: true,
                                      )) {
                                        return false;
                                      }
                                      await ref
                                          .read(localDbProvider)
                                          .discard(entry.id);
                                      return true;
                                    }, success: l.syncRecordDeleted),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
