// #1064: tree changes that arrive while the rows are being read share one more
// read, instead of one read per change.
//
// #1200: a read of the tree is now the model's — the root's child count and
// each open folder's — and the rows are read after it, a page at a time. The
// count is what the test holds and counts (`countGate`, `countCalls`) where it
// used to hold the folders' rows (`treeGate`, `treeCalls`); the claim is the
// same.
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
    final before = controller.countCalls;

    // The next read is held; changes keep arriving a frame apart.
    final gate = controller.countGate = Completer<void>();
    for (var i = 0; i < 20; i++) {
      await controller.createNote(parentPath: '', name: 'note$i');
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(controller.countCalls - before, 1, reason: 'one read is in flight');

    gate.complete();
    controller.countGate = null;
    await tester.pumpAndSettle();

    expect(controller.countCalls - before, 2, reason: 'one more, not twenty');
    expect(controller.countPeak, 1);
    expect(find.text('note19.md'), findsOneWidget);
  });
}
