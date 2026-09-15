import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/diff/line_diff.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/tokens.dart';

/// Computes the diff of two texts; the default runs off the UI isolate
/// for long texts.
typedef DiffComputer = Future<DiffSummary> Function(
  String oldText,
  String newText,
);

/// Texts up to this many characters (both together) are diffed on the
/// UI isolate: an isolate costs more than the diff itself, and widget
/// tests cannot run one.
const int _inlineDiffLimit = 20000;

/// The diff of [oldText] and [newText], summarized into hunks.
Future<DiffSummary> computeDiff(String oldText, String newText) {
  if (oldText.length + newText.length <= _inlineDiffLimit) {
    return Future.value(DiffSummary.of(diffLines(oldText, newText)));
  }
  return Isolate.run(() => DiffSummary.of(diffLines(oldText, newText)));
}

/// A read-only line diff (issue #67): removed lines red, added lines
/// green, unchanged runs between the changes folded into a row that
/// unfolds on tap.
///
/// Presentation only — it knows nothing about history or sync. The
/// caller supplies the texts and puts its own actions (restore, keep
/// mine…) around it. Rows build lazily, so a long note scrolls without
/// laying out every line.
final class DiffView extends StatefulWidget {
  /// Shows how [oldText] became [newText].
  const new({
    required this.oldText,
    required this.newText,
    this.identicalMessage,
    this.compute = computeDiff,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// The text on the "before" side.
  final String oldText;

  /// The text on the "after" side.
  final String newText;

  /// Shown instead of the diff when the texts are the same.
  final String? identicalMessage;

  /// Diff computation (a test seam).
  final DiffComputer compute;

  /// Padding around the list.
  final EdgeInsets padding;

  @override
  State<DiffView> createState() => _DiffViewState();
}

final class _DiffViewState extends State<DiffView> {
  static const _log = AppLogger(name: 'diff');

  DiffSummary? _summary;
  Object? _error;

  /// Gap indices the user unfolded.
  final Set<int> _open = {};

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  @override
  void didUpdateWidget(DiffView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.oldText != widget.oldText ||
        oldWidget.newText != widget.newText) {
      _open.clear();
      unawaited(_run());
    }
  }

  Future<void> _run() async {
    final oldText = widget.oldText;
    final newText = widget.newText;
    final clock = Stopwatch()..start();
    try {
      final summary = await widget.compute(oldText, newText);
      _log.debug(
        'diff ${oldText.length} -> ${newText.length} chars: '
        '${summary.hunks.length} hunk(s), +${summary.added} '
        '-${summary.removed} (${clock.elapsedMilliseconds} ms)',
      );
      if (!mounted || widget.oldText != oldText || widget.newText != newText) {
        return;
      }
      setState(() {
        _summary = summary;
        _error = null;
      });
    } on Object catch (e) {
      _log.error('diff failed: $e');
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    if (_error != null) {
      return Center(child: Text('$_error'));
    }
    if (summary == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (summary.identical) {
      return Center(
        key: const Key('diff-identical'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.identicalMessage ?? AppStrings.historyNoChanges,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final rows = _rows(summary);
    return ListView.builder(
      key: const Key('diff-view'),
      padding: widget.padding,
      itemCount: rows.length,
      itemBuilder: (context, index) => rows[index].build(context),
    );
  }

  /// The rows on screen: for each hunk a header and its lines, with the
  /// unchanged runs around them folded (or unfolded) in between.
  List<_Row> _rows(DiffSummary summary) {
    final rows = <_Row>[];
    void gap(int index, int from, int to) {
      if (to <= from) return;
      if (_open.contains(index)) {
        for (var i = from; i < to; i++) {
          rows.add(_LineRow(summary.lines[i]));
        }
      } else {
        rows.add(
          _GapRow(
            index: index,
            count: to - from,
            onTap: () => setState(() => _open.add(index)),
          ),
        );
      }
    }

    var previousEnd = 0;
    for (var h = 0; h < summary.hunks.length; h++) {
      final (start, end) = summary.ranges[h];
      gap(h, previousEnd, start);
      rows.add(_HeaderRow(summary.hunks[h]));
      for (final line in summary.hunks[h].lines) {
        rows.add(_LineRow(line));
      }
      previousEnd = end;
    }
    gap(summary.hunks.length, previousEnd, summary.lines.length);
    return rows;
  }
}

sealed class _Row {
  const new();

  Widget build(BuildContext context);
}

final class _HeaderRow extends _Row {
  const new(this.hunk);

  final DiffHunk hunk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Numbered on the new side when it has lines, the old side otherwise
    // (a hunk that only removes).
    final start = hunk.newStart == 0 ? hunk.oldStart : hunk.newStart;
    final end = hunk.newStart == 0 ? hunk.oldEnd : hunk.newEnd;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        start == end
            ? AppStrings.diffLineSingle(start)
            : AppStrings.diffLineRange(start, end),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

final class _LineRow extends _Row {
  const new(this.line);

  final DiffLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final added = SyntaxColors.of(context).task;
    final (Color? mark, Color? fill, String sign) = switch (line.kind) {
      DiffKind.same => (null, null, ' '),
      DiffKind.removed => (
        scheme.error,
        scheme.error.withValues(alpha: 0.13),
        '−',
      ),
      DiffKind.added => (added, added.withValues(alpha: 0.13), '+'),
    };
    final style = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12.5,
      height: 1.5,
      color: scheme.onSurface,
    );
    return Container(
      key: ValueKey(
        'diff-line-${line.kind.name}-${line.oldLine}-${line.newLine}',
      ),
      decoration: BoxDecoration(
        color: fill,
        border: Border(
          left: BorderSide(color: mark ?? Colors.transparent, width: 3),
        ),
      ),
      padding: const EdgeInsets.only(left: 9, right: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 14,
            child: Text(
              sign,
              style: style.copyWith(color: mark ?? scheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(line.text, style: style)),
        ],
      ),
    );
  }
}

final class _GapRow extends _Row {
  const new({required this.index, required this.count, required this.onTap});

  final int index;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: ValueKey('diff-gap-$index'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.unfold_more,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              AppStrings.diffUnchanged(count),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
