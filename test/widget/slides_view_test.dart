// #534: the slides kind's view — the slide on screen, its notes, the
// thumbnail row and the keys on a wide window, the swipe on a phone.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/frontmatter/note_kind.dart';
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
}
