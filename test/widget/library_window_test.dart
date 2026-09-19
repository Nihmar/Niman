// #203: the library window saves the open notes before the library goes,
// and a note that will not save keeps the library open.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/library_window.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

import '../fakes/fake_library_session.dart';

final class _Note implements UnsavedNote {
  new({this.fails = false});

  final bool fails;
  int saves = 0;

  @override
  String get path => '/fake/library/a.md';

  @override
  bool unsaved = true;

  @override
  Future<void> save() async {
    saves++;
    if (fails) throw const _SaveFailed('disk full');
    unsaved = false;
  }
}

final class _SaveFailed implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => message;
}

void main() {
  late FakeLibrarySession controller;
  late UnsavedTracker unsaved;

  setUp(() async {
    controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
    unsaved = UnsavedTracker();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                libraryWindowRoute(
                  context,
                  controller: controller,
                  unsaved: unsaved,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Close library saves the open notes first', (tester) async {
    final note = _Note();
    unsaved.register(note);
    await pump(tester);
    await tester.tap(find.byKey(const Key('library-window-close-library')));
    await tester.pumpAndSettle();
    expect(note.saves, 1);
    expect(controller.root, isNull);
    expect(find.byKey(const Key('library-window')), findsNothing);
  });

  testWidgets('a note that will not save keeps the library open', (
    tester,
  ) async {
    unsaved.register(_Note(fails: true));
    await pump(tester);
    await tester.tap(find.byKey(const Key('library-window-close-library')));
    await tester.pumpAndSettle();
    expect(controller.root, '/fake/library');
    expect(find.byKey(const Key('library-window')), findsOne);
    expect(find.byKey(const Key('library-window-error')), findsOne);
    expect(find.textContaining('disk full'), findsOne);
  });
}
