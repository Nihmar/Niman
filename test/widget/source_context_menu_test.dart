// The source surface's context menu (#245, phase 3; the legacy editor's
// #174 and #60): a right click opens the clipboard, the toolbar's formats and
// the spelling's entries where the click was, and the same menu is the
// phone's selection toolbar.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';
import 'package:niman/src/ui/note_view.dart';

const MarkdownTheme _theme = MarkdownTheme(
  body: TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
  heading1: TextStyle(fontSize: 25),
  heading2: TextStyle(fontSize: 21),
  heading3: TextStyle(fontSize: 18),
  heading4: TextStyle(fontSize: 16),
  heading5: TextStyle(fontSize: 14),
  heading6: TextStyle(fontSize: 13),
  code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
  quote: TextStyle(fontSize: 14),
  tableCell: TextStyle(fontSize: 14),
  tableHeader: TextStyle(fontSize: 14),
  link: TextStyle(fontSize: 14),
  wikilink: TextStyle(fontSize: 14),
  tag: TextStyle(fontSize: 14),
  marker: TextStyle(fontSize: 14),
  codeHighlight: <String, TextStyle>{},
  rule: Color(0xFF888888),
  codeBackground: Color(0xFFEEEEEE),
  quoteBar: Color(0xFFCCCCCC),
  tableBorder: Color(0xFFCCCCCC),
  markerDim: Color(0xFF999999),
  blockSpacing: 10,
  listIndentPerLevel: 22,
  quoteIndentPerLevel: 12,
  codePadding: 8,
  quoteBarWidth: 3,
  ruleThickness: 1,
  tableCellPadding: EdgeInsets.all(4),
  lineHeight: 21,
);

/// Column [column] of line [line], as the view lays the text out (14 px a
/// glyph, a 5 px inset, an 8 px top margin, 21 px rows).
Offset _at(int line, int column) =>
    Offset(5 + column * 14.0 + 7, 8 + line * 21.0 + 10);

/// A checker whose only misspelling is 'wrold', which it would spell 'world'.
final class _FakeChecker implements SpellChecker {
  const new();

  @override
  bool get available => true;

  @override
  bool isCorrect(String word) => word != 'wrold';

  @override
  List<String> suggest(String word) => const <String>['world', 'wold'];

  @override
  void dispose() {}
}

/// Which unified mode a body is being run in: the same tests, twice.
enum _Mode { source, live }

Future<MarkdownSourceViewState> _pump(
  WidgetTester tester,
  String text, {
  FormatMenuBuilder? formatMenu,
  EditorSpellCheck? spellCheck,
  bool live = false,
}) async {
  tester.view.physicalSize = const Size(700, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText(text),
          theme: _theme,
          showLineNumbers: false,
          formatMenu: formatMenu,
          spellCheck: spellCheck,
          // The same tests in both unified modes (#246). The fixtures here
          // carry no markers, so a click at a column lands on the same
          // character either way — which is what lets one click test hold for
          // both.
          hideMarkers: live,
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

/// A right click at [at].
Future<void> _rightClick(WidgetTester tester, Offset at) async {
  await tester.tapAt(
    at,
    buttons: kSecondaryButton,
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump();
}

/// Records what the clipboard is given.
String? _clipboard;

void _mockClipboard(WidgetTester tester) {
  _clipboard = null;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        _clipboard = (call.arguments as Map)['text'] as String?;
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

/// The desktop's menu: flutter_test runs as Android unless told.
final TargetPlatformVariant _desktop = TargetPlatformVariant.only(
  TargetPlatform.linux,
);

void main() {
  /// The same test in `source` and in `live`: the criterion is that the menu
  /// behaves identically in both, so it is run in both.
  void both(
    String name,
    Future<void> Function(WidgetTester tester, _Mode mode) body, {
    TestVariant<Object?>? variant,
  }) {
    final desktop = variant ?? _desktop;
    for (final mode in _Mode.values) {
      testWidgets(
        '$name (${mode.name})',
        (tester) => body(tester, mode),
        variant: desktop,
      );
    }
  }

  both('a right click puts the caret there and opens the menu', (
    tester,
    mode,
  ) async {
    final state = await _pump(
      tester,
      'una parola sola\n',
      live: mode == _Mode.live,
    );
    await _rightClick(tester, _at(0, 6));
    expect(state.selection.extent, 6);
    expect(state.isContextMenuShown, isTrue);
    expect(find.text('Paste'), findsOneWidget);
    expect(
      find.text('Cut'),
      findsNothing,
      reason: 'a caret has nothing to cut',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Paste'), findsNothing, reason: 'Escape closes it');
  }, variant: _desktop);

  both('a right click on the selection keeps it, and Copy copies it', (
    tester,
    mode,
  ) async {
    _mockClipboard(tester);
    final state = await _pump(
      tester,
      'una parola sola\n',
      live: mode == _Mode.live,
    );
    state.select(const SelectionModel(anchor: 4, extent: 10));
    await tester.pump();
    await _rightClick(tester, _at(0, 6));
    expect(state.selectedText, 'parola');

    await tester.tap(find.text('Copy'));
    await tester.pump();
    expect(_clipboard, 'parola');
    expect(state.isContextMenuShown, isFalse);
  }, variant: _desktop);

  both('a click beside the menu closes it and does nothing else', (
    tester,
    mode,
  ) async {
    final state = await _pump(tester, 'una parola sola\n\n\n\nfine\n');
    await _rightClick(tester, _at(0, 6));
    await tester.tapAt(_at(4, 2), kind: PointerDeviceKind.mouse);
    await tester.pump();
    expect(state.isContextMenuShown, isFalse);
    expect(state.selection.extent, 6, reason: 'the click went to the barrier');
  }, variant: _desktop);

  both('the toolbar formats follow the clipboard and run', (
    tester,
    mode,
  ) async {
    var bolded = 0;
    await _pump(
      tester,
      'una parola sola\n',
      formatMenu: () => <FormatMenuEntry>[
        FormatMenuEntry(item: ToolbarItem.bold, onPressed: () => bolded++),
      ],
      live: mode == _Mode.live,
    );
    await _rightClick(tester, _at(0, 6));
    final bold = find.byKey(const Key('context-bold'));
    expect(bold, findsOneWidget);
    expect(
      tester.getTopLeft(bold).dy,
      greaterThan(tester.getTopLeft(find.text('Paste')).dy),
    );
    await tester.tap(bold);
    await tester.pump();
    expect(bolded, 1);
    expect(find.byKey(const Key('context-bold')), findsNothing);
  }, variant: _desktop);

  both('a misspelled word offers what the checker suggests', (
    tester,
    mode,
  ) async {
    final check = EditorSpellCheck(createChecker: (_) => const _FakeChecker());
    addTearDown(check.dispose);
    final state = await _pump(
      tester,
      'hello wrold\n',
      spellCheck: check,
      live: mode == _Mode.live,
    );
    await _rightClick(tester, _at(0, 8));
    expect(find.text('world'), findsOneWidget);
    expect(find.text('wold'), findsOneWidget);

    await tester.tap(find.text('world'));
    await tester.pump();
    expect(state.widget.buffer.text, 'hello world\n');
    expect(state.isContextMenuShown, isFalse);
    // One undo step puts the word back.
    expect(state.undo(), isTrue);
    expect(state.widget.buffer.text, 'hello wrold\n');
  }, variant: _desktop);

  both('a correct word offers no suggestions', (tester, mode) async {
    final check = EditorSpellCheck(createChecker: (_) => const _FakeChecker());
    addTearDown(check.dispose);
    await _pump(
      tester,
      'hello wrold\n',
      spellCheck: check,
      live: mode == _Mode.live,
    );
    await _rightClick(tester, _at(0, 2));
    expect(find.text('world'), findsNothing);
    expect(find.text('Paste'), findsOneWidget);
  }, variant: _desktop);

  both('the menu key opens the menu at the caret', (tester, mode) async {
    final state = await _pump(
      tester,
      'una parola sola\n',
      live: mode == _Mode.live,
    );
    await tester.tapAt(_at(0, 3), kind: PointerDeviceKind.mouse);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pump();
    expect(state.isContextMenuShown, isTrue);
    expect(find.text('Paste'), findsOneWidget);
  }, variant: _desktop);

  both('in the note, Bold from the menu wraps the selection', (
    tester,
    mode,
  ) async {
    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            path: '/n/a.md',
            showLineNumbers: false,
            autofocusEditor: true,
            toolbarTop: true,
            // The WYSIWYG pane: the same menu over the `live` surface.
            showWysiwyg: mode == _Mode.live,
            readNote: (_) async => 'hello',
            writeNote: (_, text) async => saved = text,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final view = find.byType(MarkdownSurface);
    final state = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    )..selectAll();
    await tester.pump();
    await tester.tapAt(
      tester.getTopLeft(view) + const Offset(20, 18),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    // The note's menu is grouped (#260): Bold is under Format.
    await tester.tap(find.byKey(const Key('menu-format')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('menu-bold')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(state.widget.buffer.text, '**hello**');
    expect(saved, '**hello**');
  }, variant: _desktop);

  group("the note's menu, grouped (#260)", () {
    Future<MarkdownSourceViewState> open(
      WidgetTester tester,
      _Mode mode,
      String text, {
      required int caret,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteView(
              path: '/n/a.md',
              showLineNumbers: false,
              autofocusEditor: true,
              toolbarTop: true,
              showWysiwyg: mode == _Mode.live,
              readNote: (_) async => text,
              writeNote: (_, _) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<MarkdownSourceViewState>(
        find.byType(MarkdownSourceView),
      )..placeCaret(caret);
      await tester.pump();
      state.showContextMenu();
      await tester.pump();
      return state;
    }

    double top(WidgetTester tester, String key) =>
        tester.getTopLeft(find.byKey(Key(key))).dy;

    both('links, then the groups, then the clipboard, greyed out in place', (
      tester,
      mode,
    ) async {
      await open(tester, mode, 'hello', caret: 2);
      expect(top(tester, 'menu-link'), lessThan(top(tester, 'menu-format')));
      expect(
        top(tester, 'menu-insert'),
        lessThan(top(tester, 'context-paste')),
      );
      // Nothing is selected: Cut and Copy are there, and do nothing.
      final cut = tester.widget<InkWell>(find.byKey(const Key('context-cut')));
      expect(cut.onTap, isNull);
      // And the toolbar's flat list is not.
      expect(find.byKey(const Key('context-bold')), findsNothing);
    }, variant: _desktop);

    both('Paragraph › Heading 2, and Body takes it off', (tester, mode) async {
      final state = await open(tester, mode, 'titolo', caret: 2);
      await tester.tap(find.byKey(const Key('menu-paragraph')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('menu-heading-2')));
      await tester.pumpAndSettle();
      expect(state.widget.buffer.text, '## titolo');
      state.showContextMenu();
      await tester.pump();
      await tester.tap(find.byKey(const Key('menu-paragraph')));
      await tester.pump();
      final lit = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byKey(const Key('menu-heading-2')),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(lit.properties.toggled, isTrue, reason: 'the level it is');
      await tester.tap(find.byKey(const Key('menu-body')));
      await tester.pumpAndSettle();
      expect(state.widget.buffer.text, 'titolo');
    }, variant: _desktop);

    both('Insert › Footnote cites and defines the next number', (
      tester,
      mode,
    ) async {
      final state = await open(
        tester,
        mode,
        'Una frase[^1].\nche va avanti.\n\nAltro.\n\n[^1]: prima',
        caret: 'Una frase[^1].'.length,
      );
      await tester.tap(find.byKey(const Key('menu-insert')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('menu-footnote')));
      await tester.pumpAndSettle();
      expect(
        state.widget.buffer.text,
        'Una frase[^1].[^2]\nche va avanti.\n\n[^2]: \n\nAltro.\n\n'
        '[^1]: prima',
      );
      expect(
        state.selection.extent,
        state.widget.buffer.text.indexOf('[^2]: ') + 6,
        reason: 'the caret is on the definition, to write it',
      );
    }, variant: _desktop);

    testWidgets('on a phone the groups open as sheets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteView(
              path: '/n/a.md',
              showLineNumbers: false,
              autofocusEditor: true,
              toolbarTop: true,
              showWysiwyg: true,
              readNote: (_) async => 'hello world',
              writeNote: (_, _) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<MarkdownSourceViewState>(
        find.byType(MarkdownSourceView),
      );
      await tester.longPressAt(
        tester.getTopLeft(find.byType(MarkdownSurface)) + const Offset(30, 18),
      );
      await tester.pumpAndSettle();
      // The groups are in the bar's overflow.
      if (find.byKey(const Key('menu-format')).evaluate().isEmpty) {
        await tester.tap(find.byIcon(Icons.more_vert).last);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('menu-format')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu-bold')));
      await tester.pumpAndSettle();
      expect(state.widget.buffer.text, '**hello** world');
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });
}
