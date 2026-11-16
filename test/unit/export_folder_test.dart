// Where an export's save dialog opens (#1286): the system's choice, or the
// library's own folder, told to each platform's dialog as it can take it.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/export/export_folder.dart';

void main() {
  const root = '/home/ale/Notes';

  test('the system choice tells no dialog anything', () {
    expect(exportStartFolder(ExportFolder.system, root, desktop: true), isNull);
    expect(exportStartFolder(ExportFolder.system, root, android: true), isNull);
  });

  test("Linux and Windows open in the library's folder", () {
    expect(
      exportStartFolder(
        ExportFolder.library,
        root,
        android: false,
        desktop: true,
      ),
      root,
    );
  });

  test('a Mac and an iPhone leave it to the system', () {
    expect(
      exportStartFolder(
        ExportFolder.library,
        root,
        android: false,
        desktop: false,
      ),
      isNull,
    );
  });

  test("Android names the library's folder as a document of the storage", () {
    expect(
      exportStartFolder(
        ExportFolder.library,
        '/storage/emulated/0/Notes/Work',
        android: true,
      ),
      'content://com.android.externalstorage.documents/document/'
      'primary%3ANotes%2FWork',
    );
    expect(
      androidDocumentOf('/storage/emulated/0'),
      'content://com.android.externalstorage.documents/document/primary%3A',
    );
    expect(
      androidDocumentOf('/storage/emulated/0/Le mie note'),
      endsWith('primary%3ALe%20mie%20note'),
    );
  });

  test('the shared storage is named primary by any of its paths', () {
    const notes =
        'content://com.android.externalstorage.documents/document/'
        'primary%3ANotes';
    expect(androidDocumentOf('/sdcard/Notes'), notes);
    expect(androidDocumentOf('/mnt/sdcard/Notes'), notes);
    expect(androidDocumentOf('/storage/self/primary/Notes'), notes);
    // A second user's, or a work profile's: its own provider's primary.
    expect(androidDocumentOf('/storage/emulated/10/Notes'), notes);
  });

  test('a removable volume is named by its id', () {
    expect(
      androidDocumentOf('/storage/1234-ABCD/Notes/Work'),
      'content://com.android.externalstorage.documents/document/'
      '1234-ABCD%3ANotes%2FWork',
    );
    expect(androidDocumentOf('/storage/1234-ABCD'), endsWith('1234-ABCD%3A'));
  });

  test('a library on no storage the provider names has nothing to name', () {
    expect(androidDocumentOf('/storage/emulated/01/Notes'), isNull);
    expect(androidDocumentOf('/storage/emulated'), isNull);
    expect(androidDocumentOf('/data/user/0/dev.niman.niman/Notes'), isNull);
    expect(androidDocumentOf('/sdcardx/Notes'), isNull);
  });

  test("the choice is the library's, kept in its settings", () {
    final config = LibraryConfig.defaults.copyWith(
      exportFolder: ExportFolder.library,
    );
    expect(config.libraryJsonMap()['exportFolder'], 'library');
    expect(config.deviceJsonMap().containsKey('exportFolder'), isFalse);
    expect(LibraryConfig.fromJsonMap(config.toJsonMap()), config);
    expect(
      LibraryConfig.fromJsonMap(const {'exportFolder': 'desk'}).exportFolder,
      ExportFolder.system,
    );
    expect(LibraryConfig.defaults.exportFolder, ExportFolder.system);
  });
}
