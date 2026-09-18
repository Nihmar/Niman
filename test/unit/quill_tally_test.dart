// #136: counting a list in the WYSIWYG document.
//
// The point of this file is the last group: whatever the two editors do
// internally, a note counted in one has to come out byte for byte like a
// note counted in the other. The count is shared; the finding and the
// writing are not, and this is what keeps them honest.
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/list_tally.dart';
import 'package:niman/src/editor/list_tally_edit.dart';
import 'package:niman/src/editor/wysiwyg/markdown_document_codec.dart';
import 'package:niman/src/editor/wysiwyg/quill_tally.dart';

const MarkdownDocumentCodec _codec = MarkdownDocumentCodec();

/// Counts the first list of [markdown] the way the WYSIWYG would, and
/// returns the Markdown the codec writes back.
String _wysiwyg(String markdown, {TallyCut? cut, TallySort? sort}) {
  final decoded = _codec.decode(markdown);
  final controller = quill.QuillController(
    document: decoded.document,
    selection: const TextSelection.collapsed(offset: 0),
  );
  final targets = quillTallyTargets(controller.document);
  expect(targets, isNotEmpty, reason: 'no list in the document');
  final target = targets.first;
  applyQuillTally(
    controller,
    target,
    tallyList(
      rows: target.rows,
      cut: cut ?? detectTallyCut(target.rows),
      sort: sort ?? TallySort.count,
      checked: target.checks,
    ),
  );
  final out = _codec.encode(controller.document, decoded: decoded);
  controller.dispose();
  return out;
}

/// The same count through the source editor's path.
String _source(String markdown, {TallyCut? cut, TallySort? sort}) {
  final targets = tallyTargetsIn(markdown);
  expect(targets, isNotEmpty, reason: 'no list in the text');
  final target = targets.first;
  return applyTally(
    text: markdown,
    target: target,
    rows: tallyList(
      rows: target.rows,
      cut: cut ?? detectTallyCut(target.rows),
      sort: sort ?? TallySort.count,
      checked: tallyChecksAt(markdown, target),
    ),
  ).text;
}

void main() {
  group('quillTallyTargets', () {
    test('reads a list block without its markers', () {
      final document = _codec.decode('- a - x\n- b - y\n').document;
      final targets = quillTallyTargets(document);
      expect(targets, hasLength(1));
      expect(targets.single.rows, <String>['a - x', 'b - y']);
      expect(targets.single.replaces, isFalse);
    });

    test('a checklist of totals is a block, not a list to count', () {
      final document = _codec.decode('- a - x\n\n- [x] x: 1\n').document;
      final target = quillTallyTargets(document).single;
      expect(target.rows, <String>['a - x']);
      expect(target.replaces, isTrue);
      expect(target.checks, <String, bool>{'x': true});
    });

    test('a plain task list is a list to count', () {
      final document = _codec.decode('- [ ] a - x\n- [x] b - y\n').document;
      final target = quillTallyTargets(document).single;
      expect(target.rows, <String>['a - x', 'b - y']);
      expect(target.replaces, isFalse);
    });

    test('finds every list in the note', () {
      final document = _codec.decode('- a - x\n\nprose\n\n- b - y\n').document;
      final targets = quillTallyTargets(document);
      expect(targets, hasLength(2));
      expect(targets[0].rows, <String>['a - x']);
      expect(targets[1].rows, <String>['b - y']);
    });

    test('the caret picks the list it is in', () {
      final document = _codec.decode('- a - x\n\n- b - y\n').document;
      final first = quillTallyTargets(document)[0];
      final second = quillTallyTargets(document)[1];
      expect(quillTallyTargetAt(document, first.start)?.rows, first.rows);
      expect(quillTallyTargetAt(document, second.start)?.rows, second.rows);
    });

    test('a note with no list has nothing to offer', () {
      expect(quillTallyTargets(_codec.decode('prose\n').document), isEmpty);
    });

    test('a note the codec keeps opaque offers nothing', () {
      // Text on the line under a list item is a lazy continuation of it,
      // so the parser counts one block where the preview's locator
      // counts two; the codec keeps the whole note verbatim rather than
      // risk a mis-slice, and the WYSIWYG shows it read-only. There is
      // no list to count because there is nothing to edit — which is
      // also the one shape where the two editors cannot agree, and they
      // do not pretend to.
      expect(
        quillTallyTargets(_codec.decode('- a - x\nprose\n').document),
        isEmpty,
      );
      expect(tallyTargetsIn('- a - x\nprose\n'), hasLength(1));
    });
  });

  group('applyQuillTally', () {
    test('writes the block under a list that ends the note', () {
      expect(
        _wysiwyg('- a - brioche\n- b - brioche, orzo\n'),
        '- a - brioche\n- b - brioche, orzo\n\n'
        '- [ ] brioche: 2\n- [ ] orzo: 1\n',
      );
    });

    test('writes it in the middle of a note', () {
      expect(
        _wysiwyg('- a - x\n\nprose\n'),
        '- a - x\n\n- [ ] x: 1\n\nprose\n',
      );
    });

    test('a re-run replaces the block and keeps the ticks', () {
      expect(
        _wysiwyg('- a - x\n- b - x\n- c - z\n\n- [x] x: 1\n- [ ] y: 9\n'),
        '- a - x\n- b - x\n- c - z\n\n- [x] x: 2\n- [ ] z: 1\n',
      );
    });

    test('counting twice changes nothing the second time', () {
      const note = '- a - x\n- b - y\n';
      final once = _wysiwyg(note);
      expect(_wysiwyg(once), once);
    });

    test('nothing to write leaves the document alone', () {
      final decoded = _codec.decode('- a - x\n');
      final controller = quill.QuillController(
        document: decoded.document,
        selection: const TextSelection.collapsed(offset: 0),
      );
      applyQuillTally(
        controller,
        quillTallyTargets(controller.document).single,
        const <TallyRow>[],
      );
      expect(_codec.encode(controller.document, decoded: decoded), '- a - x\n');
      controller.dispose();
    });
  });

  group('the two editors agree', () {
    const notes = <String>[
      '- a - brioche\n- b - brioche, orzo\n',
      '- a - x\n\nprose\n',
      '- a - x\n- b - x\n- c - z\n\n- [x] x: 1\n- [ ] y: 9\n',
      '# T\n\n- a - x, y\n- b - y\n\nmore prose\n',
      '- brioche\n- brioche\n- orzo\n',
    ];

    for (final note in notes) {
      test('byte for byte: ${note.replaceAll('\n', r'\n')}', () {
        expect(_wysiwyg(note), _source(note));
      });
    }

    test('and on the note that asked for the feature', () {
      const order =
          '- Alessandro -  acqua naturale, brioche\n'
          '- Alex - coca cola, tramezzino olive\n'
          '- Dara - orzo\n'
          '- Tommaso -succo pesca, brioche\n';
      final counted = _source(order);
      expect(_wysiwyg(order), counted);
      expect(counted, contains('- [ ] brioche: 2'));
    });
  });
}
