// #1003, #1022: the strip of active filters under the phone's app bar and
// the desktop's toolbar — its tail (the count and Clear) never overflows,
// whatever the width and the count.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_list_view.dart';
import 'package:niman/src/ui/todo_filter_strip.dart';

void main() {
  late TodoListView view;

  Future<void> pumpStrip(
    WidgetTester tester, {
    required double width,
    required int shown,
    required int total,
    double textScale = 1,
  }) async {
    view = TodoListView(
      filter: const TodoFilter(
        dueRange: TodoDueRange.overdue,
        tokens: {'+project', '@context'},
      ),
    );
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: TodoFilterStrip(view: view, shown: shown, total: total),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder key(String name) => find.byKey(Key(name));

  testWidgets('no width of the phone overflows the strip (#1022)', (
    tester,
  ) async {
    // The narrow end of the phones, and large text on the wider ones; a
    // chip itself cannot shrink, which sets the floor at big text scales.
    const cases = <(double, double)>[
      (240, 1),
      (280, 1),
      (280, 1.5),
      (320, 2),
      (360, 2),
      (412, 2),
    ];
    for (final (width, scale) in cases) {
      await pumpStrip(
        tester,
        width: width,
        shown: 1234567,
        total: 9999999,
        textScale: scale,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'width $width, text scale $scale',
      );
      expect(key('todo-filtered-count'), findsOneWidget);
      expect(key('todo-clear-filters'), findsOneWidget);
      final strip = tester.getRect(key('todo-filter-strip'));
      expect(
        tester.getRect(key('todo-clear-filters')).right,
        lessThanOrEqualTo(strip.right),
        reason: 'Clear stays inside the strip at $width, scale $scale',
      );
    }
  });

  testWidgets('with room, the count and Clear sit at the end of the chips '
      'row', (tester) async {
    await pumpStrip(tester, width: 412, shown: 3, total: 12);
    final chip = tester.getRect(key('todo-strip-due'));
    final count = tester.getRect(key('todo-filtered-count'));
    final clear = tester.getRect(key('todo-clear-filters'));
    expect(count.left, greaterThan(chip.right));
    expect(clear.left, greaterThanOrEqualTo(count.right));
    expect(clear.right, greaterThan(412 - 16), reason: 'at the end');
  });
}
