// #842: "Links to this note" — a collapsible section under the open note, the
// dock's pane, and the same list in a phone's sheet: the notes that link here,
// each with the line it says the link on, a tap opening the note that holds
// it. The rows are read as they are drawn.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/mentions.dart';
import 'package:niman/src/ui/dock/links_dock_pane.dart';
import 'package:niman/src/ui/links_to_note_section.dart';
import 'package:niman/src/ui/note_view_handle.dart';

import '../fakes/fake_link_source.dart';

final class _Note implements NoteViewHandle {
  new(this.notePath);

  @override
  final String notePath;

  @override
  String get currentText => '';

  @override
  final ValueNotifier<List<OutlineEntry>> outline = ValueNotifier(const []);

  @override
  SpellReview? spellReview;

  @override
  void jumpToHeading(int line) {}

  @override
  bool get canInsert => true;

  @override
  String get selectedText => '';

  @override
  void insertAtCaret(String markdown) {}

  @override
  void insertColumns() {}

  @override
  void convertListToMindMap() {}

  @override
  PastedText? pasteText(String text) => null;

  @override
  void replacePasted(PastedText pasted, String text) {}

  @override
  void setNoteKind(String? type) {}

  @override
  void applyKindEdit(String newText) {}

  @override
  void openFind({bool replace = false}) {}

  @override
  void takeFocus() {}

  @override
  Future<String?> resolveEmbed(String target) async => null;
}

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(alignment: Alignment.bottomCenter, child: child),
  ),
);

FakeLinkSource _library() {
  final links = FakeLinkSource(notes: ['Newton.md']);
  links.referrers['Newton.md'] = ['Laws/Three laws.md', 'Optics.md', 'Pic.md'];
  links.mentions['Laws/Three laws.md -> Newton.md'] = const Mention(
    context: 'Proposed by [[Newton]] in 1687',
    embed: false,
  );
  links.mentions['Optics.md -> Newton.md'] = const Mention(
    context: 'See also [[Newton]].',
    embed: false,
  );
  links.mentions['Pic.md -> Newton.md'] = const Mention(
    context: '![[Newton]]',
    embed: true,
  );
  return links;
}

void main() {
  group('the section under the note', () {
    Future<List<String>> pumpSection(
      WidgetTester tester,
      FakeLinkSource? links, {
      String? path = 'Newton.md',
    }) async {
      final opened = <String>[];
      await tester.pumpWidget(
        _app(
          LinksToNoteSection(source: links, path: path, onOpenNote: opened.add),
        ),
      );
      await tester.pump();
      return opened;
    }

    testWidgets('is a header with the count, closed until asked', (
      tester,
    ) async {
      final links = _library();
      await pumpSection(tester, links);

      expect(find.text('Links to this note'), findsOneWidget);
      expect(find.byKey(const Key('links-to-note-count')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('links-to-note-count'))).data,
        '3',
      );
      expect(find.byKey(const Key('links-to-note')), findsNothing);
      expect(links.mentionReads, isEmpty, reason: 'nothing is read while shut');
    });

    testWidgets('opens onto the notes, each with the line of its link', (
      tester,
    ) async {
      final links = _library();
      await pumpSection(tester, links);

      await tester.tap(find.byKey(const Key('links-to-note-header')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Three laws'), findsOneWidget);
      expect(find.text('Laws'), findsOneWidget, reason: 'its folder, dimmed');
      expect(find.text('Optics'), findsOneWidget);
      expect(find.text('Proposed by [[Newton]] in 1687'), findsOneWidget);
      expect(find.text('See also [[Newton]].'), findsOneWidget);
      expect(find.text('embed'), findsOneWidget, reason: 'only Pic embeds');
      expect(
        find.byKey(const Key('links-to-note-embed-Pic.md')),
        findsOneWidget,
      );
    });

    testWidgets('a tap on a row opens the note that holds the link', (
      tester,
    ) async {
      final links = _library();
      final opened = await pumpSection(tester, links);
      await tester.tap(find.byKey(const Key('links-to-note-header')));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('links-to-note-row-Optics.md')));
      await tester.pump();

      expect(opened, ['Optics.md']);
    });

    testWidgets('a note nobody links to says so when opened', (tester) async {
      final links = FakeLinkSource(notes: ['Lonely.md']);
      await pumpSection(tester, links, path: 'Lonely.md');
      expect(
        tester.widget<Text>(find.byKey(const Key('links-to-note-count'))).data,
        '0',
      );

      await tester.tap(find.byKey(const Key('links-to-note-header')));
      await tester.pump();

      expect(find.text('No note links here yet'), findsOneWidget);
    });

    testWidgets('closes again, and the rows go', (tester) async {
      await pumpSection(tester, _library());
      await tester.tap(find.byKey(const Key('links-to-note-header')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('links-to-note')), findsOneWidget);

      await tester.tap(find.byKey(const Key('links-to-note-header')));
      await tester.pump();

      expect(find.byKey(const Key('links-to-note')), findsNothing);
    });

    testWidgets('shows nothing without a library or for a note outside one', (
      tester,
    ) async {
      await pumpSection(tester, null);
      expect(find.byKey(const Key('links-to-note-section')), findsNothing);

      await pumpSection(tester, _library(), path: null);
      expect(find.byKey(const Key('links-to-note-section')), findsNothing);
    });

    testWidgets('follows the library when its index moves', (tester) async {
      final links = _library();
      await pumpSection(tester, links);
      expect(
        tester.widget<Text>(find.byKey(const Key('links-to-note-count'))).data,
        '3',
      );

      links.referrers['Newton.md'] = ['Optics.md'];
      links.announceChange();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(
        tester.widget<Text>(find.byKey(const Key('links-to-note-count'))).data,
        '1',
      );
    });

    testWidgets('a referrer that changed says its new line after a reload', (
      tester,
    ) async {
      final links = _library();
      await pumpSection(tester, links);
      await tester.tap(find.byKey(const Key('links-to-note-header')));
      await tester.pump();
      await tester.pump();
      expect(find.text('See also [[Newton]].'), findsOneWidget);

      links.mentions['Optics.md -> Newton.md'] = const Mention(
        context: 'Now: [[Newton]] and more.',
        embed: false,
      );
      links.revisions['Optics.md'] = 1;
      links.announceChange();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump();

      expect(find.text('Now: [[Newton]] and more.'), findsOneWidget);
      expect(find.text('See also [[Newton]].'), findsNothing);
    });

    testWidgets('past a page, "Show more" reads the next one, kept on reload', (
      tester,
    ) async {
      final links = FakeLinkSource(notes: ['Hub.md'])..referrersPage = 2;
      links.referrers['Hub.md'] = ['a.md', 'b.md', 'c.md'];
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpSection(tester, links, path: 'Hub.md');
      await tester.tap(find.byKey(const Key('links-to-note-header')));
      await tester.pump();
      await tester.pump();
      expect(find.text('c'), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('links-to-note-count'))).data,
        '2+',
      );

      await tester.tap(find.byKey(const Key('links-to-note-more')));
      await tester.pump();
      await tester.pump();

      expect(find.text('c'), findsOneWidget);
      expect(find.byKey(const Key('links-to-note-more')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('links-to-note-count'))).data,
        '3',
      );

      links.announceChange();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump();

      expect(find.text('c'), findsOneWidget, reason: 'both pages read again');
    });

    testWidgets('follows the note it is for', (tester) async {
      final links = _library();
      links.referrers['Optics.md'] = ['Newton.md'];
      final opened = <String>[];
      Widget section(String path) => _app(
        LinksToNoteSection(source: links, path: path, onOpenNote: opened.add),
      );
      await tester.pumpWidget(section('Newton.md'));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const Key('links-to-note-count'))).data,
        '3',
      );

      await tester.pumpWidget(section('Optics.md'));
      await tester.pump();

      expect(
        tester.widget<Text>(find.byKey(const Key('links-to-note-count'))).data,
        '1',
      );
    });

    testWidgets('reads only the rows it draws, and each once', (tester) async {
      final links = FakeLinkSource(notes: ['Hub.md']);
      links.referrers['Hub.md'] = [for (var i = 0; i < 300; i++) 'n$i.md'];
      await pumpSection(tester, links, path: 'Hub.md');
      await tester.tap(find.byKey(const Key('links-to-note-header')));
      await tester.pump();
      await tester.pump();

      expect(links.mentionReads, isNotEmpty);
      expect(
        links.mentionReads.length,
        lessThan(30),
        reason: 'a screenful of 300, not the 300',
      );
      final first = links.mentionReads.length;

      await tester.pump(const Duration(milliseconds: 50));
      expect(links.mentionReads.length, first, reason: 'drawn again, not read');
    });

    testWidgets('a row waits for its line; the name is there at once', (
      tester,
    ) async {
      final links = _library()..mentionGate = Completer<void>();
      await pumpSection(tester, links);
      await tester.tap(find.byKey(const Key('links-to-note-header')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Optics'), findsOneWidget);
      expect(find.text('See also [[Newton]].'), findsNothing);

      links.mentionGate!.complete();
      await tester.pump();
      await tester.pump();

      expect(find.text('See also [[Newton]].'), findsOneWidget);
    });

    testWidgets('a long line is cut to two rows of the list', (tester) async {
      final links = FakeLinkSource(notes: ['Newton.md']);
      links.referrers['Newton.md'] = ['Long.md'];
      links.mentions['Long.md -> Newton.md'] = Mention(
        context: List.filled(40, 'a very long context word').join(' '),
        embed: false,
      );
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpSection(tester, links);
      await tester.tap(find.byKey(const Key('links-to-note-header')));
      await tester.pump();
      await tester.pump();

      final text = tester.widget<Text>(
        find.byKey(const Key('links-to-note-context-Long.md')),
      );
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull, reason: 'no overflow');
    });
  });

  group("the dock's pane", () {
    Future<List<String>> pumpPane(
      WidgetTester tester,
      FakeLinkSource links, {
      NoteViewHandle? note,
    }) async {
      final opened = <String>[];
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 400,
            child: LinksDockPane(
              note: note ?? _Note('/lib/Newton.md'),
              links: Future.value(links),
              libraryRoot: '/lib',
              onOpenNote: opened.add,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return opened;
    }

    testWidgets('lists the notes that link to the note beside it', (
      tester,
    ) async {
      final links = _library();
      final opened = await pumpPane(tester, links);

      expect(find.text('Three laws'), findsOneWidget);
      expect(find.text('Proposed by [[Newton]] in 1687'), findsOneWidget);
      expect(find.text('embed'), findsOneWidget);

      await tester.tap(find.byKey(const Key('links-to-note-row-Pic.md')));
      await tester.pump();
      expect(opened, ['Pic.md']);
    });

    testWidgets("speaks of the note's path in the library", (tester) async {
      final links = _library();
      await pumpPane(tester, links, note: _Note('/lib/Optics.md'));

      expect(find.byKey(const Key('links-to-note')), findsNothing);
      expect(find.text('No note links here yet'), findsOneWidget);
    });

    testWidgets('a note outside the library has no list', (tester) async {
      final links = _library();
      await pumpPane(tester, links, note: _Note('/elsewhere/Newton.md'));

      expect(find.byKey(const Key('links-to-note')), findsNothing);
      expect(find.text('No note links here yet'), findsNothing);
    });

    testWidgets('no note beside it, nothing to list', (tester) async {
      await tester.pumpWidget(
        _app(
          LinksDockPane(
            note: null,
            links: Future.value(_library()),
            libraryRoot: '/lib',
            onOpenNote: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('links-to-note')), findsNothing);
    });
  });
}
