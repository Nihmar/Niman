// The look-up panel's content (#1383): the entry with the form that led to
// it, the entries one after the other, a script pair shown once, what a word
// with no definition offers, a language with no pack offering its download,
// a pack that cannot be used, the language chip, Copy and Annotate with the
// definition. Over the real engine and the fixture packs where a look-up is
// cheap, over a stand-in where it is the panel's state that is looked at.
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/dictionary/dictionary_credit.dart';
import 'package:niman/src/dictionary/dictionary_entry.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/dictionary/dictionary_pack_info.dart';
import 'package:niman/src/dictionary/dictionary_result.dart';
import 'package:niman/src/dictionary/dictionary_run.dart';
import 'package:niman/src/dictionary/dictionary_section.dart';
import 'package:niman/src/dictionary/dictionary_sense.dart';
import 'package:niman/src/dictionary/dictionary_service.dart';
import 'package:niman/src/ui/dictionary_panel.dart';
import 'package:niman/src/ui/dictionary_panel/grammar_names.dart';
import 'package:niman/src/ui/dictionary_panel/lookup_session.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

import '../unit/dictionary/fixture_packs.dart';
import '../unit/dictionary/pack_tar.dart';

DictionaryPackInfo _info(String code, Uint8List tar, int port) =>
    DictionaryPackInfo(
      'niman-$code',
      languages: [code],
      definitions: code,
      source: 'test.wiktionary',
      headwords: 5,
      fileName: 'niman-$code.tar',
      url: 'http://127.0.0.1:$port/niman-$code.tar',
      bytes: tar.length,
      sha256: sha256.convert(tar).toString(),
    );

DictionaryEntry _scriptEntry(String headword) => DictionaryEntry(
  headword: headword,
  language: 'sr',
  credit: const DictionaryCredit(bookName: 'Niman Serbo-Croatian'),
  sections: [
    const DictionarySection(
      'noun',
      tags: ['feminine'],
      senses: [
        DictionarySense([DictionaryRun('A written work.')]),
      ],
    ),
  ],
);

void main() {
  late Directory dir;
  late Directory root;
  late DictionaryService service;
  DictionaryInstallation? installation;
  HttpServer? server;
  final sessions = <DictionaryLookupSession>[];

  setUp(() {
    dir = Directory.systemTemp.createTempSync('niman_panel');
    root = Directory(p.join(dir.path, 'dictionary'));
    service = DictionaryService(directory: root.path);
  });

  tearDown(() async {
    sessions
      ..forEach((session) => session.dispose())
      ..clear();
    installation?.dispose();
    installation = null;
    await server?.close(force: true);
    server = null;
    await service.dispose();
    for (var i = 0; i < 20 && dir.existsSync(); i++) {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
    AppLanguages.reset();
  });

  /// Real files, isolates and sockets run outside the fake clock.
  Future<T> real<T>(WidgetTester tester, Future<T> Function() body) async =>
      (await tester.runAsync(body)) as T;

  /// Lets real time pass, a slice at a time, until [done].
  Future<void> until(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i++) {
      await real(
        tester,
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      // The fake clock moves with the real one: a download's throttles and
      // the panel's own timers run on it.
      await tester.pump(const Duration(milliseconds: 25));
    }
    expect(done(), isTrue, reason: 'timed out');
  }

  DictionaryInstallation installationOf(List<DictionaryPackInfo> catalog) =>
      installation = DictionaryInstallation(
        directory: () async => root.path,
        service: () async => service,
        catalog: catalog,
        retryDelays: const [],
      );

  /// The panel over a session that looks [selection] up in [language],
  /// through [lookUp] or the real engine.
  Future<DictionaryLookupSession> open(
    WidgetTester tester,
    String selection,
    String language, {
    DictionaryLookUp? lookUp,
    DictionaryAnnotate? annotate,
    VoidCallback? onClose,
    VoidCallback? onOpenSettings,
    ValueChanged<String>? onLanguage,
    Stream<IndexProgress>? progress,
    List<DictionaryPackInfo> catalog = const [],
  }) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final installed = installation ?? installationOf(catalog);
    final session = await real(tester, () async {
      await installed.load();
      return DictionaryLookupSession(
        lookUp: lookUp ?? service.lookUp,
        selection: selection,
        language: language,
        progress: progress,
        onLanguage: onLanguage,
      );
    });
    sessions.add(session);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 400,
              height: 700,
              child: Material(
                child: DictionaryPanel(
                  session: session,
                  installation: installed,
                  annotate: annotate,
                  onClose: onClose ?? () {},
                  onOpenSettings: onOpenSettings ?? () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return session;
  }

  Future<void> settled(
    WidgetTester tester,
    DictionaryLookupSession session,
  ) async {
    await until(tester, () => !session.loading);
    await tester.pump();
  }

  /// The two fixture packs on disk with their indexes built, so what is
  /// looked at is the panel and not the wait for an index.
  Future<void> withFixturePacks(WidgetTester tester) => real(tester, () async {
    await writeFixturePacks(root.path);
    await service.prepare('it');
    await service.prepare('en');
  });

  String title(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('lookup-title'))).data!;
  String subtitle(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('lookup-subtitle'))).data!;

  testWidgets('a form read leads to its lemma, with what led to it, the '
      'numbered senses, the forms and the pack', (tester) async {
    await withFixturePacks(tester);
    final session = await open(tester, 'Caminetti,', 'it-IT');
    await settled(tester, session);

    expect(title(tester), 'caminetto');
    expect(
      subtitle(tester),
      AppStrings.lookUpFromFormTags('caminetti', GrammarNames.tags(['plural'])),
    );
    expect(find.text(GrammarNames.describe('noun', ['masculine'])), findsOne);
    expect(find.text('1.'), findsOne);
    expect(find.text('2.'), findsOne);
    expect(find.textContaining('A small fireplace.'), findsOne);
    // The example, in italics; the qualifier before the second sense.
    final example = tester.widget<Text>(
      find.textContaining('accendere il caminetto'),
    );
    expect(example.textSpan!.style!.fontStyle, FontStyle.italic);
    expect(find.textContaining('(familiar)'), findsOne);
    // The gloss's own italics are drawn as such.
    final decorative = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains('A decorative hearth.'),
    );
    expect(decorative, findsOne);
    expect(
      tester.widget<Text>(find.byKey(const Key('lookup-forms'))).data,
      'caminetti',
    );
    expect(find.byKey(const Key('lookup-credit')), findsOne);
    expect(
      tester.widget<Text>(find.byKey(const Key('lookup-credit'))).data,
      contains('CC BY-SA 4.0'),
    );
    expect(find.text('Italiano'), findsOne);
  });

  testWidgets('the headword read itself says no form', (tester) async {
    await withFixturePacks(tester);
    final session = await open(tester, 'caminetto', 'it');
    await settled(tester, session);
    expect(title(tester), 'caminetto');
    expect(subtitle(tester), 'Italiano');
  });

  testWidgets('a form that is two lemmas shows them one after the other, '
      'the first as the title', (tester) async {
    await withFixturePacks(tester);
    final session = await open(tester, 'ami', 'it');
    await settled(tester, session);

    final headwords = session.groups.map((g) => g.entry.headword).toList();
    expect(headwords.toSet(), {'amare', 'amo'});
    expect(title(tester), headwords.first);
    // The second is a heading of its own in the body, below the first's
    // senses.
    expect(find.text(headwords.last), findsOne);
    expect(
      tester.getTopLeft(find.text(headwords.last)).dy,
      greaterThan(tester.getTopLeft(find.byKey(const Key('lookup-title'))).dy),
    );
    expect(find.text('To love.'), findsOne);
    expect(find.text('A fishing hook.'), findsOne);
  });

  testWidgets('the same entry in two scripts is shown once, the other '
      'spelling named', (tester) async {
    final session = await open(
      tester,
      'књига',
      'sr',
      lookUp: (selection, language) async => DictionaryResult(
        outcome: DictionaryOutcome.found,
        selection: selection,
        language: language,
        packId: 'niman-sh',
        matched: selection,
        entries: [_scriptEntry('књига'), _scriptEntry('knjiga')],
      ),
    );
    await settled(tester, session);
    expect(find.text('A written work.'), findsOne);
    expect(find.text(AppStrings.lookUpAlsoSpelled('knjiga')), findsOne);
    expect(title(tester), 'књига');
  });

  testWidgets('a section that is an inflected form says which lemma, and the '
      'lemma looks itself up, with a way back', (tester) async {
    await withFixturePacks(tester);
    final session = await open(tester, 'camini', 'it');
    await settled(tester, session);
    expect(title(tester), 'camini');
    expect(find.byKey(const Key('lookup-back')), findsNothing);

    await tester.tap(find.byKey(const Key('lookup-lemma-camino')));
    await settled(tester, session);
    expect(title(tester), 'camino');
    expect(find.text('Chimney.'), findsOne);

    await tester.tap(find.byKey(const Key('lookup-back')));
    await settled(tester, session);
    expect(title(tester), 'camini');
    expect(find.byKey(const Key('lookup-back')), findsNothing);
  });

  testWidgets('a word with no definition offers its nearest entries; one '
      'looks itself up, and Back returns to the word', (tester) async {
    await withFixturePacks(tester);
    final session = await open(tester, 'camin', 'it');
    await settled(tester, session);

    expect(title(tester), 'camin');
    expect(subtitle(tester), AppStrings.lookUpNoDefinition('Italiano'));
    expect(find.text(AppStrings.lookUpNotFound('Italiano')), findsOne);
    expect(find.text(AppStrings.lookUpDidYouMean), findsOne);
    // Nothing else is offered: no entry, no senses.
    expect(find.byKey(const Key('lookup-entries')), findsNothing);
    expect(find.byKey(const Key('lookup-suggestion-camino')), findsOne);

    await tester.tap(find.byKey(const Key('lookup-suggestion-camino')));
    await settled(tester, session);
    expect(title(tester), 'camino');
    expect(find.text('Chimney.'), findsOne);

    await tester.tap(find.byKey(const Key('lookup-back')));
    await settled(tester, session);
    expect(title(tester), 'camin');
    expect(find.byKey(const Key('lookup-suggestion-camino')), findsOne);
  });

  testWidgets("a language with no pack offers the catalog's, with its size, "
      'downloads it in the panel and looks the word up when it is ready', (
    tester,
  ) async {
    final tar = await real(tester, () async {
      final folder = Directory(p.join(dir.path, 'archive'))..createSync();
      return (await fixtureTar(folder)).readAsBytesSync();
    });
    await real(tester, () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
        ..listen((request) async {
          request.response.contentLength = tar.length;
          request.response.add(tar);
          await request.response.close();
        });
    });
    final info = _info('it', tar, server!.port);
    final session = await open(tester, 'caminetti', 'it', catalog: [info]);
    await settled(tester, session);

    expect(find.byKey(const Key('lookup-no-pack')), findsOne);
    expect(find.text(AppStrings.lookUpNoPack('Italiano')), findsOne);
    expect(
      find.text(
        AppStrings.lookUpDownloadPack(
          'Italiano',
          AppStrings.byteSize(tar.length),
        ),
      ),
      findsOne,
    );
    // The language can be changed instead.
    expect(find.byKey(const Key('lookup-change-language')), findsOne);

    // The tap starts the download; it runs where real time does, the
    // sockets and isolates being real (see `startDownload` below for the
    // tap itself).
    final pack = installation!.packs.single;
    await real(tester, () => installation!.download(pack));
    await until(tester, () => title(tester) == 'caminetto');
    expect(find.byKey(const Key('lookup-no-pack')), findsNothing);
    expect(
      subtitle(tester),
      AppStrings.lookUpFromFormTags('caminetti', GrammarNames.tags(['plural'])),
    );
  });

  testWidgets('the button starts the download, and one that fails says so '
      'with Retry', (tester) async {
    final asked = <Uri>[];
    final info = DictionaryPackInfo(
      'niman-it',
      languages: const ['it'],
      definitions: 'it',
      source: 'test.wiktionary',
      headwords: 5,
      fileName: 'niman-it.tar',
      url: 'http://127.0.0.1:1/niman-it.tar',
      bytes: 4000,
      sha256: '0' * 64,
    );
    installation = DictionaryInstallation(
      directory: () async => root.path,
      service: () async => service,
      catalog: [info],
      retryDelays: const [],
      startDownload:
          ({
            required uri,
            required target,
            required onProgress,
            sha256,
            onHeaders,
          }) async {
            asked.add(uri);
            throw const SocketException('offline');
          },
    );
    final session = await open(tester, 'caminetti', 'it');
    await settled(tester, session);
    await tester.tap(find.byKey(const Key('lookup-download')));
    await until(
      tester,
      () => find.byKey(const Key('lookup-retry')).evaluate().isNotEmpty,
    );
    expect(asked.single.toString(), info.url);
    expect(find.byKey(const Key('lookup-failed')), findsOne);
    expect(find.text(AppStrings.downloadFailed), findsOne);
    expect(find.byKey(const Key('lookup-download')), findsNothing);
  });

  testWidgets('with no pack in the catalog for the language it says so, and '
      'the chip is the way out', (tester) async {
    await withFixturePacks(tester);
    final session = await open(tester, 'Kartoffel', 'de');
    await settled(tester, session);

    expect(find.text(AppStrings.lookUpNoPackOffered('Deutsch')), findsOne);
    expect(find.byKey(const Key('lookup-download')), findsNothing);

    await tester.tap(find.byKey(const Key('lookup-language')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lookup-language-list')), findsOne);
    // The languages that have a dictionary come first.
    final italian = tester.getTopLeft(
      find.byKey(const Key('lookup-language-it')),
    );
    final english = tester.getTopLeft(
      find.byKey(const Key('lookup-language-en')),
    );
    final french = tester.getTopLeft(
      find.byKey(const Key('lookup-language-fr')),
    );
    expect(english.dy, lessThan(italian.dy));
    expect(italian.dy, lessThan(french.dy));
  });

  testWidgets('the chip changes the language, looks the text up again and '
      'tells who keeps the choice', (tester) async {
    await withFixturePacks(tester);
    final chosen = <String>[];
    final session = await open(
      tester,
      'ice cream',
      'it',
      onLanguage: chosen.add,
    );
    await settled(tester, session);
    expect(find.byKey(const Key('lookup-entries')), findsNothing);

    await tester.tap(find.byKey(const Key('lookup-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lookup-language-en')));
    await tester.pump();
    await settled(tester, session);

    expect(chosen, ['en']);
    expect(title(tester), 'ice cream');
    expect(find.text('A frozen dessert.'), findsOne);
    expect(
      find.descendant(
        of: find.byKey(const Key('lookup-language')),
        matching: find.text('English'),
      ),
      findsOne,
    );
  });

  testWidgets('a pack that cannot be used says why and links to the '
      'dictionaries in Settings', (tester) async {
    var opened = 0;
    final session = await open(
      tester,
      'caminetto',
      'it',
      onOpenSettings: () => opened++,
      lookUp: (selection, language) async => DictionaryResult(
        outcome: DictionaryOutcome.unavailable,
        selection: selection,
        language: language,
        packId: 'niman-it',
        reason: 'the index would not build',
      ),
    );
    await settled(tester, session);
    expect(find.byKey(const Key('lookup-unavailable')), findsOne);
    expect(
      find.text(AppStrings.dictionaryUnusable('the index would not build')),
      findsOne,
    );
    await tester.tap(find.byKey(const Key('lookup-open-settings')));
    expect(opened, 1);
  });

  testWidgets('a look-up that throws is a pack that cannot be used, not a '
      'blank panel', (tester) async {
    final session = await open(
      tester,
      'caminetto',
      'it',
      lookUp: (selection, language) async => throw StateError('no folder'),
    );
    await settled(tester, session);
    expect(find.byKey(const Key('lookup-unavailable')), findsOne);
    expect(find.textContaining('no folder'), findsOne);
  });

  testWidgets('the wait shows how far the index the look-up needs is built', (
    tester,
  ) async {
    final done = Completer<DictionaryResult>();
    final progress = StreamController<IndexProgress>.broadcast();
    addTearDown(progress.close);
    final session = await open(
      tester,
      'caminetto',
      'it',
      lookUp: (selection, language) => done.future,
      progress: progress.stream,
    );
    await tester.pump();
    expect(session.loading, isTrue);
    expect(find.byType(CircularProgressIndicator), findsOne);
    expect(find.byKey(const Key('lookup-indexing')), findsNothing);

    progress.add((packId: 'niman-it', fraction: 0.4));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(find.text(AppStrings.dictionaryIndexing(40)), findsOne);

    done.complete(
      const DictionaryResult(
        outcome: DictionaryOutcome.notFound,
        selection: 'caminetto',
        language: 'it',
      ),
    );
    await settled(tester, session);
    expect(find.byKey(const Key('lookup-indexing')), findsNothing);
    expect(find.byKey(const Key('lookup-not-found')), findsOne);
  });

  group('the actions', () {
    String? clipboard;
    setUp(() {
      clipboard = null;
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    void listen(WidgetTester tester) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
    }

    testWidgets('Copy puts the definition, as plain text, on the clipboard', (
      tester,
    ) async {
      listen(tester);
      await withFixturePacks(tester);
      final session = await open(tester, 'caminetto', 'it');
      await settled(tester, session);

      await tester.tap(find.byKey(const Key('lookup-copy')));
      await tester.pump();
      expect(
        clipboard,
        'caminetto\n\n'
        '${GrammarNames.describe('noun', ['masculine'])}\n'
        '1. A small fireplace.\n'
        '2. (familiar) A decorative hearth.',
      );
      // The icon says it was copied.
      expect(find.byIcon(Icons.check), findsOne);
    });

    testWidgets('Copy lists every part of speech and the lemma a form is '
        'of', (tester) async {
      listen(tester);
      await withFixturePacks(tester);
      final session = await open(tester, 'camini', 'it');
      await settled(tester, session);
      await tester.tap(find.byKey(const Key('lookup-copy')));
      await tester.pump();
      expect(clipboard, startsWith('camini\n\n'));
      expect(
        clipboard,
        contains(
          AppStrings.lookUpFormOf(GrammarNames.tags(['plural']), 'camino'),
        ),
      );
      expect(clipboard, contains('1. plural of camino'));
    });

    testWidgets('Annotate with the definition hands over the definition and '
        'closes the panel', (tester) async {
      await withFixturePacks(tester);
      final definitions = <String>[];
      var closed = 0;
      final session = await open(
        tester,
        'caminetto',
        'it',
        annotate: (definition) async => definitions.add(definition),
        onClose: () => closed++,
      );
      await settled(tester, session);
      await tester.tap(find.byKey(const Key('lookup-annotate')));
      expect(closed, 1);
      expect(definitions.single, startsWith('caminetto\n\n'));
      expect(definitions.single, contains('1. A small fireplace.'));
    });

    testWidgets('both icons stay, greyed, where there is nothing to copy or '
        'the surface cannot annotate', (tester) async {
      await withFixturePacks(tester);
      // Found, but the surface cannot annotate.
      final session = await open(tester, 'caminetto', 'it');
      await settled(tester, session);
      IconButton button(String key) =>
          tester.widget<IconButton>(find.byKey(Key(key)));
      expect(button('lookup-copy').onPressed, isNotNull);
      expect(button('lookup-annotate').onPressed, isNull);

      // Nothing found: both there, both greyed.
      await tester.pumpWidget(const SizedBox());
      final empty = await open(tester, 'zzzz', 'it');
      await settled(tester, empty);
      expect(find.byKey(const Key('lookup-copy')), findsOne);
      expect(find.byKey(const Key('lookup-annotate')), findsOne);
      expect(button('lookup-copy').onPressed, isNull);
      expect(button('lookup-annotate').onPressed, isNull);
    });
  });

  testWidgets('the tags are said in the language of the app, and a tag the '
      'strings do not know as the pack wrote it', (tester) async {
    expect(
      GrammarNames.tags(['plural', 'zzz-unknown']),
      contains('zzz-unknown'),
    );
    expect(GrammarNames.partOfSpeech('noun'), AppStrings.lookUpGrammar['noun']);
    AppLanguages.choice = AppLanguage.italian;
    expect(GrammarNames.tags(['plural']), AppStrings.lookUpGrammar['plural']);
    expect(GrammarNames.describe('', ['masculine']), isNot(startsWith(',')));
    expect(GrammarNames.describe('noun', const []), isNot(contains(',')));
  });
}
