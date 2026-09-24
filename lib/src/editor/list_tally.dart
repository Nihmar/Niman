/// Counting the values of a list into a checklist (#136).
///
/// The first outside user writes a group's order one person per line
/// (`Alessandro - acqua naturale, brioche`) and then tallies it by hand
/// into a checklist he ticks off at the bar. This is that count, and
/// nothing else: rows of text in, `- [ ] label: n` rows out.
///
/// Pure Dart, no Flutter and no editor: the editor reads its rows from
/// the list at the caret and hands them here. Every rule about what a
/// value is, how two spellings become one label and how the rows are
/// ordered lives in this file, so the whole of it is unit-testable.
///
/// The generated block is plain Markdown with no marker of its own: it
/// has to stay a portable file, and a tally that cannot be ticked is
/// worth nothing to the person who asked for it. Re-running the count is
/// what answers a stale block, and [parseTallyLine] is how a re-run
/// recognizes its own previous output well enough to carry the ticks
/// over.
library;

import 'package:meta/meta.dart';

/// Where a source row is cut before its values are read.
///
/// The cut drops the part of the row that names the person or the thing
/// the values belong to. It is a fixed set rather than a free-text
/// separator because the sheet shows it as a picker with a preview: four
/// named ways of reading a list are easier to choose between — and to
/// translate — than a text field nobody knows what to type into.
enum TallyCut {
  /// Cut at the first dash that follows whitespace, then split on
  /// commas: `Alessandro -  acqua naturale, brioche`.
  ///
  /// The dash may be glued to what follows it (`Tommaso -succo pesca`
  /// is in the very note that asked for this) and may be a hyphen, an
  /// en dash or an em dash. Whitespace is required *before* it so that
  /// a hyphenated value (`anti-pasto`) is not cut in half.
  dash(r'\s+[-–—]\s*'),

  /// Cut at the first colon, then split on commas: `Alessandro: orzo`.
  colon(r'\s*:\s+'),

  /// No cut: split the whole row on commas.
  commas(null),

  /// No cut and no split: the whole row is one value, which is how a
  /// list of repeated single items is counted.
  whole(null);

  new(this._pattern);

  final String? _pattern;

  /// The cut's separator, or null when the row is not cut.
  RegExp? get separator {
    final pattern = _pattern;
    return pattern == null ? null : RegExp(pattern);
  }

  /// Whether the row is split on commas after the cut.
  bool get splitsOnCommas => this != TallyCut.whole;
}

/// The order the generated rows come out in.
enum TallySort {
  /// Most needed first, ties alphabetically — the order you read a
  /// shopping list in.
  count,

  /// By label, case-insensitively.
  alphabetical,

  /// In the order the values first appear in the source list.
  firstSeen,
}

/// One generated row: a label, how many times it was counted, and
/// whether its box is ticked.
@immutable
final class TallyRow {
  /// Creates a row.
  const new({required this.label, required this.count, this.checked = false});

  /// The value as it was first spelled in the source list.
  final String label;

  /// How many times the value was counted.
  final int count;

  /// Whether the box is ticked.
  final bool checked;

  /// This row with its box set to [checked].
  TallyRow withChecked({required bool checked}) =>
      TallyRow(label: label, count: count, checked: checked);

  @override
  bool operator ==(Object other) =>
      other is TallyRow &&
      other.label == label &&
      other.count == count &&
      other.checked == checked;

  @override
  int get hashCode => Object.hash(label, count, checked);

  @override
  String toString() => 'TallyRow($label, $count, checked: $checked)';
}

/// Runs of whitespace inside a value, collapsed to one space.
final RegExp _innerSpace = RegExp(r'\s+');

/// A generated row: `- [ ] label: 7`, at any indent.
final RegExp _tallyLine = RegExp(r'^\s*-\s+\[([ xX])\]\s+(.*)$');

/// What a generated row says, without its box: `label: 7`.
///
/// The count is anchored to the end and the label is greedy, so a label
/// that itself ends in `something: 3` keeps it.
final RegExp _tallyContent = RegExp(r'^(.+):\s*(\d+)\s*$');

/// The key two spellings of the same value share.
///
/// Case only: `acqua naturale` and `Acqua naturale` are one thing, and
/// nothing cleverer is attempted. Stemming or synonyms would guess at
/// what the writer meant, and a count that quietly merges two values is
/// worse than one that shows both.
String foldTallyLabel(String label) => label.toLowerCase();

/// The values of one source [row] under [cut], in order.
///
/// Empty values are dropped, inner whitespace runs are collapsed, and
/// each value is trimmed — the note that asked for this has both
/// `Alessandro -  acqua naturale` (two spaces) and a trailing-space row.
List<String> tallyValues(String row, TallyCut cut) {
  var rest = row.trim();
  if (rest.isEmpty) return const <String>[];
  final separator = cut.separator;
  if (separator != null) {
    final match = separator.firstMatch(rest);
    // A row the cut does not match keeps all of itself: in a list where
    // most rows name a person, the one row that is only a value still
    // counts as that value.
    if (match != null) rest = rest.substring(match.end);
  }
  final parts = cut.splitsOnCommas ? rest.split(',') : <String>[rest];
  return <String>[
    for (final part in parts)
      if (part.trim().replaceAll(_innerSpace, ' ') case final value
          when value.isNotEmpty)
        value,
  ];
}

/// The cut that reads [rows] best.
///
/// A cut has to earn its place: [TallyCut.dash] and [TallyCut.colon] are
/// only chosen when they match at least half the rows, so one stray dash
/// in a shopping list does not decide how the whole list is read. With
/// neither earning it, a comma anywhere means [TallyCut.commas] and a
/// list without commas is counted whole.
TallyCut detectTallyCut(List<String> rows) {
  final present = <String>[
    for (final row in rows)
      if (row.trim().isNotEmpty) row.trim(),
  ];
  if (present.isEmpty) return TallyCut.whole;
  final half = (present.length + 1) ~/ 2;
  for (final cut in const <TallyCut>[TallyCut.dash, TallyCut.colon]) {
    final separator = cut.separator!;
    final matches = present.where(separator.hasMatch).length;
    if (matches >= half) return cut;
  }
  if (present.any((row) => row.contains(','))) return TallyCut.commas;
  return TallyCut.whole;
}

/// Counts the values of [rows] into checklist rows.
///
/// The [cut] is the caller's to decide — [detectTallyCut] guesses it and
/// the sheet lets the writer say otherwise — because there is no reading
/// of a list that is right often enough to be a default.
///
/// Two spellings of one value are counted together under the first one
/// seen (see [foldTallyLabel]). [checked] carries the ticks of a
/// previous run across, keyed by folded label: a label that survives the
/// re-count keeps its tick, and a label that is gone takes its tick with
/// it.
List<TallyRow> tallyList({
  required List<String> rows,
  required TallyCut cut,
  TallySort sort = TallySort.count,
  Map<String, bool> checked = const <String, bool>{},
}) {
  // Insertion-ordered, which is what TallySort.firstSeen is and what
  // breaks the ties the other two orders leave.
  final labels = <String, String>{};
  final counts = <String, int>{};
  for (final row in rows) {
    for (final value in tallyValues(row, cut)) {
      final key = foldTallyLabel(value);
      labels.putIfAbsent(key, () => value);
      counts[key] = (counts[key] ?? 0) + 1;
    }
  }
  final out = <TallyRow>[
    for (final key in labels.keys)
      TallyRow(
        label: labels[key]!,
        count: counts[key]!,
        checked: checked[key] ?? false,
      ),
  ];
  switch (sort) {
    case TallySort.firstSeen:
      break;
    case TallySort.alphabetical:
      out.sort(
        (a, b) => foldTallyLabel(a.label).compareTo(foldTallyLabel(b.label)),
      );
    case TallySort.count:
      out.sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        if (byCount != 0) return byCount;
        return foldTallyLabel(a.label).compareTo(foldTallyLabel(b.label));
      });
  }
  return out;
}

/// The Markdown line for [row], indented by [indent] spaces.
String tallyLine(TallyRow row, {int indent = 0}) =>
    '${' ' * indent}- [${row.checked ? 'x' : ' '}] ${row.label}: ${row.count}';

/// The row [line] is, or null when it is not one of ours.
///
/// This is the whole of how a re-run finds its previous output: the
/// block carries no marker, so its shape is its identity.
TallyRow? parseTallyLine(String line) {
  final match = _tallyLine.firstMatch(line);
  if (match == null) return null;
  return parseTallyContent(match.group(2)!, checked: match.group(1) != ' ');
}

/// The row a checklist item saying [text] is, or null when it is not one
/// of ours.
///
/// The WYSIWYG's way in: a box there is an attribute of the line rather
/// than characters in it, so the surface knows [checked] already and has
/// only the words to offer.
TallyRow? parseTallyContent(String text, {required bool checked}) {
  final match = _tallyContent.firstMatch(text);
  if (match == null) return null;
  final label = match.group(1)!.trim();
  if (label.isEmpty) return null;
  final count = int.tryParse(match.group(2)!);
  if (count == null) return null;
  return TallyRow(label: label, count: count, checked: checked);
}

/// The ticks of [lines], keyed by folded label, for [tallyList].
///
/// Lines that are not generated rows are ignored, so a block the writer
/// has half rewritten still gives up the ticks it does carry.
Map<String, bool> tallyChecks(Iterable<String> lines) {
  final out = <String, bool>{};
  for (final line in lines) {
    final row = parseTallyLine(line);
    if (row == null) continue;
    out[foldTallyLabel(row.label)] = row.checked;
  }
  return out;
}
