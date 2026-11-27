import 'package:niman/src/dictionary/nfc_pairs.dart';

/// Canonical composition (NFC) of the scripts the dictionaries are in.
///
/// Dart and Flutter ship no normalization, and the packages that do are a
/// dependency this feature does not take: a PDF or a macOS clipboard hands
/// *città* as `citta` and a combining grave, and no pack holds that spelling.
/// This composes a letter and its combining mark into the precomposed letter
/// where Unicode has one, for Latin, Greek and Cyrillic (Vietnamese and
/// polytonic Greek included), putting several marks on one letter in
/// canonical order first. Other scripts (Hangul, Indic marks) are left as
/// they are.
final class UnicodeNfc {
  const new _();

  /// `(base << 16) | mark` to the composed letter, read from the table on
  /// first use.
  static final Map<int, int> _compositions = () {
    final table = <int, int>{};
    for (var i = 0; i + 12 <= nfcPairs.length; i += 12) {
      final base = int.parse(nfcPairs.substring(i, i + 4), radix: 16);
      final mark = int.parse(nfcPairs.substring(i + 4, i + 8), radix: 16);
      table[(base << 16) | mark] = int.parse(
        nfcPairs.substring(i + 8, i + 12),
        radix: 16,
      );
    }
    return table;
  }();

  /// Whether [unit] is a combining mark the table composes.
  static bool _isMark(int unit) => unit >= 0x0300 && unit <= 0x036F;

  /// The canonical combining class of the mark [mark]: what orders several
  /// marks on one letter (a mark below comes before one above).
  static int _combiningClass(int mark) {
    if (mark == 0x034F) return 0;
    if (mark >= 0x0334 && mark <= 0x0338) return 1;
    if (mark == 0x0321 || mark == 0x0322 || mark == 0x0327 || mark == 0x0328) {
      return 202;
    }
    if (mark == 0x031B) return 216;
    if (mark == 0x0345) return 240;
    if (mark == 0x0315 || mark == 0x031A || mark == 0x0358) return 232;
    if (mark == 0x035C || mark == 0x035F || mark == 0x0362) return 233;
    if (mark == 0x035D || mark == 0x035E || mark == 0x0360 || mark == 0x0361) {
      return 234;
    }
    final below =
        (mark >= 0x0316 && mark <= 0x0319) ||
        (mark >= 0x031C && mark <= 0x0320) ||
        (mark >= 0x0323 && mark <= 0x0326) ||
        (mark >= 0x0329 && mark <= 0x0333) ||
        (mark >= 0x0339 && mark <= 0x033C) ||
        (mark >= 0x0347 && mark <= 0x0349) ||
        mark == 0x034D ||
        mark == 0x034E ||
        (mark >= 0x0353 && mark <= 0x0356) ||
        mark == 0x0359 ||
        mark == 0x035A;
    return below ? 220 : 230;
  }

  /// [text] in NFC.
  static String compose(String text) {
    if (!text.codeUnits.any(_isMark)) return text;
    final runes = text.runes.toList();
    final out = <int>[];
    var i = 0;
    while (i < runes.length) {
      final starter = runes[i++];
      if (_isMark(starter)) {
        out.add(starter);
        continue;
      }
      var base = starter;
      final marks = <int>[];
      while (i < runes.length && _isMark(runes[i])) {
        marks.add(runes[i++]);
      }
      // Canonical order first: a letter with a mark below and one above
      // composes the same whichever the text lists first.
      // An insertion sort: stable, and a run of marks is two or three long.
      for (var m = 1; m < marks.length; m++) {
        final mark = marks[m];
        var at = m;
        while (at > 0 &&
            _combiningClass(marks[at - 1]) > _combiningClass(mark)) {
          marks[at] = marks[at - 1];
          at--;
        }
        marks[at] = mark;
      }
      var keptClass = 0;
      final kept = <int>[];
      for (final mark in marks) {
        final markClass = _combiningClass(mark);
        final composed = keptClass < markClass || keptClass == 0
            ? _compositions[(base << 16) | mark]
            : null;
        if (composed != null) {
          base = composed;
        } else {
          kept.add(mark);
          keptClass = markClass;
        }
      }
      out
        ..add(base)
        ..addAll(kept);
    }
    return String.fromCharCodes(out);
  }
}
