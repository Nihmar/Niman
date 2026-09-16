/// Three-way line merge (issues #17, #67): what two devices did to the
/// same note since the version both agreed on.
///
/// Pure and synchronous, over [diffLines]; callers with long notes run it
/// in an isolate. It merges lines, not words: two edits on the same line
/// are a conflict, even when they touch different halves of it.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/diff/line_diff.dart';

/// What happened to one region of the base text.
enum MergeKind {
  /// Neither side touched it, or both made the same change.
  unchanged,

  /// Only this device changed it.
  local,

  /// Only the server's copy changed it.
  remote,

  /// Both changed it, differently.
  conflict,
}

/// Which side of a conflict the merge takes.
enum MergeChoice {
  /// This device's lines.
  local,

  /// The server's lines.
  remote,

  /// Both, this device's first.
  both,
}

/// One region of a merged text.
@immutable
final class MergeChunk {
  /// A region of [kind]; the three sides hold its lines.
  const new({
    required this.kind,
    required this.base,
    required this.local,
    required this.remote,
  });

  /// What happened here.
  final MergeKind kind;

  /// The lines as the agreed version had them.
  final List<String> base;

  /// The lines this device has.
  final List<String> local;

  /// The lines the server has.
  final List<String> remote;

  /// The lines the merge takes, given a [choice] for a conflict.
  List<String> resolved([MergeChoice choice = MergeChoice.local]) =>
      switch (kind) {
        MergeKind.unchanged => local,
        MergeKind.local => local,
        MergeKind.remote => remote,
        MergeKind.conflict => switch (choice) {
          MergeChoice.local => local,
          MergeChoice.remote => remote,
          MergeChoice.both => [...local, ...remote],
        },
      };

  @override
  String toString() =>
      '${kind.name}(base ${base.length}, local ${local.length}, '
      'remote ${remote.length})';
}

/// The merge of one note: its regions, and the text they make.
@immutable
final class MergeResult {
  /// A merge made of [chunks], whose text ends with [lineEnding] runs and
  /// a final break when [trailingNewline].
  const new({
    required this.chunks,
    this.lineEnding = '\n',
    this.trailingNewline = true,
  });

  /// The regions, in order.
  final List<MergeChunk> chunks;

  /// The line break the merged text uses (the local text's).
  final String lineEnding;

  /// Whether the merged text ends with a line break (as the local one
  /// does).
  final bool trailingNewline;

  /// The regions both sides changed differently.
  Iterable<MergeChunk> get conflicts =>
      chunks.where((c) => c.kind == MergeKind.conflict);

  /// Whether nothing overlaps, so the merge needs no one's choice.
  bool get clean => conflicts.isEmpty;

  /// Whether the merge changes what this device has.
  bool get changesLocal =>
      chunks.any((c) => c.kind == MergeKind.remote) || !clean;

  /// The merged text; [choices] answers the i-th conflict (missing
  /// answers keep the local side).
  String text([List<MergeChoice> choices = const []]) {
    final lines = <String>[];
    var conflict = 0;
    for (final chunk in chunks) {
      if (chunk.kind == MergeKind.conflict) {
        final choice = conflict < choices.length
            ? choices[conflict]
            : MergeChoice.local;
        conflict++;
        lines.addAll(chunk.resolved(choice));
      } else {
        lines.addAll(chunk.resolved());
      }
    }
    if (lines.isEmpty) return '';
    return lines.join(lineEnding) + (trailingNewline ? lineEnding : '');
  }

  /// A log-ready summary.
  String describe() {
    final counts = <MergeKind, int>{};
    for (final chunk in chunks) {
      counts.update(chunk.kind, (n) => n + 1, ifAbsent: () => 1);
    }
    return [
      for (final kind in MergeKind.values)
        if ((counts[kind] ?? 0) > 0) '${kind.name} ${counts[kind]}',
    ].join(', ');
  }
}

/// Merges what [local] and [remote] each did to [base].
///
/// A region only one side changed is taken from that side; a region both
/// changed the same way is taken once; a region both changed differently
/// is a [MergeKind.conflict], with all three sides kept so the caller can
/// choose. The line ending and the trailing break come from [local].
MergeResult mergeThreeWay(String base, String local, String remote) {
  final baseLines = splitLines(base);
  final localLines = splitLines(local);
  final remoteLines = splitLines(remote);
  final toLocal = _alignment(baseLines.length, diffLines(base, local));
  final toRemote = _alignment(baseLines.length, diffLines(base, remote));

  final chunks = <MergeChunk>[];
  var b = 0;
  var l = 0;
  var r = 0;
  final pending = <String>[];
  void flushUnchanged() {
    if (pending.isEmpty) return;
    chunks.add(
      MergeChunk(
        kind: MergeKind.unchanged,
        base: List.unmodifiable(pending),
        local: List.unmodifiable(pending),
        remote: List.unmodifiable(pending),
      ),
    );
    pending.clear();
  }

  while (b < baseLines.length) {
    if (toLocal[b] == l && toRemote[b] == r) {
      // Both sides still have this base line, right where we are.
      pending.add(baseLines[b]);
      b++;
      l++;
      r++;
      continue;
    }
    // Everything up to the next line both sides kept in step is one
    // region; the sides may have different amounts of it.
    var end = b + 1;
    while (end < baseLines.length &&
        (toLocal[end] == null || toRemote[end] == null)) {
      end++;
    }
    final localEnd = end < baseLines.length ? toLocal[end]! : localLines.length;
    final remoteEnd = end < baseLines.length
        ? toRemote[end]!
        : remoteLines.length;
    flushUnchanged();
    chunks.add(
      _region(
        baseLines.sublist(b, end),
        localLines.sublist(l, localEnd < l ? l : localEnd),
        remoteLines.sublist(r, remoteEnd < r ? r : remoteEnd),
      ),
    );
    b = end;
    l = localEnd < l ? l : localEnd;
    r = remoteEnd < r ? r : remoteEnd;
  }
  // What either side added after the last base line.
  if (l < localLines.length || r < remoteLines.length) {
    flushUnchanged();
    chunks.add(
      _region(const [], localLines.sublist(l), remoteLines.sublist(r)),
    );
  }
  flushUnchanged();

  return MergeResult(
    chunks: chunks,
    lineEnding: local.contains('\r\n') ? '\r\n' : '\n',
    trailingNewline: local.isEmpty || local.endsWith('\n'),
  );
}

/// Where each base line ended up on the other side: its index there, or
/// null when that side changed or removed it.
List<int?> _alignment(int baseCount, List<DiffLine> diff) {
  final out = List<int?>.filled(baseCount, null);
  for (final line in diff) {
    if (line.kind != DiffKind.same) continue;
    final from = line.oldLine;
    final to = line.newLine;
    if (from != null && to != null) out[from - 1] = to - 1;
  }
  return out;
}

/// What one region amounts to.
MergeChunk _region(List<String> base, List<String> local, List<String> remote) {
  final MergeKind kind;
  if (_same(local, remote)) {
    kind = MergeKind.unchanged;
  } else if (_same(local, base)) {
    kind = MergeKind.remote;
  } else if (_same(remote, base)) {
    kind = MergeKind.local;
  } else {
    kind = MergeKind.conflict;
  }
  return MergeChunk(
    kind: kind,
    base: List.unmodifiable(base),
    local: List.unmodifiable(local),
    remote: List.unmodifiable(remote),
  );
}

bool _same(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
