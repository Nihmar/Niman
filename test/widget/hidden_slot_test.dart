// Issue #1079: a slot kept mounted while hidden is not laid out again on
// every resize, divider drag or keyboard frame, and is laid out once when
// it is shown. `Offstage` lays its child out whatever it hides.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/hidden_slot.dart';
import 'package:niman/src/ui/tab_body_stack.dart';

/// Layouts the probe has been through, by name.
final Map<String, int> layouts = {};

/// A leaf that counts its layouts: what a hidden editor would pay.
final class Probe extends LeafRenderObjectWidget {
  const new(this.name, {super.key});

  final String name;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderProbe(name);
}

final class _RenderProbe extends RenderBox {
  new(this.name);

  final String name;

  @override
  bool get sizedByParent => false;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    layouts[name] = (layouts[name] ?? 0) + 1;
    size = constraints.biggest;
  }
}

/// A state that counts how often it was created.
final class Stateful extends StatefulWidget {
  const new({super.key});

  @override
  State<Stateful> createState() => _StatefulState();
}

final class _StatefulState extends State<Stateful> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => taps++),
    child: Text('taps $taps'),
  );
}

void main() {
  setUp(layouts.clear);

  Future<void> pumpWidthAndHidden(
    WidgetTester tester, {
    required double width,
    required bool hidden,
    bool offstage = false,
  }) {
    const child = Column(
      children: [
        Expanded(child: Probe('p')),
        Stateful(),
      ],
    );
    return tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (offstage)
                  Offstage(offstage: hidden, child: child)
                else
                  HiddenSlot(hidden: hidden, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a hidden slot is not laid out by a resize, once on show', (
    tester,
  ) async {
    await pumpWidthAndHidden(tester, width: 300, hidden: false);
    expect(layouts['p'], 1);

    await pumpWidthAndHidden(tester, width: 300, hidden: true);
    for (final width in [310.0, 320.0, 330.0, 340.0]) {
      await pumpWidthAndHidden(tester, width: width, hidden: true);
    }
    expect(layouts['p'], 1, reason: 'hidden: resizes cost the child nothing');

    await pumpWidthAndHidden(tester, width: 340, hidden: false);
    expect(layouts['p'], 2, reason: 'shown: laid out once, at the new size');
    expect(tester.getSize(find.byType(Probe)).width, 340);
  });

  testWidgets('Offstage, for contrast, lays its child out on every resize', (
    tester,
  ) async {
    await pumpWidthAndHidden(tester, width: 300, hidden: true, offstage: true);
    final first = layouts['p'] ?? 0;
    await pumpWidthAndHidden(tester, width: 310, hidden: true, offstage: true);
    expect(layouts['p'], greaterThan(first));
  });

  testWidgets('a hidden slot keeps its state, and neither paints nor hits', (
    tester,
  ) async {
    await pumpWidthAndHidden(tester, width: 300, hidden: false);
    await tester.tap(find.textContaining('taps'));
    await tester.pump();
    expect(find.text('taps 1'), findsOneWidget);

    await pumpWidthAndHidden(tester, width: 300, hidden: true);
    expect(find.textContaining('taps'), findsNothing, reason: 'offstage');
    expect(find.textContaining('taps', skipOffstage: false), findsOneWidget);

    await pumpWidthAndHidden(tester, width: 300, hidden: false);
    expect(find.text('taps 1'), findsOneWidget, reason: 'state kept');
  });

  testWidgets('a hidden slot lets go of the focus and takes none (#1074)', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    Future<void> pump({required bool hidden}) => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: HiddenSlot(
          hidden: hidden,
          child: Focus(focusNode: node, child: const SizedBox(width: 50)),
        ),
      ),
    );
    await pump(hidden: false);
    node.requestFocus();
    await tester.pump();
    expect(node.hasFocus, isTrue);

    await pump(hidden: true);
    expect(node.hasFocus, isFalse, reason: 'hiding takes the focus away');
    node.requestFocus();
    await tester.pump();
    expect(node.hasFocus, isFalse, reason: 'a hidden slot takes none');

    await pump(hidden: false);
    node.requestFocus();
    await tester.pump();
    expect(node.hasFocus, isTrue);
  });

  testWidgets('a slot hidden from the start is laid out once, then spared', (
    tester,
  ) async {
    await pumpWidthAndHidden(tester, width: 300, hidden: true);
    expect(layouts['p'], 1, reason: 'the first layout keeps overlay portals');
    for (final width in [310.0, 320.0, 330.0]) {
      await pumpWidthAndHidden(tester, width: width, hidden: true);
    }
    expect(layouts['p'], 1);
    expect(tester.takeException(), isNull);
    await pumpWidthAndHidden(tester, width: 330, hidden: false);
    expect(layouts['p'], 2);
  });

  testWidgets('the tab body stack lays out only the tab showing', (
    tester,
  ) async {
    Future<void> pump(int current, double width) => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            height: 200,
            child: TabBodyStack(
              currentIndex: current,
              children: const [Probe('a'), Probe('b'), Probe('c')],
            ),
          ),
        ),
      ),
    );

    await pump(0, 300);
    expect(layouts, {'a': 1, 'b': 1, 'c': 1}, reason: 'once, on mounting');
    await pump(0, 320);
    await pump(0, 340);
    expect(layouts, {'a': 3, 'b': 1, 'c': 1});

    await pump(1, 340);
    expect(layouts, {'a': 3, 'b': 2, 'c': 1}, reason: 'b laid out on show');
    await pump(1, 360);
    expect(layouts, {'a': 3, 'b': 3, 'c': 1});
  });
}
