/// Whether a file is read as plain text with a syntax of its own rather
/// than Markdown, drawn in the source pane with its own colours and nowhere
/// else: the Todo tab's `todo.txt`/`done.txt` and the calendar's
/// `calendar.txt` (#730).
///
/// The preview and the WYSIWYG `live` mode read Markdown, and would run
/// such a file's lines together into paragraphs — so a plain-text file is
/// read in its editor alone, and its eye is offered off.
library;

import 'package:niman/src/calendar/calendar_txt_tokens.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/todo/todo_txt_tokens.dart';

/// Whether the file named [name] is plain text with a syntax of its own.
bool isPlainTextFile(String name) =>
    isTodoTxtFile(name) || isCalendarTxtFile(name);

/// The line colouring [name] gets, or null for the Markdown engine's.
List<Token> Function(String line)? plainTextTokensOf(String name) {
  if (isTodoTxtFile(name)) return todoTxtTokens;
  if (isCalendarTxtFile(name)) return calendarTxtTokens;
  return null;
}
