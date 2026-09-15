import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/ui/diff/diff_view.dart';
import 'package:niman/src/ui/strings.dart';

/// One conflicted file, both versions side by side in the diff, and the
/// choice of which whole copy to keep (mockup S8). The merge by hunks is
/// the next step; this screen is where it will live.
///
/// Pops with `true` once the conflict is resolved.
final class SyncConflictScreen extends StatefulWidget {
  /// The conflict at library-relative [path].
  const new({
    required this.sync,
    required this.path,
    this.compute = computeDiff,
    super.key,
  });

  /// The library's sync.
  final SyncService sync;

  /// The conflicted file.
  final String path;

  /// Diff computation (a test seam).
  final DiffComputer compute;

  @override
  State<SyncConflictScreen> createState() => _SyncConflictScreenState();
}

final class _SyncConflictScreenState extends State<SyncConflictScreen> {
  static const _log = AppLogger(name: 'sync');

  ({String local, String remote})? _texts;
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
      if (mounted) setState(() => _texts = texts);
    } on SyncFailure catch (e) {
      _log.warning('conflict screen ${widget.path}: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _keep({required bool local}) async {
    setState(() => _resolving = true);
    _log.info(
      'conflict screen ${widget.path}: keep ${local ? 'local' : 'remote'}',
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.sync.resolveConflict(widget.path, keepLocal: local);
      messenger.showSnackBar(
        SnackBar(
          key: const Key('sync-resolved-snack'),
          content: Text(AppStrings.syncResolved),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on SyncFailure catch (e) {
      _log.warning('conflict screen ${widget.path}: resolve failed: $e');
      if (!mounted) return;
      setState(() => _resolving = false);
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.syncResolveFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texts = _texts;
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
          else ...[
            note(Icons.info_outline, AppStrings.syncConflictLegend),
            Expanded(
              child: texts == null
                  ? const Center(child: CircularProgressIndicator())
                  : DiffView(
                      key: const Key('sync-conflict-diff'),
                      oldText: texts.remote,
                      newText: texts.local,
                      compute: widget.compute,
                      identicalMessage: AppStrings.syncConflictIdentical,
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
          ),
        ),
      ),
    );
  }
}
