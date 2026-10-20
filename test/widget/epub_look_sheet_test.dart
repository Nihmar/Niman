// The sheet that sets how the books look (#280): every pick is kept in the
// library's settings and put on screen at once, where an open book reads
// it; the text size shows on the book while the slider moves. Its choice
// menus are the app's own (#1119): compact on a pointer, a thumb's on a phone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/ui/epub_look_sheet.dart';
import 'package:niman/src/ui/pointer_menu.dart';
import 'package:niman/src/ui/pointer_menu_scope.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() => session = FakeLibrarySession());
  tearDown(EpubLooks.reset);

  Future<void> open(WidgetTester tester, {ThemeData? theme}) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        builder: (context, child) => PointerMenuScope(child: child!),
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

  group("the theme's menu", () {
    final rows = find.byWidgetPredicate((w) => w is PopupMenuItem<int>);

    Future<void> openMenu(WidgetTester tester, ThemeData theme) async {
      await open(tester, theme: theme);
      await tester.tap(find.byKey(const Key('epub-look-theme')));
      await tester.pumpAndSettle();
      expect(rows, findsNWidgets(AppPalette.values.length + 1));
    }

    /// The width every popup menu in the app takes: its widest row,
    /// rounded up to Material's 56 px steps and capped at five of them —
    /// not the drop-down's, as wide as the route that opened it.
    void expectPopupWidth(WidgetTester tester) {
      final width = tester.getSize(rows.first).width;
      expect(width % 56, 0, reason: 'a popup menu grows in 56 px steps');
      expect(width, lessThanOrEqualTo(5 * 56));
    }

    testWidgets("on a pointer, has the app's compact rows", (tester) async {
      await openMenu(tester, ThemeData(visualDensity: VisualDensity.compact));
      for (final row in rows.evaluate()) {
        expect(row.size!.height, pointerDenseItemHeight);
      }
      expectPopupWidth(tester);
      final body = Theme.of(tester.element(find.byType(Scaffold).first))
          .textTheme
          .bodyMedium!;
      final label = tester
          .widget<RichText>(
            find
                .descendant(of: rows.first, matching: find.byType(RichText))
                .first,
          )
          .text
          .style!;
      expect(label.fontSize, body.fontSize);
      expect(label.fontWeight, body.fontWeight);
    });

    testWidgets("on a phone, keeps a thumb's rows", (tester) async {
      await openMenu(tester, ThemeData(visualDensity: VisualDensity.standard));
      for (final row in rows.evaluate()) {
        expect(row.size!.height, kMinInteractiveDimension);
      }
      expectPopupWidth(tester);
    });

    testWidgets('checks the theme in use', (tester) async {
      await session.setEpubLook(EpubLook(theme: AppPalette.gruvbox.id));
      await openMenu(tester, ThemeData(visualDensity: VisualDensity.compact));
      final checked = find.descendant(
        of: rows,
        matching: find.byIcon(Icons.check),
      );
      expect(checked, findsOneWidget);
      expect(
        find.ancestor(
          of: checked,
          matching: find.widgetWithText(
            PopupMenuItem<int>,
            AppStrings.themePaletteGruvbox,
          ),
        ),
        findsOneWidget,
      );
    });
  });
}
