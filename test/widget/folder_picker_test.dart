// T-TK-07: the folder picker behind the list-folder setting — folders
// are chosen from a dialog, never typed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/folder_picker.dart';

import '../fakes/fake_library_session.dart';

/// Opens the picker over a ready fake library holding [names] and
/// returns what it resolved to.
Future<String?> _pick(
  WidgetTester tester,
  FakeLibrarySession session, {
  required List<String> names,
  String? current,
  Future<void> Function(WidgetTester tester)? act,
}) async {
  await session.open('/fake/library', create: true);
  final ops = session.ops!;
  for (final name in names) {
    await ops.createFolder(parentPath: '', name: name);
  }
  final folders = <Note>[...await session.folders()];

  String? chosen;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              chosen = await showFolderPicker(
                context,
                title: 'List folder',
                folders: folders,
                ops: ops,
                current: current,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await act?.call(tester);
  return chosen;
}

void main() {
  testWidgets('lists the folders and resolves to the chosen one', (
    tester,
  ) async {
    final session = FakeLibrarySession();
    final chosen = await _pick(
      tester,
      session,
      names: ['Lists', 'Notes'],
      current: 'Lists',
      act: (tester) async {
        // Nothing is typed: the dialog has no text field.
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Lists'), findsOneWidget);
        expect(find.text('Notes'), findsOneWidget);
        await tester.tap(find.text('Notes'));
        await tester.pump();
        await tester.tap(find.byKey(const Key('folder-picker-choose')));
        await tester.pumpAndSettle();
      },
    );
    expect(chosen, 'Notes');
    await session.close();
    await session.dispose();
  });

  testWidgets('New folder creates one and picks it', (tester) async {
    final session = FakeLibrarySession();
    final chosen = await _pick(
      tester,
      session,
      names: [],
      act: (tester) async {
        await tester.tap(find.text('New folder'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          'Checklists',
        );
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('folder-picker-choose')));
        await tester.pumpAndSettle();
      },
    );
    expect(chosen, 'Checklists');
    expect(await session.ops!.find('Checklists'), isNotNull);
    await session.close();
    await session.dispose();
  });
}
