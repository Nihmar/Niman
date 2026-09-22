// A Markdown command run over the lines its selection touches has to be the
// command run over the whole note: same text, same selection, for every
// command the toolbar has, on notes with LF and with CRLF endings. That is
// what lets a bold on a 246 MB note format two asterisks' worth of text
// instead of joining, copying and comparing the note.
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';

typedef _Command = MarkdownEdit Function(String text, TextSelection selection);

final Map<String, _Command> _commands = <String, _Command>{
  'bold': (text, selection) =>
      wrapSelection(text: text, selection: selection, left: '**', right: '**'),
  'link': (text, selection) =>
      wrapSelection(text: text, selection: selection, left: '[[', right: ']]'),
  'code block': (text, selection) =>
      codeBlock(text: text, selection: selection),
  'list': (text, selection) =>
      prefixLines(text: text, selection: selection, prefix: '- '),
  'quote': (text, selection) =>
      prefixLines(text: text, selection: selection, prefix: '> '),
  'heading': (text, selection) =>
      setHeading(text: text, selection: selection, level: 2),
  'heading off': (text, selection) =>
      setHeading(text: text, selection: selection, level: 1),
  'ordered list': (text, selection) =>
      orderedList(text: text, selection: selection),
  'indent': (text, selection) =>
      indentLines(text: text, selection: selection, width: 4, outdent: false),
  'outdent': (text, selection) =>
      indentLines(text: text, selection: selection, width: 2, outdent: true),
};

String _line(Random random) => switch (random.nextInt(9)) {
  0 => '',
  1 => '# Title',
  2 => '   indented words',
  3 => '- item',
  4 => '1. first',
  5 => '> quoted',
  6 => '## sub',
  _ => 'plain words ${random.nextInt(100)}',
};

void main() {
  test('every command over the touched lines is the command over the note', () {
    final random = Random(20260922);
    for (var round = 0; round < 300; round++) {
      final eol = random.nextBool() ? '\n' : '\r\n';
      final text = [
        for (var at = 0; at < 2 + random.nextInt(12); at++) _line(random),
      ].join(eol);
      final probe = SourceBuffer.fromText(text);
      final anchor = random.nextInt(probe.length + 1);
      final extent = random.nextInt(3) == 0
          ? anchor
          : random.nextInt(probe.length + 1);
      for (final MapEntry(key: name, value: command) in _commands.entries) {
        final windowed = MarkdownSurfaceController(SourceBuffer.fromText(text))
          ..select(SelectionModel(anchor: anchor, extent: extent));
        final whole = MarkdownSurfaceController(SourceBuffer.fromText(text))
          ..select(SelectionModel(anchor: anchor, extent: extent));

        windowed.applyLineCommand(command);
        final current = whole.selection;
        final edit = command(
          whole.buffer.text,
          TextSelection(
            baseOffset: current.anchor,
            extentOffset: current.extent,
          ),
        );
        whole.applyEdit(edit.text, edit.selection);

        final reason =
            'round $round, $name on ${text.replaceAll('\r', r'\r')} '
            'at $anchor..$extent';
        expect(windowed.buffer.text, whole.buffer.text, reason: reason);
        expect(windowed.selection, whole.selection, reason: reason);
      }
    }
  });

  test('the command sees the touched lines, not the note', () {
    final lines = [for (var at = 0; at < 1000; at++) 'line $at'];
    final controller = MarkdownSurfaceController(
      SourceBuffer.fromText(lines.join('\n')),
    );
    final start = controller.buffer.offsetOfLine(500);
    controller.select(SelectionModel(anchor: start, extent: start + 4));
    String? seen;
    controller.applyLineCommand((text, selection) {
      seen = text;
      return wrapSelection(
        text: text,
        selection: selection,
        left: '**',
        right: '**',
      );
    });
    expect(seen, 'line 500');
    expect(controller.buffer.lineAt(500), '**line** 500');
  });
}
