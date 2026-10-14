/// The `+project` / `@context` / `#tag` completion of a task's text: the
/// edit dialog's and the quick-add field's (#712).
library;

import 'package:flutter/widgets.dart';

/// The word under [caret] in [text] when it opens a `+`/`@`/`#` token,
/// with where it starts; null otherwise.
///
/// A lone sigil (e.g. `+`) counts too: right after the dialog's add
/// buttons insert a sigil, the whole pool of that kind shows so an
/// already-used project/context/tag can be tapped without typing, or
/// typing can narrow it.
({String word, int start})? todoTokenWord(String text, int caret) {
  final head = caret < 0 || caret > text.length
      ? text
      : text.substring(0, caret);
  final boundary = head.lastIndexOf(RegExp(r'\s'));
  final word = head.substring(boundary + 1);
  if (word.isEmpty || (word[0] != '+' && word[0] != '@' && word[0] != '#')) {
    return null;
  }
  return (word: word, start: boundary + 1);
}

/// The [known] tokens completing the word under [value]'s caret.
Iterable<String> todoTokenOptions(TextEditingValue value, Set<String> known) {
  final at = todoTokenWord(value.text, value.selection.extentOffset);
  if (at == null) return const Iterable<String>.empty();
  final word = at.word;
  return known.where(
    (token) => token.startsWith(word) && token != word && token[0] == word[0],
  );
}

/// [value] with the word under its caret replaced by [option], the rest of
/// the text untouched; null when the caret is on no token.
TextEditingValue? withTodoTokenOption(TextEditingValue value, String option) {
  final text = value.text;
  final caret = value.selection.extentOffset;
  final at = todoTokenWord(text, caret);
  if (at == null) return null;
  final end = caret < 0 || caret > text.length ? text.length : caret;
  return TextEditingValue(
    text: text.replaceRange(at.start, end, option),
    selection: TextSelection.collapsed(offset: at.start + option.length),
  );
}
