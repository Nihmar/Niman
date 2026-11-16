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

  test('a library outside the shared storage has nothing to name', () {
    expect(androidDocumentOf('/storage/1234-ABCD/Notes'), isNull);
    expect(androidDocumentOf('/storage/emulated/01/Notes'), isNull);
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
