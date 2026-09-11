// T-PP-22: the app's own window title bar — the sidebar toggle, the drag
// area, and the window buttons over the seam (the close button goes
// through it, so it meets the unsaved-edits guard like the system one).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
