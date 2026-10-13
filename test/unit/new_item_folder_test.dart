import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/new_item_folder.dart';

void main() {
  group('resolveNewItemFolder (issue #850)', () {
    test('the library root setting always answers the root', () {
      expect(resolveNewItemFolder(NewItemLocation.libraryRoot), '');
      expect(
        resolveNewItemFolder(
          NewItemLocation.libraryRoot,
          activeNote: 'Projects/Niman/Plan.md',
        ),
        '',
      );
    });

    test('the open note setting answers the open note\'s folder', () {
      expect(
        resolveNewItemFolder(
          NewItemLocation.openNoteFolder,
          activeNote: 'Projects/Plan.md',
        ),
        'Projects',
      );
    });

    test('a nested folder is answered whole', () {
      expect(
        resolveNewItemFolder(
          NewItemLocation.openNoteFolder,
          activeNote: 'Projects/Niman/Specs/Plan.md',
        ),
        'Projects/Niman/Specs',
      );
    });

    test('a note at the root answers the root', () {
      expect(
        resolveNewItemFolder(
          NewItemLocation.openNoteFolder,
          activeNote: 'Plan.md',
        ),
        '',
      );
    });

    test('with no note open the open note setting answers the root', () {
      expect(resolveNewItemFolder(NewItemLocation.openNoteFolder), '');
      expect(
        resolveNewItemFolder(NewItemLocation.openNoteFolder, activeNote: ''),
        '',
      );
    });
  });

  group('stored ids', () {
    test('a stored id reads back as its location', () {
      expect(newItemLocationFromId('libraryRoot'), NewItemLocation.libraryRoot);
      expect(
        newItemLocationFromId('openNoteFolder'),
        NewItemLocation.openNoteFolder,
      );
      expect(newItemLocationFromId('nonsense'), isNull);
      expect(newItemLocationFromId(null), isNull);
    });

    test('the old dead-link ids map onto the new locations', () {
      expect(
        newItemLocationFromLegacy('libraryRoot'),
        NewItemLocation.libraryRoot,
      );
      expect(
        newItemLocationFromLegacy('currentFolder'),
        NewItemLocation.openNoteFolder,
      );
      expect(newItemLocationFromLegacy(null), NewItemLocation.openNoteFolder);
    });
  });
}
