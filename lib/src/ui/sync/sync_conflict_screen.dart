import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/diff/three_way.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/sync/conflict_texts.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/ui/diff/merge_view.dart';
import 'package:niman/src/ui/strings.dart';

/// One conflicted file (mockup S8, W7): with the version both sides came
/// from, the merge region by region — the edits that do not overlap are
/// already in, the ones that do are the user's to choose; without one,
/// every place the two copies differ is a choice. Either way a whole
/// copy can be kept.
///
/// Pops with `true` once the conflict is resolved.
final class SyncConflictScreen extends StatefulWidget {
  /// The conflict at library-relative [path].
  const new({
    required this.sync,
    required this.path,
    this.merge = computeMerge,
    super.key,
  });

  /// The library's sync.
  final SyncService sync;

  /// The conflicted file.
  final String path;

  /// Merge computation (a test seam).
  final MergeComputer merge;

  @override
  State<SyncConflictScreen> createState() => _SyncConflictScreenState();
}

final class _SyncConflictScreenState extends State<SyncConflictScreen> {
  static const _log = AppLogger(name: 'sync');

  ConflictTexts? _texts;
  MergeResult? _merge;
  List<MergeChoice> _choices = const [];
  bool _failed = false;
  bool _resolving = false;

  bool get _isText => NoteOps.keepsHistory(widget.path);

  @override
  void initState() {
    super.initState();
    if (_isText) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final texts = await widget.sync.conflictTexts(widget.path);
      final merge = await widget.merge(texts.base, texts.local, texts.remote);
      _log.info(
        'conflict screen ${widget.path}: '
        '${texts.base == null ? 'no base, ' : ''}${merge.describe()}',
      );
      if (!mounted) return;
      setState(() {
        _texts = texts;
        _merge = merge;
        _choices = List.filled(merge.conflicts.length, MergeChoice.local);
        _resolving = false;
      });
    } on SyncFailure catch (e) {
      _log.warning('conflict screen ${widget.path}: $e');
      if (mounted) {
        setState(() {
          _failed = true;
          _resolving = false;
        });
      }
    }
  }

  Future<void> _resolve(Future<void> Function() action, String what) async {
    setState(() => _resolving = true);
    _log.info('conflict screen ${widget.path}: $what');
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(
        SnackBar(
          key: const Key('sync-resolved-snack'),
          content: Text(AppStrings.syncResolved),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on SyncFailure catch (e) {
      _log.warning('conflict screen ${widget.path}: $what failed: $e');
      if (!mounted) return;
      if (e.moved && _isText) {
        // Nothing was written: show the versions as they are now, and let
        // the user choose again over them.
        messenger.showSnackBar(
          SnackBar(
            key: const Key('sync-conflict-moved-snack'),
            content: Text(AppStrings.syncConflictMoved),
          ),
        );
        setState(() => _texts = null);
        await _load();
        return;
      }
      setState(() => _resolving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.moved
                ? AppStrings.syncConflictMoved
                : AppStrings.syncResolveFailed,
          ),
        ),
      );
    }
  }

  Future<void> _keep({required bool local}) => _resolve(
    () => widget.sync.resolveConflict(
      widget.path,
      keepLocal: local,
      shown: _texts,
    ),
    'keep ${local ? 'local' : 'remote'}',
  );

  Future<void> _saveMerge() {
    final merge = _merge!;
    final shown = _texts!;
    return _resolve(
      () => widget.sync.resolveMerged(
        widget.path,
        merge.text(_choices),
        shown: shown,
      ),
      'save the merge (${merge.describe()})',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = _texts;
    final merge = _merge;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    Widget note(IconData icon, String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: muted)),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.syncConflictTitle),
            Text(widget.path, style: muted, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isText)
            note(Icons.info_outline, AppStrings.syncConflictBinary)
          else if (_failed)
            note(Icons.error_outline, AppStrings.syncConflictLoadFailed)
          else if (texts == null || merge == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            note(
              Icons.merge_type,
              texts.base == null
                  ? AppStrings.syncMergeNoBase
                  : merge.clean
                  ? AppStrings.syncMergeClean
                  : AppStrings.syncMergeIntro,
            ),
            Expanded(
              child: MergeView(
                key: const Key('sync-conflict-merge'),
                merge: merge,
                choices: _choices,
                onChoice: (index, choice) => setState(() {
                  _choices = [..._choices]..[index] = choice;
                }),
                padding: const EdgeInsets.only(bottom: 16),
              ),
            ),
          ],
          if (!_isText || _failed) const Spacer(),
          note(Icons.history, AppStrings.syncConflictKeepNote),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (merge != null) ...[
                FilledButton.icon(
                  key: const Key('sync-save-merge'),
                  onPressed: _resolving ? null : _saveMerge,
                  icon: const Icon(Icons.merge_type),
                  label: Text(AppStrings.syncMergeSave),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 2),
                  child: Text(
                    AppStrings.syncMergeKeepWhole,
                    style: muted,
                    textAlign: TextAlign.center,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('sync-keep-local'),
                        onPressed: _resolving ? null : () => _keep(local: true),
                        icon: const Icon(Icons.smartphone),
                        label: Text(AppStrings.syncKeepLocal),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('sync-keep-remote'),
                        onPressed: _resolving
                            ? null
                            : () => _keep(local: false),
                        icon: const Icon(Icons.dns_outlined),
                        label: Text(AppStrings.syncKeepRemote),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                FilledButton.icon(
                  key: const Key('sync-keep-local'),
                  onPressed: _resolving ? null : () => _keep(local: true),
                  icon: const Icon(Icons.smartphone),
                  label: Text(AppStrings.syncKeepLocal),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('sync-keep-remote'),
                  onPressed: _resolving ? null : () => _keep(local: false),
                  icon: const Icon(Icons.dns_outlined),
                  label: Text(AppStrings.syncKeepRemote),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
