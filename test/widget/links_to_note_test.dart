// #842: "Links to this note" — the dock's pane, and the same list in a phone's
// sheet: the notes that link here, each with the line it says the link on, a
// tap opening the note that holds it. The rows are read as they are drawn.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/editor/task_items.dart';
import 'package:niman/src/editor/task_items_edit.dart';
import 'package:niman/src/links/mentions.dart';
import 'package:niman/src/ui/dock/links_dock_pane.dart';
import 'package:niman/src/ui/note_view_handle.dart';

import '../fakes/fake_link_source.dart';

final class _Note implements NoteViewHandle {
  new(this.notePath);

  @override
  final String notePath;

  @override
  String? get notePathInLibrary => notePath;

  @override
  String get currentText => '';

  @override
  Future<List<String>> currentTags() async => const [];

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
  void insertEisenhower() {}

  @override
  void convertListToMindMap() {}

  @override
  List<TaskItem> get taskItems => const [];

  @override
  TakenTaskItems? takeOutTaskItems(List<TaskItem> items) => null;

  @override
  bool putBackTaskItems(TakenTaskItems taken) => false;

  @override
  PastedText? pasteText(String text) => null;

  @override
  Future<bool> attachFiles(List<String> paths) async => false;

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
  group('the list', () {
    // The dock's pane and the phone's sheet draw the same list; the status
    // row's counter (#1296) has its own file.
    Future<List<String>> pumpList(
      WidgetTester tester,
      FakeLinkSource links, {
      String path = 'Newton.md',
    }) async {
      final opened = <String>[];
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 400,
            child: LinksDockPane(
              note: _Note('/lib/$path'),
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

    testWidgets('has the notes, each with the line of its link', (
      tester,
    ) async {
      final links = _library();
      await pumpList(tester, links);

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
      final opened = await pumpList(tester, links);

      await tester.tap(find.byKey(const Key('links-to-note-row-Optics.md')));
      await tester.pump();

      expect(opened, ['Optics.md']);
    });

    testWidgets('a note nobody links to says so', (tester) async {
      final links = FakeLinkSource(notes: ['Lonely.md']);
      await pumpList(tester, links, path: 'Lonely.md');

      expect(find.text('No note links here yet'), findsOneWidget);
    });

    testWidgets('follows the library when its index moves', (tester) async {
      final links = _library();
      await pumpList(tester, links);
      expect(find.text('Three laws'), findsOneWidget);

      links.referrers['Newton.md'] = ['Optics.md'];
      links.announceChange();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('Three laws'), findsNothing);
      expect(find.text('Optics'), findsOneWidget);
    });

    testWidgets('a referrer that changed says its new line after a reload', (
      tester,
    ) async {
      final links = _library();
      await pumpList(tester, links);
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
      await pumpList(tester, links, path: 'Hub.md');
      expect(find.text('c'), findsNothing);

      await tester.tap(find.byKey(const Key('links-to-note-more')));
      await tester.pump();
      await tester.pump();

      expect(find.text('c'), findsOneWidget);
      expect(find.byKey(const Key('links-to-note-more')), findsNothing);

      links.announceChange();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump();

      expect(find.text('c'), findsOneWidget, reason: 'both pages read again');
    });

    testWidgets('reads only the rows it draws, and each once', (tester) async {
      final links = FakeLinkSource(notes: ['Hub.md']);
      links.referrers['Hub.md'] = [for (var i = 0; i < 300; i++) 'n$i.md'];
      await pumpList(tester, links, path: 'Hub.md');

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
      await pumpList(tester, links);

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
      await pumpList(tester, links);

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
