// Looking up what a PDF has selected (#1383): its menu entry, the language
// the reader chose for the file kept in the library's reading positions and
// used the next time, the passage annotated with the definition where there
// is a library and greyed where there is none, and the key. The viewer
// itself needs the PDF engine, so the selection is a stand-in.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/dictionary/dictionary_providers.dart';
import 'package:niman/src/dictionary/dictionary_service.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/dictionary_look_up_action.dart';
import 'package:niman/src/ui/file_tree_context.dart' show OsLauncher;
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/pdf_document_view.dart';
import 'package:niman/src/ui/pdf_document_view_state.dart';
import 'package:niman/src/ui/pdf_look_up.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

import '../fakes/fake_library_session.dart';
import '../unit/dictionary/fixture_packs.dart';

/// A selection of [text], as the PDF viewer would hand it.
final class _Selection implements PdfTextSelectionDelegate {
  _Selection(this.text);

  final String text;

  @override
  bool get hasSelectedText => text.isNotEmpty;

  @override
  Future<String> getSelectedText() async => text;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A widget whose state owns the look-up, as the PDF's does.
final class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

final class _HostState extends State<_Host> {
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void main() {
  late Directory dir;
  late DictionaryService service;
  late DictionaryInstallation installation;
  late FakeLibrarySession library;
  late ReadingPositions positions;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('niman_pdf_look');
    final packs = Directory(p.join(dir.path, 'dictionary'));
    service = DictionaryService(directory: packs.path);
    await writeFixturePacks(packs.path);
    await service.prepare('it');
    await service.prepare('en');
    installation = DictionaryInstallation(
      directory: () async => packs.path,
      service: () async => service,
      catalog: const [],
    );
    await installation.load();
    library = FakeLibrarySession();
    await library.open('/fake/library', create: true);
    await library.setSpellDictionaries(['it_IT']);
    positions = ReadingPositions(p.join(dir.path, 'library'));
    Directory(p.join(dir.path, 'library', 'papers'))
        .createSync(recursive: true);
  });

  tearDown(() async {
    AppKeyMap.current.value = KeyMap.defaults;
    installation.dispose();
    await service.dispose();
    for (var i = 0; i < 20 && dir.existsSync(); i++) {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  });

  String pdf() => p.join(dir.path, 'library', 'papers', 'a.pdf');

  Future<_HostState> pump(WidgetTester tester, {bool pointer = false}) async {
    tester.view
      ..physicalSize = const Size(900, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dictionaryServiceProvider.overrideWith((ref) async => service),
          dictionaryInstallationProvider.overrideWithValue(installation),
          librarySessionProvider.overrideWithValue(library),
        ],
        child: MaterialApp(
          theme: ThemeData(
            visualDensity: pointer
                ? VisualDensity.compact
                : VisualDensity.standard,
          ),
          home: const Scaffold(body: _Host()),
        ),
      ),
    );
    return tester.state<_HostState>(find.byType(_Host));
  }

  PdfLookUp lookUpOf(
    _HostState owner, {
    ReadingPositions? kept,
    Annotation? passage,
    List<Annotation>? annotated,
  }) => PdfLookUp(
    owner: owner,
    path: pdf(),
    positions: kept,
    passage: (selection) async => passage,
    annotate: (annotation) => annotated?.add(annotation),
  );

  PdfViewerContextMenuBuilderParams menu(
    _Selection selection, {
    VoidCallback? dismiss,
  }) => PdfViewerContextMenuBuilderParams(
    isTextSelectionEnabled: true,
    anchorA: const Offset(300, 100),
    anchorB: const Offset(300, 120),
    textSelectionDelegate: selection,
    dismissContextMenu: dismiss ?? () {},
    contextMenuFor: PdfViewerPart.selectedText,
  );

  Future<void> answered(WidgetTester tester) async {
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
      final done = [
        'lookup-entries',
        'lookup-not-found',
        'lookup-no-pack',
      ].any((key) => find.byKey(Key(key)).evaluate().isNotEmpty);
      if (done) break;
    }
    await tester.pumpAndSettle();
  }

  String title(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('lookup-title'))).data!;

  testWidgets('the menu entry is Look up, and dismisses the viewer\'s menu', (
    tester,
  ) async {
    final owner = await pump(tester);
    var dismissed = 0;
    final item = lookUpOf(owner)
        .menuItem(menu(_Selection('caminetti'), dismiss: () => dismissed++));
    expect(item.label, AppStrings.lookUpAction);
    item.onPressed!();
    expect(dismissed, 1);
    await answered(tester);
    expect(title(tester), 'caminetto');
    // The library's first spelling language: a PDF says none.
    expect(find.text('Italiano'), findsWidgets);
  });

  testWidgets('the language chosen in the panel is kept for the file, and '
      'the next look-up starts in it, in this session and the next', (
    tester,
  ) async {
    final owner = await pump(tester);
    final first = lookUpOf(owner, kept: positions);
    first.menuItem(menu(_Selection('polished'))).onPressed!();
    await answered(tester);
    // In Italian there is nothing to find.
    expect(find.byKey(const Key('lookup-not-found')), findsOne);
    await tester.tap(find.byKey(const Key('lookup-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lookup-language-en')));
    for (
      var i = 0;
      i < 40 && find.byKey(const Key('lookup-entries')).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }
    expect(title(tester), 'polish');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // The file's entry holds it, beside no place.
    final key = positions.keyOf(pdf())!;
    for (
      var i = 0;
      i < 40 && await tester.runAsync(() => positions.language(key)) == null;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
    }
    expect(await tester.runAsync(() => positions.language(key)), 'en');
    expect(await tester.runAsync(() => positions.read(key)), isNull);

    // This session: the next look-up is in English at once.
    first.menuItem(menu(_Selection('polished'))).onPressed!();
    await answered(tester);
    expect(title(tester), 'polish');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // The next session: the pane opens the file anew and reads the choice.
    final again = lookUpOf(owner, kept: positions);
    await tester.runAsync(again.load);
    again.menuItem(menu(_Selection('polished'))).onPressed!();
    await answered(tester);
    expect(title(tester), 'polish');
  });

  testWidgets('a PDF outside a library keeps the choice for the session '
      'only', (tester) async {
    final owner = await pump(tester);
    final outside = lookUpOf(owner);
    outside.menuItem(menu(_Selection('polished'))).onPressed!();
    await answered(tester);
    await tester.tap(find.byKey(const Key('lookup-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lookup-language-en')));
    for (
      var i = 0;
      i < 40 && find.byKey(const Key('lookup-entries')).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    outside.menuItem(menu(_Selection('polished'))).onPressed!();
    await answered(tester);
    expect(title(tester), 'polish');
    // Nowhere was anything written.
    expect(
      File(p.join(dir.path, 'library', ReadingPositions.filePath)).existsSync(),
      isFalse,
    );
  });

  testWidgets('Annotate with the definition hands over the passage the '
      'selection holds, the definition its comment; outside a library it is '
      'greyed', (tester) async {
    final owner = await pump(tester);
    final annotated = <Annotation>[];
    const passage = Annotation(
      path: 'papers/a.pdf',
      place: PdfLocation(page: 3, chars: (start: 10, end: 19)),
      label: 'a, p. 3',
      quote: 'caminetti',
    );
    lookUpOf(
      owner,
      kept: positions,
      passage: passage,
      annotated: annotated,
    ).menuItem(menu(_Selection('caminetti'))).onPressed!();
    await answered(tester);
    await tester.tap(find.byKey(const Key('lookup-annotate')));
    await tester.pumpAndSettle();
    expect(annotated.single.quote, 'caminetti');
    expect((annotated.single.place as PdfLocation).page, 3);
    expect(annotated.single.comment, startsWith('caminetto\n\n'));

    lookUpOf(
      owner,
      annotated: annotated,
    ).menuItem(menu(_Selection('caminetti'))).onPressed!();
    await answered(tester);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('lookup-annotate')))
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<IconButton>(find.byKey(const Key('lookup-copy'))).onPressed,
      isNotNull,
    );
  });

  testWidgets('the key looks the selection up under the pointer, and is '
      'there only while no command of the app has it', (tester) async {
    final owner = await pump(tester, pointer: true);
    final look = lookUpOf(owner);
    var selection = _Selection('caminetti');
    final bindings = look.bindings(() => selection);
    expect(bindings, hasLength(1));
    final run = bindings.values.single;

    look.pointer = const Offset(400, 300);
    run();
    await answered(tester);
    final popup = tester.getRect(find.byKey(const Key('lookup-popup')));
    expect(popup.top, 300 + 10 + 6);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // Nothing selected: nothing happens.
    selection = _Selection('');
    run();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lookup-popup')), findsNothing);

    // The keys given to a command of the app are that command's.
    AppKeyMap.current.value = KeyMap.defaults.withBinding(
      AppCommand.zenMode,
      lookUpShortcut(),
    );
    expect(lookUpShortcut(), isNull);
    expect(look.bindings(() => selection), isEmpty);
  });

  group("the PDF's own menu", () {
    Future<PdfDocumentViewState> pane(
      WidgetTester tester, {
      ReadingPositions? kept,
      void Function(Annotation annotation)? onAnnotate,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dictionaryServiceProvider.overrideWith((ref) async => service),
            dictionaryInstallationProvider.overrideWithValue(installation),
            librarySessionProvider.overrideWithValue(library),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PdfDocumentView(
                path: pdf(),
                launcher: const OsLauncher(),
                positions: kept,
                onAnnotate: onAnnotate,
              ),
            ),
          ),
        ),
      );
      return tester.state<PdfDocumentViewState>(find.byType(PdfDocumentView));
    }

    List<String?> labels(PdfDocumentViewState state) {
      final items = <ContextMenuButtonItem>[];
      state.selectionMenu(menu(_Selection('caminetti')), items);
      return [for (final item in items) item.label];
    }

    testWidgets('Look up comes after Annotate', (tester) async {
      final state = await pane(tester, kept: positions, onAnnotate: (_) {});
      expect(labels(state), [
        AppStrings.annotateAction,
        AppStrings.lookUpAction,
      ]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a PDF outside a library has Look up alone', (tester) async {
      final state = await pane(tester);
      expect(labels(state), [AppStrings.lookUpAction]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('nothing selected, no entry', (tester) async {
      final state = await pane(tester, kept: positions, onAnnotate: (_) {});
      final items = <ContextMenuButtonItem>[];
      state.selectionMenu(menu(_Selection('')), items);
      expect(items, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  });

  test('the key is Ctrl+D, and Cmd+D on a Mac', () {
    final keys = lookUpShortcut()!;
    expect(keys.trigger, LogicalKeyboardKey.keyD);
    expect(keys.control, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final mac = lookUpShortcut()!;
    expect(mac.meta, isTrue);
    expect(mac.control, isFalse);
  });
}
