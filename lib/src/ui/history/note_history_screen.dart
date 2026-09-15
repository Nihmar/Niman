import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/diff/diff_view.dart';
import 'package:niman/src/ui/history/history_labels.dart';
import 'package:niman/src/ui/history/note_version_screen.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/tokens.dart';
import 'package:path/path.dart' as p;

/// The kept versions of one note (issue #55, mockup H3): the current
/// version on top, then the versions newest first, grouped by day, each
/// with why it was kept and how many lines differ between it and the note
/// as it is now (`+` added since, `−` gone since).
///
/// Pops with the restored [HistoryVersion] when one was restored, so the
/// caller can reload the note and offer Undo.
final class NoteHistoryScreen extends StatefulWidget {
  /// Lists the history of the note at library-relative [path]; [limit] is
  /// the library's `historyVersions`, for the footer.
  const new({
    required this.ops,
    required this.path,
    required this.limit,
    this.now = DateTime.now,
    this.compute = computeDiff,
    super.key,
  });

  /// The open library's operations.
  final NoteOperations ops;

  /// The note, library-relative.
  final String path;

  /// How many versions the library keeps.
  final int limit;

  /// The clock the day labels are read against (a test seam).
  final DateTime Function() now;

  /// Diff computation (a test seam).
  final DiffComputer compute;

  @override
  State<NoteHistoryScreen> createState() => _NoteHistoryScreenState();
}

final class _NoteHistoryScreenState extends State<NoteHistoryScreen> {
  static const _log = AppLogger(name: 'history');

  HistoryManifest? _manifest;
  Object? _error;

  /// `(added, removed)` per version number, filled in as they compute.
  final Map<int, (int, int)> _stats = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final manifest = await widget.ops.noteHistory(widget.path);
      if (!mounted) return;
      setState(() {
        _manifest = manifest;
        _error = null;
      });
      _log.info(
        'history screen "${widget.path}": '
        '${manifest.versions.length} version(s)',
      );
      await _loadStats(manifest);
    } on Object catch (e) {
      _log.error('history screen "${widget.path}": $e');
      if (mounted) setState(() => _error = e);
    }
  }

  /// Diffs each version against the current note — the same comparison
  /// the version screen opens on, so a row's numbers match what tapping it
  /// shows — newest first, so the rows fill in without holding the list
  /// back.
  Future<void> _loadStats(HistoryManifest manifest) async {
    final String current;
    try {
      current = await widget.ops.readNote(widget.path);
    } on Object catch (e) {
      _log.warning('stats "${widget.path}": current text unreadable: $e');
      return;
    }
    for (final version in manifest.versions.reversed) {
      final String text;
      try {
        text = await widget.ops.readNoteVersion(widget.path, version.number);
      } on Object catch (e) {
        _log.warning('stats "${widget.path}" v${version.number}: $e');
        continue;
      }
      final summary = await widget.compute(text, current);
      if (!mounted) return;
      setState(() {
        _stats[version.number] = (summary.added, summary.removed);
      });
    }
  }

  Future<void> _open(HistoryVersion version) async {
    final restored = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => NoteVersionScreen(
          ops: widget.ops,
          path: widget.path,
          version: version,
          now: widget.now,
          compute: widget.compute,
        ),
      ),
    );
    if (restored == true && mounted) Navigator.pop(context, version);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.noteHistoryTitle),
            Text(
              p.basename(widget.path),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final manifest = _manifest;
    if (_error != null) {
      return Center(child: Text(AppStrings.historyLoadFailed));
    }
    if (manifest == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);
    final now = widget.now();
    final newestFirst = manifest.versions.reversed.toList();
    final children = <Widget>[
      ListTile(
        key: const Key('history-current'),
        leading: const Icon(Icons.edit_note),
        title: Text(AppStrings.historyCurrentVersion),
        subtitle: Text(AppStrings.historyCurrentSubtitle),
        tileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      ),
    ];
    String? day;
    for (final version in newestFirst) {
      final label = historyDay(version.savedAt, now);
      if (label != day) {
        day = label;
        children.add(_DayHeader(label));
      }
      children.add(
        _VersionRow(
          version: version,
          pinned: manifest.isPinned(version.number),
          stats: _stats[version.number],
          onTap: () => _open(version),
        ),
      );
    }
    if (newestFirst.isEmpty) {
      children.add(
        Padding(
          key: const Key('history-empty'),
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.limit == 0 ? AppStrings.historyOff : AppStrings.historyEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    } else {
      final unpinned = manifest.versions
          .where((v) => !manifest.isPinned(v.number))
          .length;
      children.add(
        Padding(
          key: const Key('history-footer'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [
                    AppStrings.historyKept(unpinned, widget.limit),
                    if (manifest.pins.isNotEmpty) AppStrings.historyBaseKept,
                  ].join(' '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(key: const Key('history-list'), children: children);
  }
}

final class _DayHeader extends StatelessWidget {
  const new(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

final class _VersionRow extends StatelessWidget {
  const new({
    required this.version,
    required this.pinned,
    required this.stats,
    required this.onTap,
  });

  final HistoryVersion version;
  final bool pinned;
  final (int, int)? stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mono = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final stats = this.stats;
    return InkWell(
      key: ValueKey('history-version-${version.number}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(historyTime(version.savedAt), style: mono),
            ),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Tag(historyReasonLabel(version.reason)),
                  if (pinned)
                    _Tag(
                      AppStrings.historySyncBase,
                      icon: Icons.push_pin,
                      key: const Key('history-sync-base'),
                      accent: true,
                    ),
                ],
              ),
            ),
            if (stats != null)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '+${stats.$1}',
                      style: TextStyle(color: SyntaxColors.of(context).task),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: '−${stats.$2}',
                      style: TextStyle(color: scheme.error),
                    ),
                  ],
                ),
                style: mono?.copyWith(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

final class _Tag extends StatelessWidget {
  const new(this.label, {this.icon, this.accent = false, super.key});

  final String label;
  final IconData? icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = accent ? scheme.primary : scheme.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent ? scheme.primary.withValues(alpha: 0.18) : null,
        border: accent ? null : Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
