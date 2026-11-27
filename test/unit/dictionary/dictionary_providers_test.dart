// The seams the rest of the app reads the dictionaries through (#1382): the
// catalog, the folder, the one service and the installation.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/dictionary_catalog.dart';
import 'package:niman/src/dictionary/dictionary_pack_info.dart';
import 'package:niman/src/dictionary/dictionary_providers.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('niman_providers'));
  tearDown(() => dir.deleteSync(recursive: true));

  ProviderContainer container({List<DictionaryPackInfo>? catalog}) {
    final result = ProviderContainer(
      overrides: [
        dictionaryDirectoryProvider.overrideWith(
          (ref) async => p.join(dir.path, 'dictionary'),
        ),
        if (catalog != null)
          dictionaryCatalogProvider.overrideWithValue(catalog),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  test('the catalog is the generated one', () {
    expect(container().read(dictionaryCatalogProvider), dictionaryPacks);
  });

  test('the installation offers the catalog it is given', () async {
    const info = DictionaryPackInfo(
      'niman-it',
      languages: ['it'],
      definitions: 'it',
      source: 'it.wiktionary',
      headwords: 1,
      fileName: 'niman-it.tar',
      url: 'http://127.0.0.1:1/niman-it.tar',
      bytes: 10,
      sha256:
          '0000000000000000000000000000000000000000000000000000000000000000',
    );
    final installation = container(catalog: const [info])
        .read(dictionaryInstallationProvider);
    expect(installation.packs.single.id, 'niman-it');
    expect(installation.packs.single.uri.toString(), info.url);
    await installation.load();
    expect(installation.loaded, isTrue);
    expect(installation.installed, isEmpty);
  });

  test('one service serves the app, over the dictionaries folder', () async {
    final root = container();
    final first = await root.read(dictionaryServiceProvider.future);
    final second = await root.read(dictionaryServiceProvider.future);
    expect(identical(first, second), isTrue);
    expect(await first.installedPacks(), isEmpty);
    // The installation reads the same folder the service does.
    final installation = root.read(dictionaryInstallationProvider);
    await installation.load();
    expect(installation.installed, isEmpty);
  });
}
