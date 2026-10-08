// #534: the slides kind's view — the slide on screen, its notes, the
// thumbnail row and the keys on a wide window, the swipe on a phone.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/kinds/slides/slide_place.dart';
import 'package:niman/src/ui/kinds/slides/slides_view.dart';
import 'package:niman/src/ui/strings.dart';

final class _Host implements NoteKindHost {
  new(this.notePath, {this.showMarkdown});

  @override
  final String notePath;

  @override
  final VoidCallback? showMarkdown;

  @override
  String get text => '';

  @override
  void applyEdit(String newText) {}

  @override
  String? get libraryRoot => null;

  @override
  String get attachmentsFolder => '';

  @override
  LinkType get linkType => LinkType.wikilink;

  @override
  Future<String?> resolveEmbed(String target) async => null;

  @override
  void openLink(BuildContext context, String href) {}

  @override
  void openWikiLink(BuildContext context, String inner) {}
}

const String _deck =
    '---\ntype: slides\n---\n\n# Alpha\n\n---\n\n## Beta\n\nNote: say beta\n';

Finder _text(String text) => find.textContaining(text, findRichText: true);

Future<void> _show(WidgetTester tester, Widget view, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: view)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('wide: the keys and the thumbnails move the slide', (
    tester,
  ) async {
    final host = _Host('wide.md');
    await _show(
      tester,
      SlidesNoteView(text: _deck, host: host),
      const Size(1200, 800),
    );
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byKey(const Key('speaker-notes')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('say beta'), findsOneWidget);
    expect(slidePlaceOf('wide.md').value, 1);

    await tester.tap(find.byKey(const Key('slide-thumb-0')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(_text('Alpha'), findsWidgets);
  });

  testWidgets('narrow: a swipe moves the slide; Markdown leaves the view', (
    tester,
  ) async {
    var markdown = 0;
    final host = _Host('narrow.md', showMarkdown: () => markdown++);
    await _show(
      tester,
      SlidesNoteView(text: _deck, host: host),
      const Size(390, 844),
    );
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.fling(
      find.byKey(const Key('slides-pages')),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('say beta'), findsOneWidget);

    await tester.tap(find.text(AppStrings.slidesMarkdown));
    expect(markdown, 1);
  });

  testWidgets('an edit that removes the slide on screen falls back', (
    tester,
  ) async {
    final host = _Host('edit.md');
    slidePlaceOf('edit.md').value = 1;
    await _show(
      tester,
      SlidesNoteView(text: _deck, host: host),
      const Size(1200, 800),
    );
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlidesNoteView(text: '# Only', host: host),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets("a renamed note shows the new path's slide, swipe and count", (
    tester,
  ) async {
    slidePlaceOf('old.md').value = 1;
    await _show(
      tester,
      SlidesNoteView(text: _deck, host: _Host('old.md')),
      const Size(390, 844),
    );
    expect(find.text('say beta'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlidesNoteView(text: _deck, host: _Host('new.md')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(_text('Alpha'), findsWidgets);
    expect(_text('Beta'), findsNothing);
  });

  testWidgets('a pane shorter than the notes lays out, the slide at nothing', (
    tester,
  ) async {
    slidePlaceOf('short.md').value = 1;
    await _show(
      tester,
      SlidesNoteView(text: _deck, host: _Host('short.md')),
      const Size(1200, 220),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('2 / 2'), findsOneWidget);
  });

  presentingTests();
}

void presentingTests() {
  testWidgets('F5 presents from the slide on screen; Esc gives it back', (
    tester,
  ) async {
    final host = _Host('present.md');
    await _show(
      tester,
      SlidesNoteView(text: _deck, host: host),
      const Size(1200, 800),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('slides-present')), findsOneWidget);
    expect(find.byKey(const Key('speaker-notes')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(slidePlaceOf('present.md').value, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('slides-present')), findsNothing);
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('B blacks the slide alone out, held or not, and only there', (
    tester,
  ) async {
    await _show(
      tester,
      SlidesNoteView(text: _deck, host: _Host('black.md')),
      const Size(1200, 800),
    );
    const black = Key('slides-black');
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyB);
    await tester.pump();
    expect(find.byKey(black), findsOneWidget);

    // To the presenter view and back: the slide shows, not the black.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pump();
    expect(find.byKey(const Key('slides-present')), findsOneWidget);
    expect(find.byKey(black), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });

  testWidgets('down in the overview rings the slide under, row as wide as it', (
    tester,
  ) async {
    final deck = [for (var i = 1; i <= 10; i++) '# S$i'].join('\n\n---\n\n');
    await _show(
      tester,
      SlidesNoteView(text: deck, host: _Host('grid.md')),
      const Size(1920, 1080),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
    await tester.pump();
    final under = tester.getTopLeft(find.byKey(const Key('overview-slide-0')));
    final row = [
      for (var i = 1; i < 10; i++)
        if (tester.getTopLeft(find.byKey(Key('overview-slide-$i'))).dy ==
            under.dy)
          i,
    ];
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(slidePlaceOf('grid.md').value, row.length + 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });

  testWidgets('presenting runs on the key the user chose, not on F5', (
    tester,
  ) async {
    AppKeyMap.current.value = KeyMap.defaults.withBinding(
      AppCommand.presentSlides,
      const SingleActivator(LogicalKeyboardKey.f6),
    );
    addTearDown(() => AppKeyMap.current.value = KeyMap.defaults);
    await _show(
      tester,
      SlidesNoteView(text: _deck, host: _Host('chosen.md')),
      const Size(1200, 800),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('slides-present')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('slides-present')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });

  testWidgets('the presenter view shows the notes, the next slide, the time', (
    tester,
  ) async {
    final host = _Host('presenter.md');
    await _show(
      tester,
      SlidesNoteView(text: _deck, host: host),
      const Size(1280, 800),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('slides-presenter')), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('slides-presenter-next')));
    await tester.pump();
    expect(find.text('say beta'), findsOneWidget);

    await tester.tap(find.byKey(const Key('slides-slide-only')));
    await tester.pump();
    expect(find.byKey(const Key('slides-present')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
    await tester.pump();
    await tester.tap(find.byKey(const Key('overview-slide-0')));
    await tester.pump();
    expect(slidePlaceOf('presenter.md').value, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });
}
