// The wikilink panel's own words (#475): the caption, the empty words, the
// book note and the keys' footer are labels, so they follow the language the
// app speaks rather than the English written into the widget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/markdown/render/wikilink_panel.dart';

/// Everything the panel wrote, as one string.
String _words(WidgetTester tester) => <String>[
  for (final text in tester.widgetList<Text>(
    find.descendant(
      of: find.byType(WikilinkPanel),
      matching: find.byType(Text),
    ),
  ))
    text.data ?? text.textSpan?.toPlainText() ?? '',
].join(' | ');

Future<void> _pump(WidgetTester tester, WikilinkPanel panel) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: panel),
        ),
      ),
    );

void main() {
  setUp(AppLanguages.reset);
  tearDown(AppLanguages.reset);

  testWidgets('the caption and the footer are the app language', (
    tester,
  ) async {
    AppLanguages.choice = AppLanguage.italian;
    await _pump(
      tester,
      const WikilinkPanel(
        kind: WikilinkPanelKind.headings,
        entries: <SuggestEntry>[HeadingSuggestion('Introduzione')],
        selected: 0,
        query: 'Int',
        named: 'Nota',
      ),
    );

    final said = _words(tester);
    expect(said, contains('Titoli in'));
    expect(said, contains('sposta'));
    expect(said, contains('o'));
    expect(said, contains('inserisci'));
    expect(said, contains('chiudi'));
    expect(said, isNot(contains('Headings in')));
    expect(said, isNot(contains('insert')));
  });

  testWidgets('the empty panel names what it looked for, in that language', (
    tester,
  ) async {
    AppLanguages.choice = AppLanguage.italian;
    await _pump(
      tester,
      const WikilinkPanel(
        kind: WikilinkPanelKind.notes,
        entries: <SuggestEntry>[],
        selected: 0,
        query: 'xyz',
      ),
    );

    final said = _words(tester);
    expect(said, contains('Nessuna nota corrisponde a “xyz”'));
    expect(said, contains('niente nella libreria ha quel nome o alias'));
    expect(said, isNot(contains('matches')));
  });

  testWidgets('a book panel says its own words in that language', (
    tester,
  ) async {
    AppLanguages.choice = AppLanguage.italian;
    await _pump(
      tester,
      const WikilinkPanel(
        kind: WikilinkPanelKind.book,
        entries: <SuggestEntry>[
          BookSuggestion(form: 'page=', hint: 'digita un numero'),
        ],
        selected: 0,
        query: '',
      ),
    );

    final said = _words(tester);
    expect(said, contains('Posizioni in'));
    expect(said, contains('questa nota'));
    expect(said, contains('La pagina si sceglie'));
    expect(said, isNot(contains('Places in')));
    expect(said, isNot(contains('this note')));
  });

  // The pill a row found through an alias wears. German is one of the
  // languages that writes the word differently from English, so the label
  // can be told apart from what the panel used to write into itself.
  testWidgets('the alias pill is the app language', (tester) async {
    AppLanguages.choice = AppLanguage.german;
    await _pump(
      tester,
      const WikilinkPanel(
        kind: WikilinkPanelKind.notes,
        entries: <SuggestEntry>[
          NoteSuggestion(
            name: 'Ada',
            folder: '',
            target: 'Ada',
            alias: 'Ada Lovelace',
          ),
        ],
        selected: 0,
        query: 'Lovel',
      ),
    );

    final said = _words(tester);
    expect(said, contains('Alias Ada Lovelace'));
    expect(said, isNot(contains('alias Ada Lovelace')));
  });
}
