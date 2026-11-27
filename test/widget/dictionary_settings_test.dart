// Settings → Dictionaries (#1382): the packs on the device, a download on its
// way, the catalog with its search, and the notes under them.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/download/downloader.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/dictionary/dictionary_pack_info.dart';
import 'package:niman/src/dictionary/dictionary_preparation.dart';
import 'package:niman/src/dictionary/dictionary_providers.dart';
import 'package:niman/src/dictionary/dictionary_service.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_search.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';
import '../unit/dictionary/fixture_packs.dart';
import '../unit/dictionary/pack_writer.dart';

const int _mb = 1024 * 1024;

DictionaryPackInfo _info(
  String code, {
  List<String>? languages,
  String definitions = 'en',
  int megabytes = 40,
  String url = 'http://127.0.0.1:1/x.tar',
}) => DictionaryPackInfo(
  'niman-$code',
  languages: languages ?? [code],
  definitions: definitions,
  source: 'en.wiktionary',
  headwords: 1000,
  fileName: 'niman-$code.tar',
  url: url,
  bytes: megabytes * _mb,
  sha256: '0' * 64,
);

void main() {
  late Directory root;
  late DictionaryService service;
  late DictionaryInstallation installation;
  late FakeLibrarySession controller;
  HttpServer? server;
  // Flags, not completers: the server runs in a zone of its own, and what a
  // completer wakes in another zone waits for a pump that never comes.
  var released = false;
  var reached = false;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('niman_dict_screen');
    service = DictionaryService(directory: root.path);
    controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
  });

  tearDown(() async {
    released = true;
    await server?.close(force: true);
    server = null;
    installation.dispose();
    await service.dispose();
    for (var i = 0; i < 20 && root.existsSync(); i++) {
      try {
        root.deleteSync(recursive: true);
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  });

  /// Real files, isolates and sockets run outside the fake clock.
  Future<void> real(WidgetTester tester, Future<void> Function() body) =>
      tester.runAsync(body);

  /// The Dictionaries screen over [catalog], with the fixture packs for
  /// Italian and English on disk when [installed].
  Future<void> open(
    WidgetTester tester, {
    required List<DictionaryPackInfo> catalog,
    bool installed = true,
    Future<String?> Function(String, String)? removePack,
    DownloadStarter? startDownload,
  }) async {
    await real(tester, () async {
      if (installed) await writeFixturePacks(root.path);
      installation = DictionaryInstallation(
        directory: () async => root.path,
        service: () async => service,
        catalog: catalog,
        retryDelays: const [],
        removePack: removePack,
        startDownload: startDownload,
      );
      await installation.load();
    });
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dictionaryInstallationProvider.overrideWithValue(installation),
        ],
        child: MaterialApp(
          home: Scaffold(body: SettingsBody(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final area = find.byKey(const Key('settings-area-dictionaries'));
    await tester.ensureVisible(area);
    await tester.tap(area);
    await tester.pumpAndSettle();
  }

  /// Lets real time pass, a slice at a time, and the fake clock after it,
  /// until [done]: what a tap starts goes through isolates and files.
  Future<void> until(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await real(
        tester,
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(done(), isTrue, reason: 'timed out');
    await tester.pumpAndSettle();
  }

  double top(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  final catalog = [
    _info('it', definitions: 'it', megabytes: 25),
    _info('en', megabytes: 120),
    _info('de', definitions: 'de', megabytes: 60),
    _info('fr', definitions: 'fr', megabytes: 90),
    _info('sh', languages: ['hr', 'sr', 'bs'], megabytes: 10),
  ];

  testWidgets('the area is listed, with the dictionaries and the notes', (
    tester,
  ) async {
    await open(tester, catalog: catalog);
    expect(find.text(AppStrings.settingsSectionDictionaries), findsWidgets);
    expect(find.text(AppStrings.dictionariesIntro), findsOne);
    expect(find.text(AppStrings.dictionariesInstalled), findsOne);
    expect(find.text(AppStrings.dictionariesDownload), findsOne);
    expect(find.text(AppStrings.dictionaryPdfLanguageTitle), findsOne);
    expect(find.text(AppStrings.dictionaryPdfLanguageNote), findsOne);
    final notice = find.byKey(const Key('dictionary-notice'));
    expect(notice, findsOne);
    expect(
      find.descendant(
        of: notice,
        matching: find.textContaining(AppStrings.dictionaryNotice),
      ),
      findsOne,
    );
    expect(
      find.descendant(
        of: notice,
        matching: find.textContaining('CC BY-SA 4.0 and GFDL'),
      ),
      findsOne,
    );
    expect(find.textContaining('wiktextract'), findsOne);
  });

  testWidgets('an installed pack shows its language, source, licence and size, '
      'and can be removed', (tester) async {
    await open(tester, catalog: catalog);
    final tile = find.byKey(const Key('dictionary-tile-niman-it'));
    expect(
      find.descendant(of: tile, matching: find.text('Italiano')),
      findsOne,
    );
    final detail = find.descendant(
      of: tile,
      matching: find.textContaining('Wiktionary'),
    );
    final text = tester.widget<Text>(detail).data!;
    expect(text, contains(AppStrings.dictionaryDefinitions('Italiano')));
    expect(text, contains('CC BY-SA 4.0; GFDL'));
    expect(
      text,
      contains(AppStrings.byteSize(installation.installed.first.bytes)),
    );
    expect(find.byKey(const Key('dictionary-delete-niman-it')), findsOne);
    expect(find.byKey(const Key('dictionary-delete-niman-en')), findsOne);
    // An installed pack is not offered again.
    expect(find.byKey(const Key('dictionary-download-niman-it')), findsNothing);
  });

  testWidgets('the catalog lists what is not installed, with the language of '
      'its definitions and its size before the download', (tester) async {
    await open(tester, catalog: catalog);
    final de = find.byKey(const Key('dictionary-tile-niman-de'));
    expect(find.descendant(of: de, matching: find.text('Deutsch')), findsOne);
    final detail = tester
        .widget<Text>(
          find.descendant(of: de, matching: find.textContaining('Wiktionary')),
        )
        .data!;
    expect(detail, contains(AppStrings.dictionaryDefinitions('Deutsch')));
    expect(detail, contains(AppStrings.byteSize(60 * _mb)));
    expect(find.byKey(const Key('dictionary-download-niman-de')), findsOne);
    expect(find.byKey(const Key('dictionary-download-niman-fr')), findsOne);
    // The Serbo-Croatian pack names what it is for.
    final sh = find.byKey(const Key('dictionary-tile-niman-sh'));
    expect(
      find.descendant(of: sh, matching: find.text('Srpskohrvatski')),
      findsOne,
    );
    expect(
      find.descendant(
        of: sh,
        matching: find.textContaining(
          AppStrings.dictionaryServes('Hrvatski, Српски, Bosanski'),
        ),
      ),
      findsOne,
    );
    // Those on the device sit above the heading of those on offer.
    expect(
      top(tester, find.byKey(const Key('dictionary-tile-niman-it'))),
      lessThan(top(tester, find.text(AppStrings.dictionariesDownload))),
    );
    expect(
      top(tester, de),
      greaterThan(top(tester, find.text(AppStrings.dictionariesDownload))),
    );
  });

  testWidgets('the search narrows the offer by native and English name, and '
      'leaves the installed ones', (tester) async {
    await open(tester, catalog: catalog);
    final search = find.byKey(const Key('dictionary-search'));
    await tester.enterText(search, 'german');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dictionary-download-niman-de')), findsOne);
    expect(find.byKey(const Key('dictionary-download-niman-fr')), findsNothing);
    expect(find.byKey(const Key('dictionary-delete-niman-it')), findsOne);
    await tester.enterText(search, 'franç');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dictionary-download-niman-fr')), findsOne);
    expect(find.byKey(const Key('dictionary-download-niman-de')), findsNothing);
    // One pack for three languages answers to any of their names.
    for (final query in ['croat', 'srpsk', 'bosan', 'serbian', 'Српски']) {
      await tester.enterText(search, query);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('dictionary-download-niman-sh')),
        findsOne,
        reason: query,
      );
    }
    await tester.enterText(search, 'klingon');
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.dictionariesNoMatch), findsOne);
    expect(find.byKey(const Key('dictionary-download-niman-de')), findsNothing);
  });

  testWidgets('with every pack installed the offer says so', (tester) async {
    await open(tester, catalog: [_info('it'), _info('en')]);
    expect(find.text(AppStrings.dictionariesAllInstalled), findsOne);
  });

  testWidgets('an empty catalog says there is nothing to download yet, and '
      'the installed packs still show', (tester) async {
    await open(tester, catalog: const []);
    expect(find.text(AppStrings.dictionariesUnavailable), findsOne);
    expect(find.byKey(const Key('dictionary-search')), findsNothing);
    expect(find.byKey(const Key('dictionary-delete-niman-it')), findsOne);
    expect(find.text(AppStrings.dictionaryPdfLanguageNote), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with nothing installed and nothing on offer the page is just '
      'two quiet lines', (tester) async {
    await open(tester, catalog: const [], installed: false);
    expect(find.text(AppStrings.dictionariesNoneInstalled), findsOne);
    expect(find.text(AppStrings.dictionariesUnavailable), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pack this app cannot read says why, and can be removed', (
    tester,
  ) async {
    await real(tester, () async {
      await writePack(
        root.path,
        code: 'fr',
        entries: [(headword: 'a', html: 'b')],
        nimanPack: 2,
      );
    });
    await open(tester, catalog: catalog, installed: false);
    final tile = find.byKey(const Key('dictionary-tile-niman-fr'));
    expect(tile, findsOne);
    final detail = tester
        .widget<Text>(
          find.descendant(
            of: tile,
            matching: find.textContaining('Wiktionary'),
          ),
        )
        .data!;
    expect(
      detail,
      contains(
        AppStrings.dictionaryUnusable(
          installation.installed.single.pack.unavailableReason!,
        ),
      ),
    );
    expect(find.byIcon(Icons.error_outline), findsOne);

    await tester.tap(find.byKey(const Key('dictionary-delete-niman-fr')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dictionary-delete-confirm')));
    await until(tester, () => installation.installed.isEmpty);
    // Back among the offer, since the catalog still lists it.
    expect(find.byKey(const Key('dictionary-download-niman-fr')), findsOne);
  });

  testWidgets('a removal that fails says so, and the pack stays', (
    tester,
  ) async {
    await open(
      tester,
      catalog: catalog,
      removePack: (root, id) async => 'Access is denied.',
    );
    await tester.tap(find.byKey(const Key('dictionary-delete-niman-it')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dictionary-delete-confirm')));
    await until(
      tester,
      () => find
          .text(
            AppStrings.dictionaryRemoveFailed('Italiano', 'Access is denied.'),
          )
          .evaluate()
          .isNotEmpty,
    );
    expect(
      find.text(
        AppStrings.dictionaryRemoveFailed('Italiano', 'Access is denied.'),
      ),
      findsOne,
    );
    expect(find.byKey(const Key('dictionary-delete-niman-it')), findsOne);
  });

  testWidgets('a pack being unpacked and indexed keeps its place and shows '
      'how far it has got', (tester) async {
    await open(tester, catalog: catalog);
    final before = top(tester, find.text(AppStrings.dictionariesDownload));
    installation.debugPrepare(
      'niman-de',
      const DictionaryPreparation.unpacking(),
    );
    await tester.pump();
    final preparing = find.byKey(const Key('dictionary-preparing-niman-de'));
    expect(preparing, findsOne);
    expect(find.text(AppStrings.dictionaryUnpacking), findsOne);
    expect(find.byKey(const Key('dictionary-download-niman-de')), findsNothing);
    // It joined the installed ones, above the offer.
    expect(
      top(tester, preparing),
      lessThan(top(tester, find.text(AppStrings.dictionariesDownload))),
    );
    expect(
      top(tester, find.text(AppStrings.dictionariesDownload)),
      greaterThan(before),
    );

    installation.debugPrepare(
      'niman-de',
      const DictionaryPreparation.indexing(0.42),
    );
    await tester.pump();
    expect(find.text(AppStrings.dictionaryIndexing(42)), findsOne);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.descendant(
              of: preparing,
              matching: find.byType(LinearProgressIndicator),
            ),
          )
          .value,
      0.42,
    );
  });

  testWidgets('Download starts the download, and a failure is shown with '
      'Retry', (tester) async {
    await open(
      tester,
      catalog: catalog,
      startDownload: ({
        required uri,
        required target,
        required onProgress,
        sha256,
        onHeaders,
      }) async => throw const SocketException('offline'),
    );
    await tester.tap(find.byKey(const Key('dictionary-download-niman-de')));
    await until(
      tester,
      () => find
          .byKey(const Key('dictionary-retry-niman-de'))
          .evaluate()
          .isNotEmpty,
    );
    expect(find.text(AppStrings.downloadFailed), findsOne);
    expect(find.byKey(const Key('dictionary-download-niman-de')), findsNothing);
  });

  testWidgets('a download shows its progress with Cancel, among the installed '
      'ones, and Cancel puts it back', (tester) async {
    final body = Uint8List(4000);
    released = false;
    reached = false;
    late final HttpServer started;
    await real(tester, () async {
      started = server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
        ..listen((request) async {
          request.response.contentLength = body.length;
          request.response.add(body.sublist(0, 2000));
          await request.response.flush();
          reached = true;
          while (!released) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
          try {
            request.response.add(body.sublist(2000));
            await request.response.close();
          } on Object {
            // The client went away.
          }
        });
    });
    await open(
      tester,
      catalog: [
        _info('it'),
        _info('en'),
        _info('de', url: 'http://127.0.0.1:${started.port}/de.tar'),
      ],
    );
    final heading = find.text(AppStrings.dictionariesDownload);
    final tile = find.byKey(const Key('dictionary-tile-niman-de'));
    expect(top(tester, tile), greaterThan(top(tester, heading)));

    // Started where real time runs: a socket and an isolate are real.
    await real(tester, () async {
      unawaited(installation.download(installation.packs.last));
      while (!reached) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump();
    final cancel = find.byKey(const Key('dictionary-cancel-niman-de'));
    expect(cancel, findsOne);
    expect(find.byType(LinearProgressIndicator), findsOne);
    expect(top(tester, tile), lessThan(top(tester, heading)));
    expect(find.byKey(const Key('dictionary-download-niman-de')), findsNothing);

    await tester.tap(cancel);
    await until(
      tester,
      () => find
          .byKey(const Key('dictionary-download-niman-de'))
          .evaluate()
          .isNotEmpty,
    );
    expect(cancel, findsNothing);
    expect(top(tester, tile), greaterThan(top(tester, heading)));
  });

  testWidgets('the settings search finds the area and its rows, and each '
      'points at a row that is there', (tester) async {
    await open(tester, catalog: catalog);
    await tester.pageBack();
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(SettingsBody));
    final entries = [
      for (final entry in settingsSearchEntries(
        controller: controller,
        transcription: null,
        spellCheck: null,
        libraryName: 'Notes',
        context: context,
        flashHome: (_) {},
        openArea: (area, row) => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => settingsAreas(
              controller: controller,
              spellCheck: null,
              transcription: null,
              keyboardAttached: true,
            ).firstWhere((a) => a.id == area).build(row),
          ),
        ),
      ))
        if (entry.areaId == SettingsAreaId.dictionaries) entry,
    ];
    expect(
      [for (final entry in entries) entry.title],
      [
        AppStrings.settingsSectionDictionaries,
        AppStrings.dictionariesDownload,
        AppStrings.dictionaryPdfLanguageTitle,
      ],
    );
    for (final entry in entries) {
      expect(entry.area, AppStrings.settingsSectionDictionaries);
      entry.open();
      await tester.pumpAndSettle();
      expect(find.byKey(entry.rowKey), findsOneWidget, reason: entry.title);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });
}
