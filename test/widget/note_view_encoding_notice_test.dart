// A note that is not UTF-8 opens as Windows-1252 and is saved as UTF-8: the
// reader is told when it opens, before the first keystroke (#1367). A UTF-8
// note says nothing.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_editor_options.dart';
import 'package:niman/src/ui/note_services.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('niman_enc_notice'));
  tearDown(() => dir.deleteSync(recursive: true));

  String write(String name, List<int> bytes) {
    final path = p.join(dir.path, name);
    File(path).writeAsBytesSync(bytes);
    return path;
  }

  /// The real reads are isolates and a stat: real waits, and a frame each.
  Future<void> settle(WidgetTester tester) async {
    for (var turn = 0; turn < 3; turn++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump();
    }
  }

  Widget app(String path) => MaterialApp(
    home: Scaffold(
      body: NoteView(
        key: ValueKey(path),
        path: path,
        options: const NoteEditorOptions(
          showLineNumbers: false,
          autofocusEditor: false,
        ),
        services: NoteServices(unsavedTracker: UnsavedTracker()),
      ),
    ),
  );

  testWidgets('a Windows-1252 note says it was read so and will be saved as '
      'UTF-8', (tester) async {
    final path = write('latin.md', [0x63, 0x61, 0x66, 0xE9, 0x0A]);
    await tester.pumpWidget(app(path));
    await settle(tester);
    expect(find.text(AppStrings.noteReadAsWindows1252), findsOneWidget);
  });

  testWidgets('a UTF-8 note says nothing', (tester) async {
    final path = write('utf8.md', [0x63, 0x61, 0x66, 0xC3, 0xA9, 0x0A]);
    await tester.pumpWidget(app(path));
    await settle(tester);
    expect(find.text(AppStrings.noteReadAsWindows1252), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a UTF-16 note says nothing: it is saved as it was read', (
    tester,
  ) async {
    final path = write('utf16.md', [0xFF, 0xFE, 0x61, 0x00, 0x0A, 0x00]);
    await tester.pumpWidget(app(path));
    await settle(tester);
    expect(find.byType(SnackBar), findsNothing);
  });
}
