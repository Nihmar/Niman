// Unit tests for resolveLibraryRoot.

import 'package:copist/src/core/library_root.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveLibraryRoot', () {
    test('passes real paths through unchanged', () {
      expect(
        resolveLibraryRoot('/storage/emulated/0/Vaults/notes'),
        '/storage/emulated/0/Vaults/notes',
      );
      expect(
        resolveLibraryRoot('/home/alessandro/notes'),
        '/home/alessandro/notes',
      );
    });

    test('maps a primary-volume tree URI to the FUSE path', () {
      expect(
        resolveLibraryRoot(
          'content://com.android.externalstorage.documents/'
          'tree/primary%3ADocuments%2FHelixNotes',
        ),
        '/storage/emulated/0/Documents/HelixNotes',
      );
    });

    test('maps a tree URI for the storage root', () {
      expect(
        resolveLibraryRoot(
          'content://com.android.externalstorage.documents/tree/primary:',
        ),
        '/storage/emulated/0',
      );
    });

    test('maps other volumes under /storage/<volume>', () {
      expect(
        resolveLibraryRoot(
          'content://com.android.externalstorage.documents/'
          'tree/external%3AFoo',
        ),
        '/storage/external/Foo',
      );
    });

    test('accepts the single-slash content form', () {
      expect(
        resolveLibraryRoot(
          'content/com.android.externalstorage.documents/'
          'tree/primary%3ADocuments%2FHelixNotes',
        ),
        '/storage/emulated/0/Documents/HelixNotes',
      );
    });

    test('returns null for empty picks', () {
      expect(resolveLibraryRoot(null), isNull);
      expect(resolveLibraryRoot(''), isNull);
      expect(resolveLibraryRoot('   '), isNull);
    });

    test('returns null for URIs that are not external-storage trees', () {
      expect(
        resolveLibraryRoot(
          'content://com.android.providers.downloads.documents/'
          'tree/primary:Downloads',
        ),
        isNull,
      );
      expect(
        resolveLibraryRoot(
          'content://com.android.externalstorage.documents/'
          'document/primary%3ADocuments%2Fnote.md',
        ),
        isNull,
      );
    });
  });
}
