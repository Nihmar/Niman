// A long note's tags and links, kept block by block as it is edited: after
// any run of edits they are the note's as a whole reading finds them, and a
// save reads the blocks the edits changed, not the note.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_styler.dart';

String _shape(NoteReferences references) => [
  'tags ${references.tags.join(' ')}',
  for (final link in references.links)
    switch (link) {
      final WikiLink w => 'wiki ${w.ref.target}',
      final MarkdownLink m => 'md ${m.href}',
    },
].join(' | ');

String _note() {
  final note = StringBuffer();
  for (var at = 0; at < 300; at++) {
    note
      ..writeln('Paragraph $at with #tag$at and [[Note $at]].')
      ..writeln()
      ..writeln('- an item with a [link](l$at.md)')
      ..writeln()
      ..writeln('```')
      ..writeln('#not-a-tag [[not a link]]')
      ..writeln('```')
      ..writeln();
  }
  return note.toString();
}

void main() {
  late SourceBuffer buffer;
  late SourceStyler styler;

  setUp(() async {
    buffer = SourceBuffer.fromText(_note());
    styler = await SourceStyler.inBackground(buffer);
  });

  void edit(int start, int end, String text) =>
      styler.edited(buffer.replaceRange(start, end, text));

  void expectWhole() => expect(
    _shape(styler.references()!),
    _shape(noteReferencesOf(buffer.text)),
  );

  test('a note read in the background keeps them', () {
    expect(styler.references(), isNotNull);
    expectWhole();
    expect(styler.referenceCache.blocksRead, 0, reason: 'read in the isolate');
  });

  test('a note read here does not', () {
    expect(SourceStyler(SourceBuffer.fromText('a #tag')).references(), isNull);
  });

  test('an edit in a block reads that block again, and no other', () {
    final at = buffer.offsetOfLine(8 * 100) + 'Paragraph 100 with'.length;
    edit(at, at, ' #added');
    final references = styler.references()!;
    expect(references.tags, contains('added'));
    expectWhole();
    expect(styler.referenceCache.blocksRead, lessThanOrEqualTo(3));
  });

  test('blocks added, removed and moved along', () {
    // A new paragraph near the top: every block below moves down.
    edit(0, 0, 'New #first with [[Top]].\n\n');
    expectWhole();
    // A whole section taken out further down.
    final from = buffer.offsetOfLine(8 * 50);
    final to = buffer.offsetOfLine(8 * 52);
    edit(from, to, '');
    expectWhole();
    // A block split in two, and two joined into one.
    final split = buffer.offsetOfLine(8 * 10) + 'Paragraph 9 with'.length;
    edit(split, split, '\n\n#split');
    expectWhole();
    final join = buffer.offsetOfLine(8 * 20 + 1);
    edit(join, join + 1, '');
    expectWhole();
  });

  test('a fence opened takes the tags below it out, and back', () {
    final at = buffer.offsetOfLine(8 * 200);
    edit(at, at, '```\n');
    // The scan past the fence may be owed a while: settled, it answers.
    while (!styler.settled) {
      styler.advance();
    }
    expectWhole();
    edit(at, at + 4, '');
    while (!styler.settled) {
      styler.advance();
    }
    expectWhole();
  });

  test('a link definition added reads its reference links again', () {
    final at = buffer.offsetOfLine(8 * 5);
    edit(at, at, 'See [the ref][r].\n\n');
    expect(_shape(styler.references()!), isNot(contains('md defined.md')));
    edit(buffer.length, buffer.length, '\n[r]: defined.md\n');
    expect(_shape(styler.references()!), contains('md defined.md'));
    expectWhole();
  });
}
