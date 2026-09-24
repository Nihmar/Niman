import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:niman/src/diff/three_way.dart';
import 'package:niman/src/diff/two_way_merge.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/tokens.dart';

/// Merges two sides over their [base], or without one when it is null;
/// the default runs off the UI isolate for long texts.
typedef MergeComputer = Future<MergeResult> Function(
  String? base,
  String local,
  String remote,
);

/// Texts up to this many characters (all three together) merge on the UI
/// isolate: an isolate costs more than the merge, and widget tests cannot
/// run one.
const int _inlineMergeLimit = 20000;

/// The three-way merge of [base], [local] and [remote], or the two-way
/// one ([mergeTwoWay]) when there is no [base].
Future<MergeResult> computeMerge(String? base, String local, String remote) {
  MergeResult merge() => base == null
      ? mergeTwoWay(local, remote)
      : mergeThreeWay(base, local, remote);
  final size = (base?.length ?? 0) + local.length + remote.length;
  if (size <= _inlineMergeLimit) return Future.value(merge());
  return Isolate.run(merge);
}

/// The merge of a conflicted note, region by region (issue #67, mockup
/// W7): what came from each side on its own, and, where both changed the
/// same lines, the choice between them.
///
/// Presentation only: the caller holds the [choices] and writes the text.
final class MergeView extends StatefulWidget {
  /// Shows [merge], with one entry of [choices] per conflict.
  const new({
    required this.merge,
    required this.choices,
    required this.onChoice,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// The merge to show.
  final MergeResult merge;

  /// The choice made for each conflict, in order.
  final List<MergeChoice> choices;

  /// Called when the user picks a side for the conflict at that index.
  final void Function(int index, MergeChoice choice) onChoice;

  /// Padding around the list.
  final EdgeInsets padding;

  @override
  State<MergeView> createState() => _MergeViewState();
}

final class _MergeViewState extends State<MergeView> {
  /// Unchanged regions the user unfolded, by chunk index.
  final Set<int> _open = {};

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var conflict = 0;
    for (var i = 0; i < widget.merge.chunks.length; i++) {
      final chunk = widget.merge.chunks[i];
      switch (chunk.kind) {
        case MergeKind.unchanged:
          rows.add(_unchanged(context, i, chunk));
        case MergeKind.local:
          rows.add(
            _taken(
              context,
              chunk.local,
              AppStrings.syncMergeFromLocal,
              local: true,
            ),
          );
        case MergeKind.remote:
          rows.add(
            _taken(
              context,
              chunk.remote,
              AppStrings.syncMergeFromRemote,
              local: false,
            ),
          );
        case MergeKind.conflict:
          final index = conflict++;
          rows.add(
            _conflict(
              context,
              chunk: chunk,
              index: index,
              total: widget.merge.conflicts.length,
            ),
          );
      }
    }
    return ListView(
      key: const Key('merge-view'),
      padding: widget.padding,
      children: rows,
    );
  }

  /// A run neither side touched: folded unless the user opened it, and
  /// always shown when it is short.
  Widget _unchanged(BuildContext context, int index, MergeChunk chunk) {
    final theme = Theme.of(context);
    if (chunk.local.length <= 3 || _open.contains(index)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final line in chunk.local) _line(context, line, null)],
      );
    }
    return InkWell(
      key: ValueKey('merge-gap-$index'),
      onTap: () => setState(() => _open.add(index)),
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
              AppStrings.diffUnchanged(chunk.local.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A region only one side changed: already merged, labelled with where
  /// it came from.
  Widget _taken(
    BuildContext context,
    List<String> lines,
    String label, {
    required bool local,
  }) {
    final theme = Theme.of(context);
    final color = local
        ? SyntaxColors.of(context).task
        : theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          child: Row(
            children: [
              Icon(
                local ? Icons.smartphone : Icons.dns_outlined,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
        if (lines.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(29, 0, 16, 4),
            child: Text(
              AppStrings.syncMergeRemovedLines,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final line in lines) _line(context, line, color),
      ],
    );
  }

  /// A region both sides changed: their lines, and the choice.
  Widget _conflict(
    BuildContext context, {
    required MergeChunk chunk,
    required int index,
    required int total,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final choice = index < widget.choices.length
        ? widget.choices[index]
        : MergeChoice.local;
    final mine = SyntaxColors.of(context).task;
    Widget side(
      String label,
      List<String> lines,
      Color color, {
      required bool on,
    }) => Opacity(
      opacity: on ? 1 : 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Text(
                // An overlap with no base lines only arises without a base
                // (with one, a side with nothing there did not touch it):
                // the lines are missing from this copy, not removed.
                chunk.base.isEmpty
                    ? AppStrings.syncMergeAbsentLines
                    : AppStrings.syncMergeRemovedLines,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final line in lines) _line(context, line, color),
        ],
      ),
    );
    return Card.outlined(
      key: ValueKey('merge-conflict-$index'),
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Text(
              AppStrings.syncMergeOverlap(index + 1, total),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.tertiary,
              ),
            ),
          ),
          side(
            AppStrings.syncMergeFromLocal,
            chunk.local,
            mine,
            on: choice != MergeChoice.remote,
          ),
          side(
            AppStrings.syncMergeFromRemote,
            chunk.remote,
            scheme.primary,
            on: choice != MergeChoice.local,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: SegmentedButton<MergeChoice>(
              key: ValueKey('merge-choice-$index'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: MergeChoice.local,
                  label: Text(AppStrings.syncMergeKeepLocal),
                ),
                ButtonSegment(
                  value: MergeChoice.remote,
                  label: Text(AppStrings.syncMergeKeepRemote),
                ),
                ButtonSegment(
                  value: MergeChoice.both,
                  label: Text(AppStrings.syncMergeKeepBoth),
                ),
              ],
              selected: {choice},
              onSelectionChanged: (picked) =>
                  widget.onChoice(index, picked.first),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String text, Color? mark) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: mark?.withValues(alpha: 0.13),
        border: Border(
          left: BorderSide(color: mark ?? Colors.transparent, width: 3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Text(
        text.isEmpty ? ' ' : text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.5,
          height: 1.5,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
