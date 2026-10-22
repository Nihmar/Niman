// T-TK-01/02: the reserved `type` key, kind detection and the registry.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
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
    const on = Features();

    test('list, its shopping subtype and audio are registered', () {
      expect(NoteKinds.forType('list', on), isNotNull);
      expect(NoteKinds.forType('list', on)!.type, 'list');
      expect(NoteKinds.forType('shopping-list', on), isNotNull);
      expect(NoteKinds.forType('shopping-list', on)!.type, 'shopping-list');
      expect(NoteKinds.forType('audio', on), isNotNull);
      expect(NoteKinds.forType('audio', on)!.type, 'audio');
      expect(NoteKinds.forType('note', on), isNull);
      expect(NoteKinds.forType('recipe', on), isNull);
      expect(NoteKinds.forType(null, on), isNull);
    });

    test('every registered kind names the feature it needs (#1109)', () {
      expect(NoteKinds.types, [
        'list',
        'shopping-list',
        'audio',
        'slides',
        'flashcard',
        'kanban',
      ]);
      expect(featureOfKind('list'), LibraryFeature.kindList);
      expect(featureOfKind('shopping-list'), LibraryFeature.kindShopping);
      expect(featureOfKind('audio'), LibraryFeature.kindAudio);
      expect(featureOfKind('slides'), LibraryFeature.kindSlides);
      expect(featureOfKind('flashcard'), LibraryFeature.kindFlashcards);
      expect(featureOfKind('kanban'), LibraryFeature.kindKanban);
      expect(featureOfKind('recipe'), isNull);
      expect(featureOfKind(null), isNull);
      for (final type in NoteKinds.types) {
        expect(featureOfKind(type), isNotNull, reason: type);
      }
    });

    test('a kind that is off answers no GUI: the note is plain (#1109)', () {
      for (final type in NoteKinds.types) {
        final feature = featureOfKind(type)!;
        final off = on.withSwitch(feature, on: false);
        expect(NoteKinds.forType(type, off), isNull, reason: type);
        // The others stay as they were.
        for (final other in NoteKinds.types.where((t) => t != type)) {
          final otherFeature = featureOfKind(other)!;
          // Shopping lists go with their parent.
          if (feature == otherFeature.parent) continue;
          expect(NoteKinds.forType(other, off), isNotNull, reason: other);
        }
        // Turning it back on is the whole undo.
        expect(
          NoteKinds.forType(type, off.withSwitch(feature, on: true)),
          isNotNull,
          reason: type,
        );
      }
    });

    test('shopping lists go with Lists, and keep their own switch', () {
      final listsOff = on.withSwitch(LibraryFeature.kindList, on: false);
      expect(NoteKinds.forType('list', listsOff), isNull);
      expect(NoteKinds.forType('shopping-list', listsOff), isNull);
      // Lists on, shopping off: the list still opens as a list.
      final shoppingOff = on.withSwitch(LibraryFeature.kindShopping, on: false);
      expect(NoteKinds.forType('list', shoppingOff), isNotNull);
      expect(NoteKinds.forType('shopping-list', shoppingOff), isNull);
      // Its own value survives a parent that is off.
      expect(listsOff.own(LibraryFeature.kindShopping), isTrue);
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
