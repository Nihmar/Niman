// #784: a letter picked from the A-Z grid after the row that opened it
// went away reports nothing: the dialog that owned the row is disposed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/todo_priority_chips.dart';

void main() {
  testWidgets('a pick after the row went away reports nothing', (tester) async {
    final showRow = ValueNotifier<bool>(true);
    addTearDown(showRow.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: showRow,
            builder: (context, show, _) =>
                show ? const _Owner() : const SizedBox(),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('todo-priority-more')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('todo-priority-grid')), findsOne);

    // The owner goes while the grid stays up, then a letter is picked.
    showRow.value = false;
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-priority-pick-M')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('todo-priority-grid')), findsNothing);
  });
}

/// What the todo dialog does with the row: keeps the value in its state.
class _Owner extends StatefulWidget {
  const new();

  @override
  State<_Owner> createState() => _OwnerState();
}

class _OwnerState extends State<_Owner> {
  String? _priority;

  @override
  Widget build(BuildContext context) => TodoPriorityChips(
    current: _priority,
    onChanged: (p) => setState(() => _priority = p),
  );
}
