// The Files pane's List | Grid switch is one rounded shape: the fill of
// the segment that is on follows the outline's corners instead of poking
// out of them square.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/ui/tree_view_toggle.dart';

void main() {
  const background = Color(0xFFFF00FF);
  final boundary = GlobalKey();

  Future<void> pump(WidgetTester tester, TreeView view) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: background,
        body: Center(
          child: RepaintBoundary(
            key: boundary,
            child: ColoredBox(
              color: background,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TreeViewToggle(view: view, onView: (_) {}),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('the segments are clipped to the rounded outline', (
    tester,
  ) async {
    await pump(tester, TreeView.grid);
    final material = tester.widget<Material>(
      find
          .ancestor(
            of: find.byKey(const Key('view-grid-toggle')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.clipBehavior, Clip.antiAlias);
    final shape = material.shape! as RoundedRectangleBorder;
    expect(
      shape.borderRadius,
      BorderRadius.circular(TreeViewToggle.cornerRadius),
    );
    expect(shape.side.style, BorderStyle.solid);
  });

  testWidgets('the fill of the selected segment does not reach the corners', (
    tester,
  ) async {
    await pump(tester, TreeView.grid);
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = (await tester.runAsync(render.toImage))!;
    final data = (await tester.runAsync(image.toByteData))!;
    Color at(int x, int y) {
      final i = (y * image.width + x) * 4;
      return Color.fromARGB(
        data.getUint8(i + 3),
        data.getUint8(i),
        data.getUint8(i + 1),
        data.getUint8(i + 2),
      );
    }

    // The corner pixel of the toggle's bounding box lies outside the
    // rounded shape, so it is the ground, not the fill. A square fill
    // painted it.
    final ratio = image.width / tester.getSize(find.byKey(boundary)).width;
    final box = tester.getRect(find.byType(Material).last);
    final origin = tester.getTopLeft(find.byKey(boundary));
    final right = ((box.right - origin.dx) * ratio).floor() - 1;
    final bottom = ((box.bottom - origin.dy) * ratio).floor() - 1;
    final top = ((box.top - origin.dy) * ratio).ceil();
    for (final y in [top, bottom]) {
      expect(at(right, y), background, reason: 'corner pixel at y=$y');
    }
    // And the fill is there, away from the corners.
    expect(
      at(right - 8, (top + bottom) ~/ 2),
      isNot(background),
      reason: 'the selected segment is filled',
    );
  });
}
