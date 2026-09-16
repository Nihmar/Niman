import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/diff/line_diff.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/diff/diff_view.dart';
import 'package:niman/src/ui/history/history_labels.dart';
import 'package:niman/src/ui/strings.dart';

/// One history version of a note against the note as it is now (mockups
/// H4–H5): the changes as a diff, or the version's whole text, and the
/// restore action.
///
/// The whole version goes back by default. Picking single changes turns
/// the action into a restore of those alone (issue #67): the note keeps
/// everything written since, except where the version was chosen.
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

  /// The diff on screen, once computed.
  DiffSummary? _summary;

  /// The hunks the version wins, by position in [_summary].
  final Set<int> _taken = {};

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

  /// Re-reads the note and, when it no longer matches what the diff was
  /// made from, refreshes the screen instead of writing over it.
  ///
  /// The note can move while the screen is open — a sync run, the editor
  /// in another window. A selective restore composes its text out of the
  /// note as it was read, so writing that text afterwards would quietly
  /// undo whatever landed meanwhile.
  Future<bool> _stillCurrent() async {
    final current = await widget.ops.readNote(widget.path);
    if (current == _currentText) return true;
    if (!mounted) return false;
    _log.info('"${widget.path}" changed under the version screen');
    setState(() {
      _currentText = current;
      _summary = null;
      _taken.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.historyNoteChangedReloaded)),
    );
    return false;
  }

  Future<void> _restore() async {
    final selected = _taken.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('history-restore-dialog'),
        title: Text(AppStrings.historyRestoreConfirmTitle(_when)),
        content: Text(
          selected == 0
              ? AppStrings.historyRestoreConfirmBody
              : AppStrings.historyRestoreSelectedConfirmBody,
        ),
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
    try {
      if (!await _stillCurrent()) {
        if (mounted) setState(() => _restoring = false);
        return;
      }
      final summary = _summary;
      final current = _currentText;
      if (selected == 0 || summary == null || current == null) {
        _log.info('restore "${widget.path}" v${widget.version.number} (ui)');
        await widget.ops.restoreNoteVersion(widget.path, widget.version.number);
      } else {
        _log.info(
          'restore $selected of ${summary.hunks.length} change(s) from '
          '"${widget.path}" v${widget.version.number} (ui)',
        );
        await widget.ops.restoreNoteText(
          widget.path,
          summary.compose(
            _taken,
            lineEnding: current.contains('\r\n') ? '\r\n' : '\n',
            trailingNewline: current.isEmpty || current.endsWith('\n'),
          ),
        );
      }
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
                          onSummary: (summary) {
                            if (mounted) setState(() => _summary = summary);
                          },
                          hunkAction: (context, hunk) => FilterChip(
                            key: ValueKey('history-take-$hunk'),
                            label: Text(AppStrings.historyTakeHunk),
                            selected: _taken.contains(hunk),
                            visualDensity: VisualDensity.compact,
                            onSelected: _restoring
                                ? null
                                : (on) => setState(() {
                                    if (on) {
                                      _taken.add(hunk);
                                    } else {
                                      _taken.remove(hunk);
                                    }
                                  }),
                          ),
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
                  label: Text(
                    _taken.isEmpty
                        ? AppStrings.historyRestoreAction
                        : AppStrings.historyRestoreSelectedAction(
                            _taken.length,
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  static String _capitalized(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
