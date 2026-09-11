// T-TK-01/02: the reserved `type` key, kind detection and the registry.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/frontmatter/parser.dart';

void main() {
  group('frontmatterTypeOf', () {
    test('detects type: list in a closed block', () {
      expect(frontmatterTypeOf('---\ntype: list\n---\n- [ ] a\n'), 'list');
      // Quotes are stripped, like every other frontmatter value.
      expect(frontmatterTypeOf('---\ntype: "list"\n---\n'), 'list');
    });

    test('no block, no key, unclosed block: null', () {
      expect(frontmatterTypeOf('just text\n'), isNull);
      expect(frontmatterTypeOf('---\ntitle: x\n---\n'), isNull);
      // A block that never closes is not frontmatter.
      expect(frontmatterTypeOf('---\ntype: list\n'), isNull);
    });

    test('a type after the closed block does not count', () {
      expect(frontmatterTypeOf('---\ntitle: x\n---\ntype: list\n'), isNull);
    });

    test('body text is never scanned', () {
      expect(frontmatterTypeOf('```\ntype: list\n```\n'), isNull);
    });
  });

  group('NoteKinds', () {
    test('list is registered; unknown or absent kinds are plain notes', () {
      expect(NoteKinds.forType('list'), isNotNull);
      expect(NoteKinds.forType('list')!.type, 'list');
      expect(NoteKinds.forType('note'), isNull);
      expect(NoteKinds.forType('recipe'), isNull);
      expect(NoteKinds.forType(null), isNull);
    });
  });

  group('parseFrontmatter', () {
    test('reads the type key alongside the other fields', () {
      final fm = parseFrontmatter('---\ntype: list\ntitle: Spesa\n---\n');
      expect(fm?.type, 'list');
      expect(fm?.title, 'Spesa');
      expect(parseFrontmatter('---\n---\n')?.type, isNull);
    });
  });
}
