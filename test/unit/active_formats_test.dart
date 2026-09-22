// The formats on at the caret, for the toolbar's pressed state (#246): the
// answer is a property of the caret, so it is tested as one — a note, a caret,
// and the buttons that should be lit.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/markdown/active_formats.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_styler.dart';

/// The formats on at [column] of [line] in [note], read through the real
/// styler: the tokens under test are the ones the colours are drawn from, not
/// a fixture's idea of them.
Set<ToolbarItem> _activeAt(String note, int line, int column) {
  final buffer = SourceBuffer.fromText(note);
  final text = buffer.lineAt(line);
  return activeFormatsOf(
    text: text,
    tokens: SourceStyler(buffer).tokensOf(line),
    run: runAround(text, column),
  );
}

void main() {
  test('an inline format is on while the caret is in its own text', () {
    expect(_activeAt('**bold**\n', 0, 3), {ToolbarItem.bold});
    expect(_activeAt('*italic*\n', 0, 2), {ToolbarItem.italic});
    expect(_activeAt('~~strike~~\n', 0, 3), {ToolbarItem.strikethrough});
    expect(_activeAt('`code`\n', 0, 2), {ToolbarItem.code});
    expect(_activeAt('[text](u)\n', 0, 2), {ToolbarItem.link});
    expect(_activeAt('[[wiki]]\n', 0, 3), {ToolbarItem.link});
  });

  test('a format one word over is not on', () {
    // The toolbar says what is on *at the caret*, so the syntax of the next
    // word is dark until the caret is in it.
    expect(_activeAt('a **bold** b\n', 0, 0), isEmpty);
    expect(_activeAt('a [[wiki]] e `code`\n', 0, 0), isEmpty);
    // ...and the caret's own word, markers and all, is what is asked.
    expect(_activeAt('a **bold** b\n', 0, 5), {ToolbarItem.bold});
    expect(_activeAt('a **bold** b\n', 0, 9), {
      ToolbarItem.bold,
    }, reason: 'the closing pair belongs to the word it closes');
    expect(_activeAt('a [[wiki]] e `code`\n', 0, 15), {
      ToolbarItem.code,
    }, reason: 'the second run, not the first');
  });

  test('a phrase reads as one format, not as the word inside it', () {
    // The one place this deliberately differs from the reveal: the reveal shows
    // only the markers of the word being edited, while the toolbar has to say
    // "you are writing in bold" from anywhere inside the phrase.
    expect(_activeAt('**a very long bold phrase**\n', 0, 10), {
      ToolbarItem.bold,
    });
  });

  test('a structural mark follows the line, not the word', () {
    expect(_activeAt('# Titolo\n', 0, 4), {ToolbarItem.heading});
    expect(_activeAt('- item\n', 0, 4), {ToolbarItem.list});
    expect(_activeAt('1. item\n', 0, 4), {ToolbarItem.orderedList});
    expect(_activeAt('> quote\n', 0, 3), {ToolbarItem.quote});
    expect(_activeAt('```\ncode here\n```\n', 1, 2), {ToolbarItem.code});
  });

  test('a quote holding a heading is both', () {
    expect(_activeAt('> # Titolo\n', 0, 6), {
      ToolbarItem.quote,
      ToolbarItem.heading,
    });
  });

  test('what the tokenizer cannot see stays dark', () {
    // An image is an insert action, as it is in the legacy WYSIWYG; a tag and
    // a horizontal rule are not formats the toolbar toggles; `<u>` and `<sup>`
    // have no token of their own, so their buttons stay dark rather than lie.
    expect(_activeAt('![alt](u)\n', 0, 3), isEmpty);
    expect(_activeAt('---\n', 0, 1), isEmpty);
    expect(_activeAt('#tag\n', 0, 2), isEmpty);
    expect(_activeAt('plain text\n', 0, 4), isEmpty);
  });
}
