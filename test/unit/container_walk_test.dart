// A line walked through the containers open around it, as
// `package:markdown` — the read view's parser — hands each its lines.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/container_walk.dart';
import 'package:niman/src/markdown/line_state.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The last line of [text] walked in the state the scan enters it in.
ContainerWalk _walk(String text) {
  final buffer = SourceBuffer.fromText(text);
  final last = buffer.lineCount - 1;
  final state = BlockScanner(buffer).stateEntering(last);
  return ContainerWalk.of(state, buffer.lineAt(last), null);
}

void main() {
  group('an item', () {
    test('takes a line at its indent, its indent off', () {
      final walk = _walk('- a\n    b');
      expect(walk.items, hasLength(1));
      expect(walk.text, '  b');
      expect(walk.lazy, isFalse);
    });

    test('takes a line short of it lazily, as it stands', () {
      final walk = _walk('- a\nb');
      expect(walk.items, hasLength(1));
      expect(walk.text, 'b');
      expect(walk.lazy, isTrue);
    });

    test('hands a lazy line on as it stands, for the items inside it', () {
      // `  1. w` takes lines five in, `      - w` three past that. `    * w`
      // is short of the first — lazy, kept as it is — and reaches the
      // second, which takes its three spaces off: a sublist of the sublist.
      final walk = _walk('  1. w\n      - w\n    * w');
      expect(walk.items, hasLength(2));
      expect(walk.text, ' * w');
    });

    test('ends at a rule, a marker or a block that interrupts', () {
      for (final line in ['---', '- b', '# h', '> q', '```']) {
        final walk = _walk('- a\n$line');
        expect(walk.closed, isTrue, reason: line);
        expect(walk.items, isEmpty, reason: line);
      }
    });

    test('ends at text after a blank line', () {
      expect(_walk('- a\n\nb').closed, isTrue);
      expect(_walk('- a\n\n  b').closed, isFalse);
    });

    test('with no text on its marker, takes one blank line at most', () {
      expect(_walk('-\n  a').closed, isFalse);
      expect(_walk('-\n\n\n  a').closed, isTrue);
    });
  });

  group('a quote', () {
    test('takes a line by its `>`, the marker off', () {
      expect(_walk('> a\n> b').quote, 'b');
    });

    test('takes paragraph text lazily, but not after a fence', () {
      expect(_walk('> a\nb').quote, 'b');
      expect(_walk('> ```\nb').quote, isNull);
    });

    test('takes indented lines lazily while its paragraph is open', () {
      // `cmark` reads every one of them as the paragraph's; the package
      // left at the second.
      expect(_walk('> a\n    b').quote, '    b');
      expect(_walk('> a\n    b\n    c').quote, '    c');
      // After a blank line, or a heading, no paragraph is open.
      expect(_walk('> a\n>\n    b').quote, isNull);
      expect(_walk('> # h\nb').quote, isNull);
    });

    test('in an item, reads the line the item leaves', () {
      // `    > b` is four spaces from the margin, two past the item: the
      // quote in it.
      expect(_walk('- a\n  > q\n    > b').quote, 'b');
    });
  });

  test('the bits a quote line leaves', () {
    expect(ContainerWalk.lastOf(''), LineState.lastBlank);
    expect(ContainerWalk.lastOf('```'), LineState.lastFence);
    expect(ContainerWalk.lastOf('    code'), LineState.lastIndented);
    expect(ContainerWalk.lastOf('text'), 0);
    // Four columns in under an open paragraph are the paragraph's.
    expect(ContainerWalk.lastOf('    more', 0), 0);
    expect(ContainerWalk.lastOf('# h'), LineState.lastClosed);
    expect(ContainerWalk.lastOf('---'), LineState.lastClosed);
  });
}
