// #493: the Settings "Close library" row leaves the library the one way out
// of a library does — every unsaved note is written first, and a note that
// will not save keeps the library open.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

/// An open note whose write is the session's own `saveNote`, so a test can
/// make it fail ([FakeLibrarySession.saveError]).
final class _OpenNote implements UnsavedNote {
  new(this.session, this.path);

  final FakeLibrarySession session;

  @override
  final String path;

  @override
  bool unsaved = true;

  @override
  Future<void> save() async {
    await session.saveNote(path, 'edited');
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
  late FakeLibrarySession session;
  late UnsavedTracker unsaved;

  setUp(() async {
    session = FakeLibrarySession();
    unsaved = UnsavedTracker();
    await session.open(
      p.join(Directory.systemTemp.path, 'niman_close_library'),
      create: false,
    );
  });

  tearDown(() async {
    await session.dispose();
    unsaved.dispose();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsBody(controller: session, unsaved: unsaved),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the open notes are written before the library closes', (
    tester,
  ) async {
    final note = _OpenNote(session, 'note.md');
    unsaved.register(note);
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('close-library-setting')));
    await tester.pumpAndSettle();

    expect(session.saves, hasLength(1), reason: 'the note was written');
    expect(note.unsaved, isFalse);
    expect(session.root, isNull, reason: 'the library closed');
  });

  testWidgets('a note that will not save keeps the library open', (
    tester,
  ) async {
    session.saveError = const _SaveFailed('disk full');
    unsaved.register(_OpenNote(session, 'note.md'));
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('close-library-setting')));
    await tester.pumpAndSettle();

    expect(session.root, isNotNull, reason: 'the library stayed');
    expect(find.text(AppStrings.closeSaveFailed), findsOne);
  });
}
