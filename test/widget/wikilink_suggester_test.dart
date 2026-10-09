// The wikilink suggester panel (#475): while a wikilink is typed the panel
// lists the library's notes after `[[` and a note's headings after `#`,
// filters as the text grows, and completes the link on Enter/Tab without
// writing anything but the link.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/render/wikilink_panel.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/ui/keyboard_presence.dart';

import '../fakes/fake_wikilink_suggester.dart';

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

/// The library the panel reads in these tests.
FakeWikilinkSuggester _library() => FakeWikilinkSuggester(
  notes: const <NoteSuggestion>[
    NoteSuggestion(name: 'Notes', folder: 'Archive', target: 'Notes'),
    NoteSuggestion(name: 'Notes', folder: 'Guides', target: 'Notes'),
    NoteSuggestion(
      name: 'Markdown basics',
      folder: 'Guides',
      target: 'Markdown basics',
      alias: 'md',
    ),
    NoteSuggestion(
      name: 'Meeting notes',
      folder: 'Personal',
      target: 'Meeting notes',
    ),
    NoteSuggestion(
      name: 'Meeting notes',
      folder: 'Work',
      target: 'Meeting notes',
    ),
  ],
  headings: const <String, List<HeadingSuggestion>>{
    'Notes': <HeadingSuggestion>[
      HeadingSuggestion('Links'),
      HeadingSuggestion('Link targets'),
      HeadingSuggestion('Dead links'),
    ],
  },
);

void main() {
  /// Pumps the live/source surface over [text] with [suggester], tapping it so
  /// the platform's own text path is the one a keystroke takes.
  Future<MarkdownSourceViewState> pump(
    WidgetTester tester,
    SourceBuffer buffer,
    FakeWikilinkSuggester? suggester, {
    MarkdownSurfaceMode mode = MarkdownSurfaceMode.source,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSurface(
            buffer: buffer,
            mode: mode,
            theme: _theme,
            showLineNumbers: false,
            wikilinkSuggester: suggester,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(MarkdownSourceView));
    await tester.pump();
    return tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
  }

  /// Types the whole note's new text, the way the platform reports it, the
  /// caret at [caret] — the end when none is given.
  Future<void> type(WidgetTester tester, String text, {int? caret}) async {
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: caret ?? text.length),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  WikilinkPanel panel(WidgetTester tester) =>
      tester.widget<WikilinkPanel>(find.byType(WikilinkPanel));

  /// The note [key] leaves at [caret] in [text] on a surface with no library,
  /// where no panel can take it: what the key does with no panel.
  Future<String> withNoPanel(
    WidgetTester tester,
    String text,
    int caret,
    LogicalKeyboardKey key,
  ) async {
    final buffer = SourceBuffer.fromText(text);
    final state = await pump(tester, buffer, null);
    state.placeCaret(caret);
    await tester.pump();
    await tester.sendKeyEvent(key);
    await tester.pump();
    return buffer.text;
  }

  testWidgets('typing [[ lists the library notes', (tester) async {
    final buffer = SourceBuffer.fromText('');
    final suggester = _library();
    final state = await pump(tester, buffer, suggester);

    await type(tester, '[[');

    expect(state.isSuggesterShown, isTrue);
    expect(suggester.noteQueries, contains(''));
    final drawn = panel(tester);
    expect(drawn.kind, WikilinkPanelKind.notes);
    expect(drawn.entries.whereType<NoteSuggestion>().map((n) => n.name), [
      'Notes',
      'Notes',
      'Markdown basics',
      'Meeting notes',
      'Meeting notes',
    ]);
    // The folder tells the two same-named notes apart, and the alias row says
    // how it was found.
    expect(drawn.entries.whereType<NoteSuggestion>().map((n) => n.folder), [
      'Archive',
      'Guides',
      'Guides',
      'Personal',
      'Work',
    ]);
  });

  testWidgets('typing ![[ lists the attachments, then the notes (#705)', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText('');
    final suggester = FakeWikilinkSuggester(
      notes: const <NoteSuggestion>[
        NoteSuggestion(name: 'Notes', folder: '', target: 'Notes'),
      ],
      attachments: const <NoteSuggestion>[
        NoteSuggestion(
          name: 'photo.png',
          folder: 'attachments',
          target: 'photo.png',
        ),
      ],
    );
    final state = await pump(tester, buffer, suggester);

    await type(tester, '![[');

    expect(state.isSuggesterShown, isTrue);
    expect(suggester.embedQueries, ['']);
    expect(suggester.noteQueries, [''], reason: 'the fake lists notes after');
    expect(panel(tester).kind, WikilinkPanelKind.embeds);
    expect(
      panel(tester).entries.whereType<NoteSuggestion>().map((n) => n.name),
      ['photo.png', 'Notes'],
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(buffer.text, '![[photo.png]]');
  });

  testWidgets('typing more narrows the list', (tester) async {
    final buffer = SourceBuffer.fromText('');
    final suggester = _library();
    await pump(tester, buffer, suggester);

    await type(tester, '[[');
    await type(tester, '[[No');

    final names = panel(tester).entries
        .whereType<NoteSuggestion>()
        .map((n) => n.name)
        .toList();
    expect(
      names,
      ['Notes', 'Notes', 'Meeting notes', 'Meeting notes'],
      reason:
          'the two prefix matches first, the contains matches after, '
          'and the name that matched neither gone',
    );
    expect(suggester.noteQueries, ['', 'No']);
  });

  testWidgets('Enter completes the link and the caret lands after it', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText('');
    final state = await pump(tester, buffer, _library());

    await type(tester, '[[Note');
    expect(panel(tester).entries, isNotEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    // The picked row, the prefix match at the top: the note named `Notes`,
    // with the closing `]]` written behind it.
    expect(buffer.text, '[[Notes]]');
    expect(
      state.selection.extent,
      9,
      reason: 'the caret stands past the closing brackets',
    );
    expect(state.isSuggesterShown, isFalse, reason: 'completing closes it');
  });

  testWidgets('Tab completes the link too', (tester) async {
    final buffer = SourceBuffer.fromText('');
    await pump(tester, buffer, _library());

    await type(tester, '[[Meeting');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(buffer.text, '[[Meeting notes]]');
  });

  testWidgets('Up/Down move the picked row', (tester) async {
    final buffer = SourceBuffer.fromText('');
    await pump(tester, buffer, _library());

    await type(tester, '[[');
    expect(panel(tester).selected, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(panel(tester).selected, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(panel(tester).selected, 0);
    // Down at the bottom stays on the last row.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(panel(tester).selected, 0);
  });

  testWidgets('# lists the named note headings and completes one', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText('');
    final suggester = _library();
    await pump(tester, buffer, suggester);

    await type(tester, '[[Notes#Li');

    expect(suggester.headingTargets, contains('Notes'));
    final drawn = panel(tester);
    expect(drawn.kind, WikilinkPanelKind.headings);
    expect(drawn.entries.map((e) => (e as HeadingSuggestion).heading), [
      'Links',
      'Link targets',
      'Dead links',
    ], reason: 'prefix matches before contains');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(buffer.text, '[[Notes#Links]]');
  });

  testWidgets('a row found through an alias says so', (tester) async {
    final buffer = SourceBuffer.fromText('');
    await pump(tester, buffer, _library());

    await type(tester, '[[md');

    final drawn = panel(tester);
    expect(drawn.entries.map((e) => (e as NoteSuggestion).name), [
      'Markdown basics',
    ]);
    expect(drawn.entries.single, isA<NoteSuggestion>());
    expect((drawn.entries.single as NoteSuggestion).alias, 'md');
    expect(
      find.textContaining('alias md'),
      findsOneWidget,
      reason: 'the row carries the alias it was found through',
    );
  });

  testWidgets('the empty target offers the note being edited', (tester) async {
    final buffer = SourceBuffer.fromText('# Links\n\nSee also [[');
    final state = await pump(tester, buffer, _library());
    await tester.pumpAndSettle();

    state.placeCaret(buffer.length);
    await tester.pump();
    await type(tester, '# Links\n\nSee also [[#');

    final drawn = panel(tester);
    expect(drawn.kind, WikilinkPanelKind.headings);
    expect(
      drawn.named,
      isEmpty,
      reason: 'the caption names the note being edited, not a target',
    );
    expect(drawn.entries.map((e) => (e as HeadingSuggestion).heading), [
      'Links',
    ]);
  });

  testWidgets('a book target offers its place form, not a list', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText('');
    final suggester = FakeWikilinkSuggester(
      places: const <BookSuggestion>[
        BookSuggestion(form: 'page=', hint: 'type a number'),
      ],
    );
    await pump(tester, buffer, suggester);

    await type(tester, '[[Dune.pdf#');

    final drawn = panel(tester);
    expect(drawn.kind, WikilinkPanelKind.book);
    expect(drawn.entries.single, isA<BookSuggestion>());
    expect(find.textContaining('Places in'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    // The number still has to be typed, so the link is left open at the `=`.
    expect(buffer.text, '[[Dune.pdf#page=');
  });

  testWidgets('the number typed after a book form is not overwritten', (
    tester,
  ) async {
    // `[[Dune.pdf#` and Enter write the form `page=`, leaving the caret on
    // its `=` for the number. What follows is the writer's number, which no
    // row completes: a second key wrote the form over it (#494).
    const written = '[[Dune.pdf#page=12';
    final suggester = FakeWikilinkSuggester(
      places: const <BookSuggestion>[
        BookSuggestion(form: 'page=', hint: 'type a number'),
      ],
    );

    Future<String> form(LogicalKeyboardKey key) async {
      final buffer = SourceBuffer.fromText('');
      final state = await pump(tester, buffer, suggester);
      await type(tester, '[[Dune.pdf#');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(buffer.text, '[[Dune.pdf#page=');

      await type(tester, written);
      expect(
        state.isSuggesterShown,
        isFalse,
        reason: 'the form is written through: nothing is left to complete',
      );

      await tester.sendKeyEvent(key);
      await tester.pump();
      return buffer.text;
    }

    for (final key in <LogicalKeyboardKey>[
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.tab,
    ]) {
      expect(
        await form(key),
        startsWith(written),
        reason: '$key leaves the number the writer typed',
      );
    }
  });

  testWidgets('the footer carries the keys the panel answers', (tester) async {
    final buffer = SourceBuffer.fromText('');
    await pump(tester, buffer, _library());

    await type(tester, '[[');

    expect(find.text('Tab'), findsOneWidget);
    expect(find.text('insert'), findsOneWidget);
    expect(find.text('close'), findsOneWidget);
  });

  testWidgets('a tapped row completes the link, the one tapped', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText('');
    final state = await pump(tester, buffer, _library());

    await type(tester, '[[Note');
    final entries = panel(tester).entries;
    final meeting = entries.indexWhere(
      (entry) => entry is NoteSuggestion && entry.name == 'Meeting notes',
    );
    expect(meeting, greaterThan(0), reason: 'not the selected row');

    await tester.tap(find.byKey(Key('wikilink-panel-row-$meeting')));
    await tester.pump();

    expect(buffer.text, '[[Meeting notes]]');
    expect(state.isSuggesterShown, isFalse, reason: 'completing closes it');
  });

  testWidgets('on a phone the rows are a fingertip tall', (tester) async {
    // The tests run as Android: rows there are tapped.
    await pump(tester, SourceBuffer.fromText(''), _library());
    await type(tester, '[[');
    expect(panel(tester).rowHeight, wikilinkPanelTouchRowHeight);
    expect(
      tester.getSize(find.byKey(const Key('wikilink-panel-row-0'))).height,
      wikilinkPanelTouchRowHeight,
    );
  });

  group('with no keyboard seen', () {
    late bool wasAttached;
    setUp(() {
      wasAttached = KeyboardPresence.shared.attached;
      KeyboardPresence.shared.attached = false;
    });
    tearDown(() => KeyboardPresence.shared.attached = wasAttached);

    testWidgets('the footer names no keys', (tester) async {
      await pump(tester, SourceBuffer.fromText(''), _library());
      await type(tester, '[[');

      expect(find.byKey(const Key('wikilink-panel')), findsOneWidget);
      expect(find.text('Tab'), findsNothing);
      expect(find.text('Esc'), findsNothing);
    });
  });

  testWidgets('a name that matches nothing says so', (tester) async {
    final buffer = SourceBuffer.fromText('');
    await pump(tester, buffer, _library());

    await type(tester, '[[zzz');

    expect(find.byType(WikilinkPanel), findsOneWidget);
    expect(panel(tester).entries, isEmpty);
    expect(
      find.textContaining('No note matches', findRichText: true),
      findsOneWidget,
    );
    // And the panel writes nothing: the dead name is left as typed.
    expect(buffer.text, '[[zzz');
  });

  testWidgets('Escape closes the panel and leaves the text alone', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText('');
    final state = await pump(tester, buffer, _library());

    await type(tester, '[[No');
    expect(state.isSuggesterShown, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(state.isSuggesterShown, isFalse);
    expect(buffer.text, '[[No', reason: 'Escape never edits the note');
  });

  testWidgets('the panel is drawn in both surfaces', (tester) async {
    for (final mode in MarkdownSurfaceMode.values) {
      final buffer = SourceBuffer.fromText('');
      final state = await pump(tester, buffer, _library(), mode: mode);
      await type(tester, '[[');
      expect(
        state.isSuggesterShown,
        isTrue,
        reason: '$mode draws the panel under the caret',
      );
      expect(find.byType(WikilinkPanel), findsOneWidget);
      expect(
        panel(tester).entries.whereType<NoteSuggestion>().map((n) => n.name),
        contains('Notes'),
        reason: '$mode lists the library notes',
      );
    }
  });

  testWidgets('a caret moved into a written link opens no panel', (
    tester,
  ) async {
    // The panel is for a link being typed: Down onto a line with a finished
    // link lands the caret inside it, and that is a caret move, not typing.
    const text = 'Intro text\nSee [[Project plan]]\nThe end\n';
    final buffer = SourceBuffer.fromText(text);
    final suggester = FakeWikilinkSuggester(
      notes: const <NoteSuggestion>[
        NoteSuggestion(
          name: 'Project plan',
          folder: '',
          target: 'Project plan',
        ),
      ],
    );
    final state = await pump(tester, buffer, suggester);
    // `Intro tex|t`, straight above `See [[Pro|ject plan]]`. The pumps
    // between placing and moving are what the caret's rectangle is measured
    // between.
    state.placeCaret(9);
    await tester.pump();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pump();

    expect(
      state.selection.extent,
      buffer.offsetOfLine(1) + 9,
      reason: 'Down landed inside the link, after `[[Pro`',
    );
    expect(state.isSuggesterShown, isFalse);
    expect(suggester.noteQueries, isEmpty, reason: 'nothing was asked');

    // The keys a panel would take stay the note's: Down goes on to the next
    // line.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(buffer.lineOf(state.selection.extent), 2);

    // A caret put there by hand is no typing either, and Enter there does
    // what it does in a note with no panel — never a completion.
    final inLink = buffer.offsetOfLine(1) + 9;
    state.placeCaret(inLink);
    await tester.pump();
    expect(state.isSuggesterShown, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    final written = buffer.text;
    expect(
      written,
      await withNoPanel(tester, text, inLink, LogicalKeyboardKey.enter),
    );
  });

  testWidgets('a caret moved out of the link closes the panel', (tester) async {
    // And moving back in does not open it again: the panel is for typing.
    final buffer = SourceBuffer.fromText('See ');
    final suggester = _library();
    final state = await pump(tester, buffer, suggester);

    await type(tester, 'See [[No');
    expect(state.isSuggesterShown, isTrue);
    state.placeCaret(2);
    await tester.pump();
    expect(state.isSuggesterShown, isFalse);
    state.placeCaret(buffer.length);
    await tester.pump();
    expect(state.isSuggesterShown, isFalse);
  });

  group('rows of an earlier query', () {
    /// Presses Enter the way the desktop embedders do (see `FakeEmbedder`):
    /// the key goes to the note first, and only a key it left alone becomes
    /// a line break typed at the caret.
    Future<void> enter(
      WidgetTester tester,
      SourceBuffer buffer,
      MarkdownSourceViewState state,
    ) async {
      if (await tester.sendKeyEvent(LogicalKeyboardKey.enter)) return;
      final caret = state.selection.extent;
      await type(
        tester,
        buffer.text.replaceRange(caret, caret, '\n'),
        caret: caret + 1,
      );
    }

    testWidgets('Tab after a # does not complete a note listed before it', (
      tester,
    ) async {
      final buffer = SourceBuffer.fromText('');
      final suggester = _library();
      await pump(tester, buffer, suggester);
      await type(tester, '[[Note');
      expect(panel(tester).entries.first, isA<NoteSuggestion>());

      // The headings are still on their way: the note rows stay drawn.
      suggester.holding = true;
      await type(tester, '[[Notes#');
      expect(panel(tester).entries.first, isA<NoteSuggestion>());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final written = buffer.text;
      suggester.release();
      await tester.pump();

      expect(
        written,
        await withNoPanel(tester, '[[Notes#', 8, LogicalKeyboardKey.tab),
        reason: "Tab is the note's, as with no panel",
      );
    });

    testWidgets("Enter in another note's link writes none of the last "
        "note's headings", (tester) async {
      final buffer = SourceBuffer.fromText('');
      final suggester = _library();
      final state = await pump(tester, buffer, suggester);
      await type(tester, '[[Notes#');
      expect(panel(tester).entries.first, isA<HeadingSuggestion>());

      suggester.holding = true;
      await type(tester, '[[Meeting notes#');
      await enter(tester, buffer, state);
      suggester.release();
      await tester.pump();

      expect(buffer.text, '[[Meeting notes#\n', reason: 'a line break');
    });

    testWidgets('Enter after the # is deleted is a line break again', (
      tester,
    ) async {
      final buffer = SourceBuffer.fromText('');
      final suggester = _library();
      final state = await pump(tester, buffer, suggester);
      await type(tester, '[[Notes#');
      expect(panel(tester).entries.first, isA<HeadingSuggestion>());

      suggester.holding = true;
      await type(tester, '[[Notes');
      await enter(tester, buffer, state);
      suggester.release();
      await tester.pump();

      expect(buffer.text, '[[Notes\n', reason: 'the key was not swallowed');
    });

    testWidgets('once the answer lands, its rows complete', (tester) async {
      final buffer = SourceBuffer.fromText('');
      final suggester = _library();
      await pump(tester, buffer, suggester);
      await type(tester, '[[Note');

      suggester.holding = true;
      await type(tester, '[[Notes#');
      suggester.release();
      await tester.pump();
      await tester.pump();
      expect(panel(tester).entries.first, isA<HeadingSuggestion>());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(buffer.text, '[[Notes#Links]]');
    });
  });

  group('completing inside a written link', () {
    /// Puts the caret at [at] in [before], types [typed] there, and presses
    /// [key] on the row the panel picked: the note that is left.
    Future<(String, int)> complete(
      WidgetTester tester,
      String before,
      int at,
      String typed,
      LogicalKeyboardKey key,
    ) async {
      final buffer = SourceBuffer.fromText(before);
      final state = await pump(tester, buffer, _library());
      state.placeCaret(at);
      await tester.pump();
      await type(
        tester,
        before.replaceRange(at, at, typed),
        caret: at + typed.length,
      );
      expect(state.isSuggesterShown, isTrue, reason: 'typing opened it');
      expect(panel(tester).entries, isNotEmpty);
      await tester.sendKeyEvent(key);
      await tester.pump();
      expect(state.isSuggesterShown, isFalse);
      return (buffer.text, state.selection.extent);
    }

    testWidgets('replaces the rest of the target, not a second closer', (
      tester,
    ) async {
      // `See [[Mee|ng notes]] now`: the target runs on to the `]]`.
      final (text, caret) = await complete(
        tester,
        'See [[Meng notes]] now',
        8,
        'e',
        LogicalKeyboardKey.enter,
      );
      expect(text, 'See [[Meeting notes]] now');
      expect(caret, 'See [[Meeting notes]]'.length, reason: 'past the `]]`');
    });

    testWidgets('keeps the heading and the alias after the target', (
      tester,
    ) async {
      final (text, caret) = await complete(
        tester,
        '[[Ma#Intro|shown]]',
        4,
        'r',
        LogicalKeyboardKey.tab,
      );
      expect(text, '[[Markdown basics#Intro|shown]]');
      expect(caret, text.length, reason: 'past the link');
    });

    testWidgets('replaces the rest of a heading', (tester) async {
      final (text, caret) = await complete(
        tester,
        '[[Notes#Lnks]] and on',
        9,
        'i',
        LogicalKeyboardKey.enter,
      );
      expect(text, '[[Notes#Links]] and on');
      expect(caret, '[[Notes#Links]]'.length);
    });

    testWidgets('leaves what follows a link with no closer alone', (
      tester,
    ) async {
      // The `]]` further on is the next link's: this one was never closed,
      // so the completion closes it and eats nothing.
      final (text, _) = await complete(
        tester,
        '[[Me and [[Notes]]',
        4,
        'e',
        LogicalKeyboardKey.tab,
      );
      expect(text, '[[Meeting notes]] and [[Notes]]');
    });
  });

  group('a note the panel was not opened on', () {
    /// Pumps the view over [buffer] with [suggester] and hands back its state.
    /// [focus] taps it, so the platform's own text path is the one a keystroke
    /// takes: only the first pump of a test needs it, the shell rebuilding the
    /// view leaving the focus — and the keyboard — where they were.
    Future<MarkdownSourceViewState> view(
      WidgetTester tester,
      SourceBuffer buffer,
      FakeWikilinkSuggester suggester, {
      bool focus = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownSourceView(
              buffer: buffer,
              theme: _theme,
              showLineNumbers: false,
              wikilinkSuggester: suggester,
            ),
          ),
        ),
      );
      await tester.pump();
      if (focus) {
        await tester.tap(find.byType(MarkdownSourceView));
        await tester.pump();
      }
      return tester.state<MarkdownSourceViewState>(
        find.byType(MarkdownSourceView),
      );
    }

    testWidgets('a swapped buffer closes the panel', (tester) async {
      // The shell loads another note into the same view — the note view's
      // own key keeps the state — and the panel held offsets into the text
      // that went: the key after it wrote a completion into the new note.
      final first = SourceBuffer.fromText('');
      final state = await view(tester, first, _library(), focus: true);
      await type(tester, '[[Note');
      expect(state.isSuggesterShown, isTrue);
      expect(panel(tester).entries, isNotEmpty, reason: 'a key would write');

      final second = SourceBuffer.fromText('Another note\n');
      final reopened = await view(tester, second, _library());
      expect(
        identical(state, reopened),
        isTrue,
        reason: 'one view, another note: the panel held the old offsets',
      );
      expect(state.isSuggesterShown, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(second.text, 'Another note\n', reason: 'the key went to the note');
    });

    testWidgets('a revision made behind the view closes the panel', (
      tester,
    ) async {
      final buffer = SourceBuffer.fromText('');
      final state = await view(tester, buffer, _library(), focus: true);
      await type(tester, '[[Note');
      expect(state.isSuggesterShown, isTrue);

      // An edit this view did not make — a command, a revert — read on the
      // frame the shell rebuilds it in: the link the panel stood in is not
      // there any more.
      buffer.replaceRange(0, 0, '# Other\n');
      final reopened = await view(tester, buffer, _library());
      expect(identical(state, reopened), isTrue);
      expect(state.isSuggesterShown, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        buffer.text,
        isNot(contains('Notes]]')),
        reason: 'the key went to the note',
      );
    });
  });

  group('the note replaced under the panel', () {
    Future<MarkdownSourceViewState> open(
      WidgetTester tester,
      SourceBuffer buffer,
    ) async {
      final state = await pump(tester, buffer, _library());
      await type(tester, '[[Note');
      expect(state.isSuggesterShown, isTrue);
      expect(panel(tester).entries, isNotEmpty, reason: 'a key would write');
      return state;
    }

    testWidgets('replacing the whole text closes the panel', (tester) async {
      // The disk or the WYSIWYG says the note is another text: the panel held
      // offsets into the text that went, and the key after it wrote a
      // completion into the new one (#494).
      final buffer = SourceBuffer.fromText('');
      final state = await open(tester, buffer);

      state.replaceAll('Another note that is longer than the link was\n');
      await tester.pump();
      expect(state.isSuggesterShown, isFalse);
      expect(find.byType(WikilinkPanel), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        buffer.text,
        isNot(contains(']]')),
        reason: 'the key went to the note',
      );
    });

    testWidgets('an undo follows the text it left, or closes', (tester) async {
      // An undo is an edit no keystroke made: the link the panel stood in is
      // gone, and so must the panel be.
      final buffer = SourceBuffer.fromText('');
      final state = await open(tester, buffer);

      expect(state.undo(), isTrue);
      await tester.pump();
      expect(buffer.text, isNot(contains('[[')), reason: 'the link is undone');
      expect(state.isSuggesterShown, isFalse);
    });
  });

  group('a link typed in code', () {
    /// Types [text] with the caret at [caret] and holds that the library was
    /// not asked and the key that follows writes no link: nothing but the
    /// code's own text is left.
    Future<void> typedInCode(
      WidgetTester tester,
      String text,
      int caret,
    ) async {
      final buffer = SourceBuffer.fromText('');
      final suggester = _library();
      final state = await pump(tester, buffer, suggester);

      await type(tester, text, caret: caret);

      expect(suggester.noteQueries, isEmpty, reason: 'the library was asked');
      expect(state.isSuggesterShown, isFalse);
      expect(find.byType(WikilinkPanel), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        buffer.text,
        isNot(contains(']]')),
        reason: 'the key went to the code',
      );
      expect(buffer.text, isNot(contains('Notes')), reason: 'no note name');
    }

    testWidgets('a fenced block lists nothing', (tester) async {
      // A bash fence, the caret after the `[[Note` typed in it: the panel
      // listed the library and Enter wrote a note name and its `]]` into the
      // code.
      await typedInCode(tester, '```bash\n[[Note\n```\n', 14);
    });

    testWidgets('inline code lists nothing', (tester) async {
      await typedInCode(tester, 'text `[[Note` more\n', 12);
    });

    testWidgets('display maths lists nothing', (tester) async {
      await typedInCode(tester, '\$\$\n[[Note\n\$\$\n', 9);
    });

    testWidgets('inline maths lists nothing', (tester) async {
      await typedInCode(tester, 'x \$[[Note\$ y\n', 9);
    });

    testWidgets('a note whose colours are unread opens none, then does', (
      tester,
    ) async {
      // A long note is read in the background: until it lands its lines have
      // no tokens, which is "nobody has read it yet" and not "no code here" —
      // the fence the caret is in was answered as prose (#494).
      MarkdownSourceViewState.backgroundLines = 2;
      addTearDown(() => MarkdownSourceViewState.backgroundLines = 50000);
      // Long enough for the reading to be in the background.
      final buffer = SourceBuffer.fromText('\n\n\n');
      final suggester = _library();
      final state = await pump(tester, buffer, suggester);

      await type(tester, '```bash\n[[Note\n```\n', caret: 14);
      expect(state.tokensOf(1), isEmpty, reason: 'nobody has read the line');
      expect(suggester.noteQueries, isEmpty, reason: 'the library was asked');
      expect(state.isSuggesterShown, isFalse);

      for (var round = 0; round < 50 && state.tokensOf(1).isEmpty; round++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(state.tokensOf(1), isNotEmpty, reason: 'the reading landed');
      // Read, the fence is code: still none there.
      await type(tester, '```bash\n[[Notes\n```\n', caret: 15);
      expect(suggester.noteQueries, isEmpty);
      expect(state.isSuggesterShown, isFalse);

      // And a link in prose is the writer's once the line is read.
      await type(tester, '[[Note\n', caret: 6);
      expect(state.isSuggesterShown, isTrue);
      expect(suggester.noteQueries, ['Note']);
    });

    testWidgets('a link after a span is prose still', (tester) async {
      // The caret past a span's last delimiter is outside it, and so is the
      // `[[` the link was read from: the ordinary panel is the writer's.
      final buffer = SourceBuffer.fromText('');
      final suggester = _library();
      final state = await pump(tester, buffer, suggester);

      await type(tester, 'a `x` [[Note\n', caret: 12);

      expect(state.isSuggesterShown, isTrue);
      expect(suggester.noteQueries, ['Note']);
    });
  });

  testWidgets('a surface with no library draws no panel', (tester) async {
    final buffer = SourceBuffer.fromText('');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(
            buffer: buffer,
            theme: _theme,
            selection: const SelectionModel.at(0),
            showLineNumbers: false,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(MarkdownSourceView));
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '[[',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(WikilinkPanel), findsNothing);
  });
}
