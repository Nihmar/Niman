/// Live note statistics (T-M2-07): words and characters of the buffer.
library;

final RegExp _word = RegExp(r'\S+');

/// The number of whitespace-separated words in [text].
int countWords(String text) => _word.allMatches(text).length;

/// The number of characters (UTF-16 code units) in [text].
int countCharacters(String text) => text.length;
