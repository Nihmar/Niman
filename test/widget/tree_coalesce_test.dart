// #1064: tree changes that arrive while the rows are being read share one more
// read, instead of one read per change.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/tree.dart';

import '../fakes/fake_library_session.dart';

void main() {
  testWidgets('twenty changes during a slow read make two reads', (
    tester,
  ) async {
    final controller = FakeLibrarySession();
    addTearDown(() async {
      await controller.close();
      await controller.dispose();
    });
    await controller.open('/lib', create: false);
    await controller.createNote(parentPath: '', name: 'alpha');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteTree(
            controller: controller,
            selectedPath: null,
            expanded: const <String>{},
            onToggle: (_) {},
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = controller.treeCalls;

    // The next read is held; changes keep arriving a frame apart.
    final gate = controller.treeGate = Completer<void>();
    for (var i = 0; i < 20; i++) {
      await controller.createNote(parentPath: '', name: 'note$i');
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(controller.treeCalls - before, 1, reason: 'one read is in flight');

    gate.complete();
    controller.treeGate = null;
    await tester.pumpAndSettle();

    expect(controller.treeCalls - before, 2, reason: 'one more, not twenty');
    expect(controller.treePeak, 1);
    expect(find.text('note19.md'), findsOneWidget);
  });
}
