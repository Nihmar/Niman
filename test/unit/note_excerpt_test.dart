// Note excerpts (issue 6): titles, prose excerpts and checklist rows.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/widget/note_excerpt.dart';

void main() {
  group('titles', () {
    test('strips the extension', () {
      expect(noteWidgetTitle('Todo.md'), 'Todo');
      expect(noteWidgetTitle('Lists/Packing.md'), 'Packing');
    });
  });

  group('kinds', () {
    test('detects list notes', () {
      expect(isListNoteContent('---\ntype: list\n---\n- [ ] milk\n'), isTrue);
      expect(isListNoteContent('# plain note\n'), isFalse);
      expect(isListNoteContent('---\ntype: audio\n---\n'), isFalse);
    });
  });

  group('prose excerpts', () {
    test('drops the frontmatter and trims', () {
      final excerpt = noteExcerpt(
        '---\ntitle: T\npinned: true\n---\n\nHello\nworld\n',
      );
      expect(excerpt.text, 'Hello\nworld');
      expect(excerpt.truncated, isFalse);
    });

    test('caps long notes with a hint', () {
      final excerpt = noteExcerpt('word ' * 500, maxChars: 20);
      expect(excerpt.text.length, lessThanOrEqualTo(21));
      expect(excerpt.text.endsWith('…'), isTrue);
      expect(excerpt.truncated, isTrue);
    });

    test('an empty note excerpts empty', () {
      final excerpt = noteExcerpt('---\ntype: note\n---\n');
      expect(excerpt.text, isEmpty);
      expect(excerpt.truncated, isFalse);
    });
  });

  group('checklist excerpts', () {
    const content =
        '---\ntype: list\n---\n'
        '- [ ] milk\n'
        '- [x] eggs\n'
        '  - [ ] nested\n'
        '\n'
        'prose is not an item\n';

    test('renders boxes in document order', () {
      final list = checklistExcerpt(content);
      expect(list.text, '☐ milk\n☑ eggs\n  ☐ nested');
      expect(list.truncated, isFalse);
    });

    test('caps the rows with a flag', () {
      final list = checklistExcerpt(content, maxItems: 2);
      expect(list.text, '☐ milk\n☑ eggs');
      expect(list.truncated, isTrue);
    });
  });
}
