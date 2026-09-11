// T-TB-04/05: the editor renders the toolbar the user arranged, and the
// settings screen is where they arrange it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/toolbar.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/toolbar_settings.dart';
import 'package:re_editor/re_editor.dart';

import '../fakes/fake_library_session.dart';

const String _doc = 'hello world';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Pumps a NoteView whose toolbar is [layout].
Future<void> _pumpEditor(
  WidgetTester tester,
  ToolbarLayout layout, {
  bool toolbarTop = false,
  bool showPreview = false,
}) async {
  final controller = CodeLineEditingController.fromText(_doc);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    _app(
      NoteView(
        path: '/notes/a.md',
        showLineNumbers: true,
        autofocusEditor: false,
        toolbarLayout: layout,
        toolbarTop: toolbarTop,
        showPreview: showPreview,
        controller: controller,
        readNote: (_) async => _doc,
        writeNote: (path, content) async {},
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// The toolbar's buttons, in render order.
List<Key?> _renderedKeys(WidgetTester tester) {
  final toolbar = tester.widget<EditorToolbar>(find.byType(EditorToolbar));
  return [for (final button in toolbar.buttons) button.key];
}

void main() {
  testWidgets('the editor renders every button by default', (tester) async {
    await _pumpEditor(tester, ToolbarLayout.defaults);
    expect(_renderedKeys(tester), [
      for (final item in ToolbarItem.values) item.widgetKey,
    ]);
  });

  testWidgets('default: the toolbar sits below the editor (phone)', (
    tester,
  ) async {
    await _pumpEditor(tester, ToolbarLayout.defaults);
    final bar = tester.getCenter(find.byKey(ToolbarItem.bold.widgetKey)).dy;
    final editor = tester.getCenter(find.byType(CodeEditor)).dy;
    expect(bar, greaterThan(editor));
  });

  testWidgets('toolbarTop: the toolbar sits above the editor (desktop)', (
    tester,
  ) async {
    await _pumpEditor(tester, ToolbarLayout.defaults, toolbarTop: true);
    expect(find.byType(EditorToolbar), findsOneWidget);
    expect(
      tester.getRect(find.byType(EditorToolbar)).height,
      editorToolbarHeight,
    );
    final bar = tester.getCenter(find.byKey(ToolbarItem.bold.widgetKey)).dy;
    final editor = tester.getCenter(find.byType(CodeEditor)).dy;
    expect(bar, lessThan(editor));
    // A divider sets the bar off the text.
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('fullscreen preview hides the toolbar, top or bottom', (
    tester,
  ) async {
    await _pumpEditor(tester, ToolbarLayout.defaults, showPreview: true);
    expect(find.byType(EditorToolbar), findsNothing);
    await _pumpEditor(
      tester,
      ToolbarLayout.defaults,
      toolbarTop: true,
      showPreview: true,
    );
    expect(find.byType(EditorToolbar), findsNothing);
  });

  testWidgets('a stored order is the render order', (tester) async {
    await _pumpEditor(tester, ToolbarLayout.parse('link,heading,bold'));
    expect(_renderedKeys(tester).take(3), [
      ToolbarItem.link.widgetKey,
      ToolbarItem.heading.widgetKey,
      ToolbarItem.bold.widgetKey,
    ]);
  });

  testWidgets('a hidden button is not rendered', (tester) async {
    await _pumpEditor(
      tester,
      ToolbarLayout.defaults.withVisible(ToolbarItem.bold, visible: false),
    );
    expect(find.byKey(ToolbarItem.bold.widgetKey), findsNothing);
    expect(find.byKey(ToolbarItem.italic.widgetKey), findsOneWidget);
  });

  testWidgets('hiding every button hides the toolbar itself', (tester) async {
    var layout = ToolbarLayout.defaults;
    for (final item in ToolbarItem.values) {
      layout = layout.withVisible(item, visible: false);
    }
    await _pumpEditor(tester, layout);
    expect(find.byType(EditorToolbar), findsNothing);
  });

  group('the settings screen', () {
    late FakeLibrarySession controller;

    setUp(() async {
      controller = FakeLibrarySession();
      await controller.open('/fake/library', create: true);
    });

    tearDown(() async {
      await controller.close();
      await controller.dispose();
    });

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        _app(ToolbarSettingsScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists every button, in order, with its name', (tester) async {
      // Tall enough for all fourteen rows: the list is lazy, so a short
      // surface would simply not build the last ones.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester);
      for (final item in ToolbarItem.values) {
        expect(find.text(item.label), findsOneWidget, reason: item.id);
      }
    });

    testWidgets('the eye hides a button and persists it', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('toolbar-visibility-bold')));
      await tester.pumpAndSettle();

      final stored = ToolbarLayout.parse(await controller.editorToolbar);
      expect(stored.isVisible(ToolbarItem.bold), isFalse);
      expect(stored.isVisible(ToolbarItem.italic), isTrue);

      // Tapping it again brings the button back.
      await tester.tap(find.byKey(const Key('toolbar-visibility-bold')));
      await tester.pumpAndSettle();
      expect(
        ToolbarLayout.parse(await controller.editorToolbar)
            .isVisible(ToolbarItem.bold),
        isTrue,
      );
    });

    testWidgets('dragging a row reorders and persists it', (tester) async {
      await pump(tester);
      final handle = find
          .descendant(
            of: find.byType(ReorderableDragStartListener),
            matching: find.byIcon(Icons.drag_indicator),
          )
          .first;
      final rowHeight = tester.getSize(find.byType(ListTile).first).height;

      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveBy(Offset(0, rowHeight * 1.6));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pumpAndSettle();

      final stored = ToolbarLayout.parse(await controller.editorToolbar);
      expect(stored.order.first, isNot(ToolbarItem.bold));
      expect(stored.order.indexOf(ToolbarItem.bold), greaterThan(0));
      expect(stored.order.length, ToolbarItem.values.length);
    });

    testWidgets('restore defaults puts the shipped toolbar back', (
      tester,
    ) async {
      await controller.setEditorToolbar('-bold,link');
      await pump(tester);
      await tester.tap(find.text(AppStrings.toolbarResetOrder));
      await tester.pumpAndSettle();

      expect(await controller.editorToolbar, ToolbarLayout.defaults.encode());
    });
  });
}
