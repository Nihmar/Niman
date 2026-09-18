import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/history/history_labels.dart';
import 'package:niman/src/ui/strings.dart';

/// The dock's history (#175): the note's kept versions, newest first,
/// when and why each was kept. Comparing and restoring stay where they
/// are, in the history screen: a version, or All versions, opens it.
final class HistoryDockPane extends StatefulWidget {
  /// The history of the note at library-relative [path].
  const new({
    required this.ops,
    required this.path,
    required this.onOpenHistory,
    this.now = DateTime.now,
    super.key,
  });

  /// The open library's operations; null while none is ready.
  final NoteOperations? ops;

  /// The note shown beside; null when none is open.
  final String? path;

  /// Opens the history screen for the note.
  final VoidCallback onOpenHistory;

  /// The clock the labels are read against (a test seam).
  final DateTime Function() now;

  @override
  State<HistoryDockPane> createState() => _HistoryDockPaneState();
}

final class _HistoryDockPaneState extends State<HistoryDockPane> {
  List<HistoryVersion>? _versions;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(HistoryDockPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) unawaited(_load());
  }

  Future<void> _load() async {
    final ops = widget.ops;
    final path = widget.path;
    if (ops == null || path == null) return;
    setState(() => _versions = null);
    final manifest = await ops.noteHistory(path);
    if (!mounted || widget.path != path) return;
    setState(() => _versions = manifest.versions.reversed.toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final versions = _versions;
    if (widget.path == null) return const SizedBox.shrink();
    if (versions == null) return const LinearProgressIndicator(minHeight: 2);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final now = widget.now();
    return ListView(
      key: const Key('dock-history'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        if (versions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(AppStrings.historyEmpty, style: muted),
          ),
        for (final version in versions)
          ListTile(
            key: Key('dock-history-${version.number}'),
            dense: true,
            leading: const Icon(Icons.history, size: 18),
            title: Text(historyWhen(version.savedAt, now)),
            subtitle: Text(historyReasonLabel(version.reason)),
            onTap: widget.onOpenHistory,
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: TextButton(
              key: const Key('dock-history-all'),
              onPressed: widget.onOpenHistory,
              child: Text(AppStrings.historyAllVersions),
            ),
          ),
        ),
      ],
    );
  }
}
