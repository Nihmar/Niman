/// Finding a match in a note on disk and cutting the lines around it — what
/// a search result shows under its path.
///
/// The index keeps no copy of the notes' text (only its word index), so a
/// result's excerpt is read from the note itself. A note is read a slice at
/// a time and no further than its first match: the 247 MB stress note whose
/// match is on its first page costs a page, and nothing is ever held whole.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

/// How many characters of context an excerpt keeps on each side of its
/// match.
const int excerptRadius = 40;

/// Where a match is in a piece of text.
typedef ExcerptMatch = ({int start, int end});

/// Finds the first match in folded text; see [foldForSearch].
typedef ExcerptFinder = ExcerptMatch? Function(String folded);

/// A finder for [pattern] anywhere, letters folded — the "contains" search.
ExcerptFinder containsFinder(String pattern) {
  final wanted = foldForSearch(pattern);
  return (folded) {
    if (wanted.isEmpty) return null;
    final at = folded.indexOf(wanted);
    return at < 0 ? null : (start: at, end: at + wanted.length);
  };
}

/// A finder for the first word that starts with one of [terms], letters
/// folded — the word search, whose index matches a term at the start of a
/// word ([wordTermsOf]).
ExcerptFinder wordFinder(List<String> terms) {
  final wanted = [
    for (final term in terms)
      if (foldForSearch(term) case final folded when folded.isNotEmpty) folded,
  ];
  return (folded) {
    ExcerptMatch? best;
    for (final term in wanted) {
      var from = 0;
      while (true) {
        final at = folded.indexOf(term, from);
        if (at < 0) break;
        if (best != null && at >= best.start) break;
        if (at == 0 || !_isWordChar(folded.codeUnitAt(at - 1))) {
          var end = at + term.length;
          while (end < folded.length && _isWordChar(folded.codeUnitAt(end))) {
            end++;
          }
          best = (start: at, end: end);
          break;
        }
        from = at + 1;
      }
    }
    return best;
  };
}

/// The terms of a word search typed as [userText]: its words, split where
/// the index's tokenizer splits them (anything that is not a letter or a
/// digit), so `re-read` looks for `re` and `read` as the index does.
List<String> wordTermsOf(String userText) => [
  for (final part in userText.split(_nonWord))
    if (part.isNotEmpty) part,
];

final RegExp _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

bool _isWordChar(int unit) {
  if (unit < 0x80) {
    return (unit >= 0x30 && unit <= 0x39) ||
        (unit >= 0x61 && unit <= 0x7A) ||
        (unit >= 0x41 && unit <= 0x5A);
  }
  // Past ASCII a quote, a dash or an ellipsis is as common as a letter —
  // `“parola”` has to start a word — so the character is asked.
  return _wordChar.hasMatch(String.fromCharCode(unit));
}

final RegExp _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// The excerpt around the first match [find] makes in the note at [path],
/// the match between `<mark>` and `</mark>` and `…` where the cut is not
/// the note's edge; null when there is none, or the note cannot be read.
///
/// Top-level for `Isolate.run`: it carries the path and the finder.
Future<String?> excerptInFile(String path, ExcerptFinder find) async {
  final Stream<String> slices;
  try {
    slices = File(path)
        .openRead()
        .transform(const Utf8Decoder(allowMalformed: true));
  } on FileSystemException {
    return null;
  }
  // What was read and not yet searched past: the slice, and before it
  // enough of the last one that a match — and its context — can straddle
  // the cut.
  final pending = StringBuffer();
  // Whether the window still begins where the note does.
  var atStart = true;
  try {
    await for (final slice in slices) {
      pending.write(slice);
      final window = pending.toString();
      final match = find(foldForSearch(window));
      if (match != null) {
        // The context after the match may still be to come: take what is
        // there, which is at worst a shorter excerpt at a slice's end.
        return _cut(window, match, atStart: atStart);
      }
      // Keep a tail long enough for a match and its context before it.
      const keep = excerptRadius * 4;
      if (window.length > keep) {
        pending
          ..clear()
          ..write(window.substring(window.length - keep));
        atStart = false;
      }
    }
  } on FileSystemException {
    return null;
  }
  return null;
}

String _cut(String text, ExcerptMatch match, {required bool atStart}) {
  var start = match.start - excerptRadius;
  var end = match.end + excerptRadius;
  if (start < 0) start = 0;
  if (end > text.length) end = text.length;
  final before = start > 0 || !atStart ? '…' : '';
  final after = end < text.length ? '…' : '';
  String flat(String s) => s.replaceAll(RegExp(r'\s+'), ' ');
  return '$before${flat(text.substring(start, match.start))}'
      '<mark>${flat(text.substring(match.start, match.end))}</mark>'
      '${flat(text.substring(match.end, end))}$after';
}

/// [text] lowercased with the accents of Latin letters taken off, one
/// character for one, so an offset in the folded text is the same offset
/// in [text]: what makes `perché` match `perche`, as the index's tokenizer
/// (`remove_diacritics 2`) matches them.
String foldForSearch(String text) {
  final units = List<int>.filled(text.length, 0);
  for (var i = 0; i < text.length; i++) {
    units[i] = _fold(text.codeUnitAt(i));
  }
  return String.fromCharCodes(units);
}

int _fold(int unit) {
  if (unit < 0x80) {
    return unit >= 0x41 && unit <= 0x5A ? unit + 0x20 : unit;
  }
  if (unit >= 0xC0 && unit <= 0x17F) {
    final base = latinBase.codeUnitAt(unit - 0xC0);
    // A space in the table: no plain letter underneath (×, ÷, æ …).
    return base == 0x20 ? _lower(unit) : base;
  }
  return _lower(unit);
}

int _lower(int unit) => String.fromCharCode(unit).toLowerCase().codeUnitAt(0);

/// The plain lowercase letter under each character from U+00C0 to U+017F,
/// or a space where there is none (a ligature, a sign, a letter of its
/// own).
@visibleForTesting
final String latinBase = const [
  // C0–DF: À–Å, Æ, Ç, È–Ë, Ì–Ï, Ð, Ñ, Ò–Ö, ×, Ø, Ù–Ü, Ý, Þ, ß
  'aaaaaa ceeeeiiii nooooo ouuuuy  ',
  // E0–FF: the same in lowercase, ÷ for ×, and ÿ
  'aaaaaa ceeeeiiii nooooo ouuuuy y',
  // 100–17F, Latin Extended-A: Ā–ą, Ć–č, Ď–đ, Ē–ě, Ĝ–ģ, Ĥ–ħ, Ĩ–ı, Ĳĳ, Ĵĵ,
  // Ķ–ĸ, Ĺ–ł, Ń–ŉ, Ŋŋ, Ō–ő, Œœ, Ŕ–ř, Ś–š, Ţ–ŧ, Ũ–ų, Ŵŵ, Ŷ–Ÿ, Ź–ž, ſ
  'aaaaaaccccccccddddeeeeeeeeeegggggggghhhhiiiiiiiiii  jjkkk',
  'llllllllllnnnnnnn  oooooo  rrrrrrssssssssttttttuuuuuuuuuuuu',
  'wwyyyzzzzzzs',
].join();
