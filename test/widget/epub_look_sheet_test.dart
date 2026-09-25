// The sheet that sets how the books look (#280): every pick is kept in the
// library's settings and put on screen at once, where an open book reads
// it; the text size shows on the book while the slider moves.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/ui/epub_look_sheet.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() => session = FakeLibrarySession());
  tearDown(EpubLooks.reset);

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showEpubLookSheet(context, session: session),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('epub-look-sheet')), findsOneWidget);
  }

  Future<void> pick(WidgetTester tester, Key dropdown, String label) async {
    await tester.tap(find.byKey(dropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('a face picked is kept and shown', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('epub-look-font-serif')));
    await tester.pumpAndSettle();
    expect((await session.epubLook).font, EpubFont.serif);
    expect(EpubLooks.look.font, EpubFont.serif);
  });

  testWidgets('a theme and a brightness picked are kept and shown', (
    tester,
  ) async {
    await open(tester);
    await pick(
      tester,
      const Key('epub-look-theme'),
      AppStrings.themePaletteGruvbox,
    );
    expect((await session.epubLook).theme, AppPalette.gruvbox.id);
    expect(EpubLooks.theme, const BuiltinAppTheme(AppPalette.gruvbox));

    await pick(
      tester,
      const Key('epub-look-brightness'),
      AppStrings.themeBrightnessNight,
    );
    expect((await session.epubLook).brightness, AppBrightness.night);

    // Back to the app's: nothing of the books' own is left.
    await pick(tester, const Key('epub-look-theme'), AppStrings.epubSameAsApp);
    expect((await session.epubLook).theme, isNull);
    expect(EpubLooks.theme, isNull);
  });

  testWidgets('the text size shows as it moves, and is kept let go', (
    tester,
  ) async {
    await open(tester);
    final slider = find.byKey(const Key('epub-look-size'));
    final gesture = await tester.startGesture(tester.getCenter(slider));
    await gesture.moveBy(Offset(tester.getSize(slider).width / 4, 0));
    await tester.pump();
    final moving = EpubLooks.look.textScale;
    expect(moving, greaterThan(1));
    expect((await session.epubLook).textScale, 1, reason: 'not kept yet');
    await gesture.up();
    await tester.pumpAndSettle();
    expect((await session.epubLook).textScale, moving);
  });

  testWidgets("a custom theme gone since it was picked reads as the app's", (
    tester,
  ) async {
    await session.setEpubLook(const EpubLook(theme: 'custom:gone'));
    expect(EpubLooks.theme, isNull);
    await open(tester);
    expect(find.text(AppStrings.epubSameAsApp), findsNWidgets(2));
  });
}
