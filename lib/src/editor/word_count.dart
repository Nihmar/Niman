/// Live note statistics (T-M2-07): words and characters of the buffer.
library;

/// The number of whitespace-separated words in [text].
///
/// A scan of the code units, counting where a run of non-space starts. It
/// is the regex `\S+`'s answer — the same whitespace, JavaScript's `\s` —
/// without a match object per word: on a 246 MB note the regex built 41
/// million of them, and the word count took most of the 12 s its isolate
/// spent after every edit (0.0.9 stress test).
int countWords(String text) {
  var words = 0;
  var inWord = false;
  for (var at = 0; at < text.length; at++) {
    final space = _isSpace(text.codeUnitAt(at));
    if (!space && !inWord) words++;
    inWord = !space;
  }
  return words;
}

/// Whether [unit] is whitespace as a regex's `\s` means it.
bool _isSpace(int unit) {
  if (unit <= 0x20) {
    return unit == 0x20 || (unit >= 0x09 && unit <= 0x0D);
  }
  if (unit < 0xA0) return false;
  return unit == 0xA0 ||
      unit == 0x1680 ||
      (unit >= 0x2000 && unit <= 0x200A) ||
      unit == 0x2028 ||
      unit == 0x2029 ||
      unit == 0x202F ||
      unit == 0x205F ||
      unit == 0x3000 ||
      unit == 0xFEFF;
}

/// The number of characters (UTF-16 code units) in [text].
int countCharacters(String text) => text.length;
