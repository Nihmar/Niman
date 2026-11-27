// What this device has of the dictionaries and how a pack arrives (#1382):
// downloaded from a server of the test's own, checked, unpacked, indexed and
// looked up; and how it goes when any step fails.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/dictionary/dictionary_pack_info.dart';
import 'package:niman/src/dictionary/dictionary_preparation.dart';
import 'package:niman/src/dictionary/dictionary_result.dart';
import 'package:niman/src/dictionary/dictionary_service.dart';
import 'package:path/path.dart' as p;

import '../../../tool/dictionary_pack/pack_archive.dart';
import 'pack_tar.dart';

void main() {
  late Directory dir;
  late Directory root;
  late HttpServer server;
  late DictionaryService service;
  late Uint8List tar;
  // What each path of the server answers with.
  final served = <String, Uint8List>{};
  Completer<void>? hold;
  Completer<void>? reached;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('niman_install');
    root = Directory(p.join(dir.path, 'dictionary'));
    tar = (await fixtureTar(dir)).readAsBytesSync();
    served
      ..clear()
      ..['/niman-it.tar'] = tar;
    hold = null;
    reached = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
      ..listen((request) async {
        final body = served[request.uri.path] ?? Uint8List(0);
        request.response.contentLength = body.length;
        // A response that stalls half way, for a download to cancel.
        if (hold case final hold?
            when request.uri.queryParameters['hold'] == '1') {
          request.response.add(body.sublist(0, body.length ~/ 2));
          await request.response.flush();
          reached?.complete();
          await hold.future;
        }
        try {
          request.response.add(body);
          await request.response.close();
        } on Object {
          // The client went away.
        }
      });
    service = DictionaryService(directory: root.path);
  });

  tearDown(() async {
    hold?.complete();
    await server.close(force: true);
    await service.dispose();
    for (var i = 0; i < 20 && dir.existsSync(); i++) {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  });

  DictionaryPackInfo info({Uint8List? bytes, String query = '', String? sha}) {
    final body = bytes ?? tar;
    return DictionaryPackInfo(
      'niman-it',
      languages: const ['it'],
      definitions: 'it',
      source: 'it.wiktionary',
      headwords: 5,
      fileName: 'niman-it.tar',
      url: 'http://127.0.0.1:${server.port}/niman-it.tar$query',
      bytes: body.length,
      sha256: sha ?? sha256.convert(body).toString(),
    );
  }

  DictionaryInstallation installation(
    List<DictionaryPackInfo> catalog, {
    Future<String?> Function(String, String)? removePack,
  }) {
    final result = DictionaryInstallation(
      directory: () async => root.path,
      service: () async => service,
      catalog: catalog,
      retryDelays: const [],
      removePack: removePack,
    );
    addTearDown(result.dispose);
    return result;
  }

  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 400 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    expect(done(), isTrue, reason: 'timed out');
  }

  List<String> names(Directory folder) => [
    if (folder.existsSync())
      for (final entity in folder.listSync()) p.basename(entity.path),
  ]..sort();

  test('an empty catalog offers nothing, and nothing breaks', () async {
    final dictionaries = installation(const []);
    await dictionaries.load();
    expect(dictionaries.loaded, isTrue);
    expect(dictionaries.packs, isEmpty);
    expect(dictionaries.installed, isEmpty);
    expect(await dictionaries.remove('niman-it'), isNull);
  });

  test('a pack is downloaded, unpacked, indexed and looked up', () async {
    final dictionaries = installation([info()]);
    await dictionaries.load();
    final pack = dictionaries.packs.single;
    expect(dictionaries.stateOf(pack), isA<NotDownloaded>());
    expect(dictionaries.isInstalled('niman-it'), isFalse);

    final steps = <DictionaryPreparationStep>[];
    final downloads = <DownloadState>[];
    dictionaries.addListener(() {
      downloads.add(dictionaries.stateOf(pack));
      final step = dictionaries.preparationOf('niman-it')?.step;
      if (step != null && (steps.isEmpty || steps.last != step)) {
        steps.add(step);
      }
    });
    await dictionaries.download(pack);

    expect(downloads.whereType<Downloading>(), isNotEmpty);
    expect(steps, [
      DictionaryPreparationStep.unpacking,
      DictionaryPreparationStep.indexing,
    ]);
    expect(dictionaries.isInstalled('niman-it'), isTrue);
    expect(dictionaries.stateOf(pack), isA<NotDownloaded>());
    expect(dictionaries.preparationOf('niman-it'), isNull);
    final installed = dictionaries.installed.single;
    expect(installed.pack.isAvailable, isTrue);
    expect(installed.bytes, greaterThan(0));
    // The archive is gone and the folder holds the pack and its index.
    expect(names(root), ['niman-it']);
    expect(
      names(Directory(p.join(root.path, 'niman-it'))),
      containsAll(['niman-it.ifo', 'niman-it.niman-index']),
    );
    final result = await service.lookUp('caminetti', 'it');
    expect(result.outcome, DictionaryOutcome.found);
  });

  test('a download that is not the pinned file installs nothing', () async {
    final wrong = Uint8List.fromList([for (final b in tar) b ^ 1]);
    served['/niman-it.tar'] = wrong;
    final dictionaries = installation([info()]);
    await dictionaries.load();
    final pack = dictionaries.packs.single;
    await dictionaries.download(pack);
    expect(dictionaries.stateOf(pack), isA<DownloadFailed>());
    expect(dictionaries.installed, isEmpty);
    expect(names(root).where((n) => !n.endsWith('.part')), isEmpty);
  });

  test('an archive that downloads whole but will not unpack installs nothing '
      'and is not kept', () async {
    final cut = tar.sublist(0, tar.length - 3000);
    served['/niman-it.tar'] = cut;
    final dictionaries = installation([info(bytes: cut)]);
    await dictionaries.load();
    final pack = dictionaries.packs.single;
    await dictionaries.download(pack);
    expect(dictionaries.stateOf(pack), isA<DownloadFailed>());
    expect(dictionaries.preparationOf('niman-it'), isNull);
    expect(dictionaries.installed, isEmpty);
    // Neither a pack, nor a half-unpacked one, nor the archive.
    expect(names(root), isEmpty);
    // A later ask downloads it again.
    served['/niman-it.tar'] = tar;
    final again = installation([info()]);
    await again.load();
    await again.download(again.packs.single);
    expect(again.isInstalled('niman-it'), isTrue);
  });

  test('an archive left whole by an earlier run is unpacked at load', () async {
    root.createSync(recursive: true);
    File(p.join(root.path, 'niman-it.tar')).writeAsBytesSync(tar);
    // And what an interrupted unpacking left beside it.
    Directory(p.join(root.path, '.niman-it.unpacking')).createSync();
    final dictionaries = installation([info()]);
    await dictionaries.load();
    await until(() => dictionaries.isInstalled('niman-it'));
    await until(() => dictionaries.preparationOf('niman-it') == null);
    expect(names(root), ['niman-it']);
  });

  test('a download cut off by the app closing shows as resumable', () async {
    root.createSync(recursive: true);
    File(p.join(root.path, 'niman-it.tar.part')).writeAsBytesSync([1, 2, 3]);
    final dictionaries = installation([info()]);
    await dictionaries.load();
    expect(
      dictionaries.stateOf(dictionaries.packs.single),
      isA<DownloadFailed>().having((s) => s.resumable, 'resumable', isTrue),
    );
  });

  test('a download can be cancelled, and leaves nothing', () async {
    hold = Completer<void>();
    reached = Completer<void>();
    final dictionaries = installation([info(query: '?hold=1')]);
    await dictionaries.load();
    final pack = dictionaries.packs.single;
    final running = dictionaries.download(pack);
    // The server has sent half the file and waits: the download is under way.
    await reached!.future;
    expect(dictionaries.stateOf(pack), isA<Downloading>());
    await dictionaries.cancel(pack);
    await running;
    expect(dictionaries.stateOf(pack), isA<NotDownloaded>());
    expect(dictionaries.installed, isEmpty);
    expect(names(root).where((n) => n.endsWith('.part')), isEmpty);
  });

  group('removal', () {
    Future<DictionaryInstallation> installed({
      Future<String?> Function(String, String)? removePack,
    }) async {
      final dictionaries = installation([info()], removePack: removePack);
      await dictionaries.load();
      await dictionaries.download(dictionaries.packs.single);
      expect(dictionaries.isInstalled('niman-it'), isTrue);
      return dictionaries;
    }

    test('closes the pack, deletes its folder and says it is gone', () async {
      final dictionaries = await installed();
      // Opened by a look-up, as it will be when a panel is open.
      expect((await service.lookUp('acqua', 'it')).isFound, isTrue);
      expect(await dictionaries.remove('niman-it'), isNull);
      expect(dictionaries.installed, isEmpty);
      expect(names(root), isEmpty);
      expect(
        (await service.lookUp('acqua', 'it')).outcome,
        DictionaryOutcome.noPack,
      );
      // It can be downloaded again.
      await dictionaries.download(dictionaries.packs.single);
      expect(dictionaries.isInstalled('niman-it'), isTrue);
    });

    test('a delete that fails is reported, not thrown, and the pack stays '
        'whole', () async {
      final closed = <String>[];
      final dictionaries = await installed(
        removePack: (root, id) async {
          closed.add(id);
          return 'Access is denied.';
        },
      );
      expect(await dictionaries.remove('niman-it'), 'Access is denied.');
      expect(closed, ['niman-it']);
      expect(dictionaries.isInstalled('niman-it'), isTrue);
      expect((await service.lookUp('acqua', 'it')).isFound, isTrue);
    });

    test('a failure of the folder itself is reported too', () async {
      final dictionaries = await installed(
        removePack: (root, id) async => throw const FileSystemException('x'),
      );
      expect(await dictionaries.remove('niman-it'), isNotNull);
      expect(dictionaries.isInstalled('niman-it'), isTrue);
    });
  });

  group('a pack whose index cannot be built', () {
    late Uint8List brokenTar;
    late List<int> goodIdx;

    setUp(() {
      // The fixture pack with its .idx cut inside the last record: it
      // unpacks, and cannot be indexed.
      final source = Directory(p.join(dir.path, 'source', 'niman-it'));
      final copy = Directory(p.join(dir.path, 'broken', 'niman-it'))
        ..createSync(recursive: true);
      for (final file in source.listSync().whereType<File>()) {
        file.copySync(p.join(copy.path, p.basename(file.path)));
      }
      final idx = File(p.join(copy.path, 'niman-it.idx'));
      goodIdx = idx.readAsBytesSync();
      idx.writeAsBytesSync(goodIdx.sublist(0, goodIdx.length - 3));
      final tarFile = File(p.join(dir.path, 'broken', 'niman-it.tar'));
      writePackTar(copy, 'niman-it', tarFile);
      brokenTar = tarFile.readAsBytesSync();
      served['/niman-it.tar'] = brokenTar;
    });

    test('is installed, says why it cannot be used, and tries again when '
        'asked', () async {
      final dictionaries = installation([info(bytes: brokenTar)]);
      await dictionaries.load();
      await dictionaries.download(dictionaries.packs.single);
      // On the device, with the reason, and not on its way any more.
      expect(dictionaries.isInstalled('niman-it'), isTrue);
      expect(dictionaries.preparationOf('niman-it'), isNull);
      expect(
        dictionaries.indexFailureOf('niman-it'),
        contains('ends inside a record'),
      );
      expect(dictionaries.installed.single.indexed, isFalse);

      // A retry that fails again says so again.
      await dictionaries.retryIndex('niman-it');
      expect(dictionaries.indexFailureOf('niman-it'), isNotNull);

      // Mended, it is built, and the failure is gone.
      File(p.join(root.path, 'niman-it', 'niman-it.idx'))
          .writeAsBytesSync(goodIdx);
      await dictionaries.retryIndex('niman-it');
      expect(dictionaries.indexFailureOf('niman-it'), isNull);
      expect(dictionaries.installed.single.indexed, isTrue);
      expect((await service.lookUp('caminetto', 'it')).isFound, isTrue);
    });

    test(
      'is found again at the next start, not by the first look-up',
      () async {
        final first = installation([info(bytes: brokenTar)]);
        await first.load();
        await first.download(first.packs.single);
        final restarted = installation([info(bytes: brokenTar)]);
        await restarted.load();
        await until(() => restarted.indexFailureOf('niman-it') != null);
        expect(restarted.preparationOf('niman-it'), isNull);
      },
    );

    test('a failure goes with the pack when it is removed', () async {
      final dictionaries = installation([info(bytes: brokenTar)]);
      await dictionaries.load();
      await dictionaries.download(dictionaries.packs.single);
      expect(await dictionaries.remove('niman-it'), isNull);
      expect(dictionaries.indexFailureOf('niman-it'), isNull);
      expect(dictionaries.installed, isEmpty);
    });
  });

  test('a pack the catalog does not know is listed all the same', () async {
    root.createSync(recursive: true);
    final dictionaries = installation([info()]);
    await dictionaries.load();
    await dictionaries.download(dictionaries.packs.single);
    final empty = installation(const []);
    await empty.load();
    expect(empty.installed.single.pack.id, 'niman-it');
    expect(empty.packOf('niman-it'), isNull);
    expect(await empty.remove('niman-it'), isNull);
    expect(empty.installed, isEmpty);
  });
}
