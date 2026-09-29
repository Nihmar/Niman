// T-PP-22: the app's own window title bar — the sidebar toggle, the drag
// area, and the window buttons over the seam (the close button goes
// through it, so it meets the unsaved-edits guard like the system one).
//
// #169 rides the same bar: where those buttons ended up goes to the window
// seam, which is what Windows hit-tests for Snap Layouts.
//
// #498 rides it too: the sidebar tooltip names the key bound now, not the
// shipped one.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/title_bar.dart';

import '../fakes/fake_window_controller.dart';

Widget _host(
  FakeWindowController window, {
  bool sidebarVisible = true,
  VoidCallback? onToggle,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AppTitleBar(
        title: 'Niman — note.md',
        sidebarVisible: sidebarVisible,
        onToggleSidebar: onToggle ?? () {},
        window: window,
      ),
    ),
  );
}

void main() {
  testWidgets('shows the title and calls the sidebar toggle', (tester) async {
    var toggles = 0;
    final window = FakeWindowController();
    await tester.pumpWidget(_host(window, onToggle: () => toggles++));

    expect(find.text('Niman — note.md'), findsOne);
    await tester.tap(find.byKey(const Key('toggle-sidebar')));
    expect(toggles, 1);
  });

  testWidgets('the window buttons go through the controller', (tester) async {
    final window = FakeWindowController();
    await tester.pumpWidget(_host(window));

    await tester.tap(find.byKey(const Key('window-minimize')));
    await tester.tap(find.byKey(const Key('window-maximize')));
    await tester.tap(find.byKey(const Key('window-close')));
    await tester.pump();

    expect(window.minimizeCalls, 1);
    expect(window.maximizeCalls, 1);
    expect(window.closeCalls, 1);
  });

  testWidgets('the maximize button follows the window state', (tester) async {
    final window = FakeWindowController();
    await tester.pumpWidget(_host(window));
    expect(find.byIcon(Icons.crop_square), findsOne);

    window.maximized.value = true;
    await tester.pump();
    expect(find.byIcon(Icons.filter_none), findsOne);
  });

  testWidgets('the sidebar tooltip follows the keys bound now (#498)', (
    tester,
  ) async {
    final previous = AppKeyMap.current.value;
    addTearDown(() => AppKeyMap.current.value = previous);

    final window = FakeWindowController();
    await tester.pumpWidget(_host(window));
    expect(_sidebarTooltip(tester), contains('Ctrl+B'));

    // The key is remapped (#159): the tooltip has to move with it, or it
    // points at a key that does nothing.
    AppKeyMap.current.value = previous.withBinding(
      AppCommand.toggleSidebar,
      const SingleActivator(LogicalKeyboardKey.keyB, alt: true),
    );
    await tester.pump();
    expect(_sidebarTooltip(tester), contains('Alt+B'));
  });

  testWidgets('tells the window where the caption buttons are (#169)', (
    tester,
  ) async {
    // The report is in physical pixels; at ratio 1 it is the drawn
    // rectangle itself, so the two can be compared as they stand.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final window = FakeWindowController();
    await tester.pumpWidget(_host(window));
    await tester.pump();

    final reported = window.captionButtons.last;
    expect(reported.minimize, _drawnRect(tester, 'window-minimize'));
    expect(reported.maximize, _drawnRect(tester, 'window-maximize'));
    expect(reported.close, _drawnRect(tester, 'window-close'));
  });

  testWidgets('reports the buttons in physical pixels (#169)', (tester) async {
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final window = FakeWindowController();
    await tester.pumpWidget(_host(window));
    await tester.pump();

    expect(
      window.captionButtons.last.close,
      _scaled(_drawnRect(tester, 'window-close'), 2),
    );
  });

  testWidgets('the rectangles follow the bar as it lays out again (#169)', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);

    final window = FakeWindowController();
    await tester.pumpWidget(_host(window));
    final narrow = window.captionButtons.last.close;

    // A wider window moves the buttons to its right edge; the platform has
    // to be told again, or it hit-tests where they used to be.
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump();

    final wide = window.captionButtons.last.close;
    expect(wide.right, greaterThan(narrow.right));
    expect(wide, _drawnRect(tester, 'window-close'));
  });
}

/// Where the button [label] was drawn, in the view's logical pixels.
Rect _drawnRect(WidgetTester tester, String label) =>
    tester.getRect(find.byKey(Key(label)));

/// The sidebar toggle's tooltip, as it stands.
String _sidebarTooltip(WidgetTester tester) =>
    tester
        .widget<IconButton>(find.byKey(const Key('toggle-sidebar')))
        .tooltip ??
    '';

/// [rect] scaled by [scale], the way a report scales drawn pixels.
Rect _scaled(Rect rect, double scale) => Rect.fromLTWH(
  rect.left * scale,
  rect.top * scale,
  rect.width * scale,
  rect.height * scale,
);
