import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/diff/diff_view.dart';
import 'package:niman/src/ui/history/history_labels.dart';
import 'package:niman/src/ui/strings.dart';

/// One history version of a note against the note as it is now (mockups
/// H4–H5): the changes as a diff, or the version's whole text, and the
/// restore action.
///
/// Pops with `true` once the version has been restored.
final class NoteVersionScreen extends StatefulWidget {
  /// Shows [version] of the note at library-relative [path].
  const new({
    required this.ops,
    required this.path,
    required this.version,
    this.now = DateTime.now,
    this.compute = computeDiff,
    super.key,
  });

  /// The open library's operations.
  final NoteOperations ops;

  /// The note, library-relative.
  final String path;

  /// The version shown.
  final HistoryVersion version;

  /// The clock the day labels are read against (a test seam).
  final DateTime Function() now;

  /// Diff computation (a test seam).
  final DiffComputer compute;

  @override
  State<NoteVersionScreen> createState() => _NoteVersionScreenState();
}

final class _NoteVersionScreenState extends State<NoteVersionScreen> {
  static const _log = AppLogger(name: 'history');

  String? _versionText;
  String? _currentText;
  Object? _error;
  bool _showText = false;
  bool _restoring = false;

  String get _when => historyWhen(widget.version.savedAt, widget.now());

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final version = await widget.ops.readNoteVersion(
        widget.path,
        widget.version.number,
      );
      final current = await widget.ops.readNote(widget.path);
      if (!mounted) return;
      setState(() {
        _versionText = version;
        _currentText = current;
      });
    } on Object catch (e) {
      _log.error('open "${widget.path}" v${widget.version.number}: $e');
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('history-restore-dialog'),
        title: Text(AppStrings.historyRestoreConfirmTitle(_when)),
        content: Text(AppStrings.historyRestoreConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            key: const Key('history-restore-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.historyRestoreConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _restoring = true);
    _log.info('restore "${widget.path}" v${widget.version.number} (ui)');
    try {
      await widget.ops.restoreNoteVersion(widget.path, widget.version.number);
      if (mounted) Navigator.pop(context, true);
    } on Object catch (e) {
      _log.error('restore "${widget.path}" v${widget.version.number}: $e');
      if (!mounted) return;
      setState(() => _restoring = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.historyRestoreFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final versionText = _versionText;
    final currentText = _currentText;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_capitalized(_when)),
            Text(
              AppStrings.historyCompareSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: _error != null
          ? Center(child: Text(AppStrings.historyLoadFailed))
          : versionText == null || currentText == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: SegmentedButton<bool>(
                    key: const Key('history-view-switch'),
                    segments: [
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.difference_outlined),
                        label: Text(AppStrings.historyTabChanges),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.article_outlined),
                        label: Text(AppStrings.historyTabVersion),
                      ),
                    ],
                    selected: {_showText},
                    onSelectionChanged: (s) =>
                        setState(() => _showText = s.single),
                  ),
                ),
                Expanded(
                  child: _showText
                      ? SingleChildScrollView(
                          key: const Key('history-version-text'),
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            versionText,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        )
                      : DiffView(
                          oldText: versionText,
                          newText: currentText,
                          compute: widget.compute,
                          padding: const EdgeInsets.only(bottom: 16),
                        ),
                ),
              ],
            ),
      bottomNavigationBar: versionText == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  key: const Key('history-restore'),
                  onPressed: _restoring || versionText == currentText
                      ? null
                      : _restore,
                  icon: const Icon(Icons.restore),
                  label: Text(AppStrings.historyRestoreAction),
                ),
              ),
            ),
    );
  }

  static String _capitalized(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
