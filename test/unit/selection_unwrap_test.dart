// Bold, Italic and the other wrapping buttons toggle: a selection that is
// wrapped already has the markers taken off, inside or outside it (#1340).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/md_editing.dart';

/// What [left]/[right] make of [marked], where `[` and `]` mark the selection
/// (one `|` instead of the pair is a caret), with the selection marked again.
String _wrap(String marked, String left, String right) {
  String text;
  TextSelection selection;
  if (marked.contains('|')) {
    final at = marked.indexOf('|');
    text = marked.replaceFirst('|', '');
    selection = TextSelection.collapsed(offset: at);
  } else {
    final start = marked.indexOf('«');
    final end = marked.indexOf('»') - 1;
    text = marked.replaceFirst('«', '').replaceFirst('»', '');
    selection = TextSelection(baseOffset: start, extentOffset: end);
  }
  final edit = wrapSelection(
    text: text,
    selection: selection,
    left: left,
    right: right,
  );
  final result = edit.text;
  final sel = edit.selection;
  if (sel.isCollapsed) {
    return result.replaceRange(sel.start, sel.start, '|');
  }
  return result
      .replaceRange(sel.end, sel.end, '»')
      .replaceRange(sel.start, sel.start, '«');
}

String _bold(String marked) => _wrap(marked, '**', '**');
String _italic(String marked) => _wrap(marked, '*', '*');

void main() {
  group('Bold', () {
    test('wraps a selection, and a second press takes it off', () {
      expect(_bold('x «a» y'), 'x **«a»** y');
      expect(_bold('x **«a»** y'), 'x «a» y');
    });

    test('with the markers inside the selection (a double click)', () {
      expect(_bold('x «**a**» y'), 'x «a» y');
    });

    test('over several words, and several lines', () {
      expect(_bold('«**a b**»'), '«a b»');
      expect(_bold('**«a b»**'), '«a b»');
      expect(_bold('**«a\nb»**'), '«a\nb»');
    });

    test('with the caret in a bold word', () {
      expect(_bold('x **a|b** y'), 'x a|b y');
      expect(_bold('x **|ab** y'), 'x |ab y');
      expect(_bold('x **ab|** y'), 'x ab| y');
      expect(_bold('x **ab**| y'), 'x ab| y');
    });

    test('a caret in a plain word inserts the pair, as it did', () {
      expect(_bold('x |a y'), 'x **|**a y');
      expect(_bold('|'), '**|**');
    });

    test('a selection that is not wrapped is wrapped', () {
      expect(_bold('**a** «b» **c**'), '**a** **«b»** **c**');
      expect(_bold('«a»**'), '**«a»****');
    });

    test('over italic, bold wraps; over bold-italic it takes the bold off', () {
      expect(_bold('*«a»*'), '***«a»***');
      expect(_bold('***«a»***'), '*«a»*');
    });
  });

  group('Italic', () {
    test('wraps a selection, and a second press takes it off', () {
      expect(_italic('«a»'), '*«a»*');
      expect(_italic('*«a»*'), '«a»');
    });

    test('is not taken for the bold around the text', () {
      expect(_italic('**«a»**'), '***«a»***');
      expect(_italic('«**a**»'), '*«**a**»*');
    });

    test('over bold-italic it takes the italic off, leaving the bold', () {
      expect(_italic('***«a»***'), '**«a»**');
      expect(_italic('«***a***»'), '«**a**»');
    });

    test('with the caret in an italic word', () {
      expect(_italic('x *a|b* y'), 'x a|b y');
      // In a bold word the caret is not in italic: the pair is inserted.
      expect(_italic('x **a|b** y'), 'x **a*|*b** y');
    });
  });

  group('the other markers', () {
    test('strike, highlight, tags and links toggle too', () {
      expect(_wrap('x «a» y', '~~', '~~'), 'x ~~«a»~~ y');
      expect(_wrap('x ~~«a»~~ y', '~~', '~~'), 'x «a» y');
      expect(_wrap('==«a»==', '==', '=='), '«a»');
      expect(_wrap('<u>«a»</u>', '<u>', '</u>'), '«a»');
      expect(_wrap('«<sup>a</sup>»', '<sup>', '</sup>'), '«a»');
      expect(_wrap('[[«a»]]', '[[', ']]'), '«a»');
      expect(_wrap('[«a»](...)', '[', '](...)'), '«a»');
      expect(_wrap('`«a»`', '`', '`'), '«a»');
    });

    test('a marker of one kind does not unwrap another', () {
      expect(_wrap('~~«a»~~', '==', '=='), '~~==«a»==~~');
      expect(_wrap('<u>«a»</u>', '<sup>', '</sup>'), '<u><sup>«a»</sup></u>');
    });
  });

  test('a CRLF note is read the same', () {
    final edit = wrapSelection(
      text: '**a**\r\nb',
      selection: const TextSelection(baseOffset: 2, extentOffset: 3),
      left: '**',
      right: '**',
    );
    expect(edit.text, 'a\r\nb');
    expect(edit.selection, const TextSelection(baseOffset: 0, extentOffset: 1));
  });
}
