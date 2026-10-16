// T-TK-07: the folder picker behind the list-folder setting — folders
// are chosen from a dialog, never typed.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool allowRoot = false,
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
                allowRoot: allowRoot,
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
  testWidgets('typing narrows the list, and the keys choose from it (#1072)', (
    tester,
  ) async {
    final session = FakeLibrarySession();
    final chosen = await _pick(
      tester,
      session,
      names: ['Archive', 'Inbox', 'Projects', 'Archived'],
      allowRoot: true,
      act: (tester) async {
        // The field has the focus as the dialog opens.
        await tester.enterText(
          find.byKey(const Key('folder-picker-filter')),
          'ARCH',
        );
        await tester.pumpAndSettle();
        expect(find.text('Archive'), findsOneWidget);
        expect(find.text('Archived'), findsOneWidget);
        expect(find.text('Inbox'), findsNothing);
        expect(find.text('Projects'), findsNothing);
        // The first match is the choice; Down moves it to the next.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      },
    );
    expect(chosen, 'Archived');
  });

  testWidgets('a filter nothing matches says so and chooses nothing', (
    tester,
  ) async {
    final session = FakeLibrarySession();
    final chosen = await _pick(
      tester,
      session,
      names: ['Inbox'],
      act: (tester) async {
        await tester.enterText(
          find.byKey(const Key('folder-picker-filter')),
          'zzz',
        );
        await tester.pumpAndSettle();
        expect(find.text('Inbox'), findsNothing);
        expect(find.text('No matches'), findsOneWidget);
        final choose = tester.widget<FilledButton>(
          find.byKey(const Key('folder-picker-choose')),
        );
        expect(choose.onPressed, isNull);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('folder-picker-filter')), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      },
    );
    expect(chosen, isNull);
  });

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
        // No path is typed: the one field only narrows the list.
        expect(find.byType(TextField), findsOneWidget);
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
        await tester.enterText(find.byType(TextField).last, 'Checklists');
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

  // Issue #94: the attachments setting says `assets` from the first run,
  // in libraries that never held such a folder. It must not be selected,
  // or New folder builds the wanted folder inside it.
  testWidgets('a current folder the library does not hold is not selected', (
    tester,
  ) async {
    final session = FakeLibrarySession();
    final chosen = await _pick(
      tester,
      session,
      names: ['Notes'],
      current: 'assets',
      act: (tester) async {
        // Nothing is selected, so there is nothing to choose yet.
        expect(find.byIcon(Icons.radio_button_checked), findsNothing);
        final choose = tester.widget<FilledButton>(
          find.byKey(const Key('folder-picker-choose')),
        );
        expect(choose.onPressed, isNull);
        // New folder opens on the missing folder's name...
        await tester.tap(find.text('New folder'));
        await tester.pumpAndSettle();
        final field = find.byType(TextField).last;
        expect(tester.widget<TextField>(field).controller?.text, 'assets');
        // ...and whatever it is renamed to lands at the library root.
        await tester.enterText(field, 'attachments');
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('folder-picker-choose')));
        await tester.pumpAndSettle();
      },
    );
    expect(chosen, 'attachments');
    expect(await session.ops!.find('attachments'), isNotNull);
    expect(await session.ops!.find('assets'), isNull);
    expect(await session.ops!.find('assets/attachments'), isNull);
    await session.close();
    await session.dispose();
  });

  testWidgets('a folder the library holds stays selected, and is a parent', (
    tester,
  ) async {
    final session = FakeLibrarySession();
    final chosen = await _pick(
      tester,
      session,
      names: ['assets', 'Notes'],
      current: 'assets',
      act: (tester) async {
        // Selected, so New folder has a parent and nothing to suggest.
        await tester.tap(find.text('New folder'));
        await tester.pumpAndSettle();
        final field = find.byType(TextField).last;
        expect(tester.widget<TextField>(field).controller?.text, isEmpty);
        await tester.enterText(field, 'clips');
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('folder-picker-choose')));
        await tester.pumpAndSettle();
      },
    );
    expect(chosen, 'assets/clips');
    await session.close();
    await session.dispose();
  });

  // Moving a note used to ask "which folder?" through a bare dropdown of
  // its own, which could not create one. It asks this dialog now, and
  // this dialog had no way to say "the library root".
  testWidgets('the library root is a target where the caller allows it', (
    tester,
  ) async {
    final session = FakeLibrarySession();
    final chosen = await _pick(
      tester,
      session,
      names: ['Books'],
      allowRoot: true,
      act: (tester) async {
        expect(find.text('Library root'), findsOneWidget);
        expect(find.text('Books'), findsOneWidget);
        // The move gets what the settings had: a folder it has not made
        // yet is one tap away.
        expect(find.text('New folder'), findsOneWidget);
        await tester.tap(find.text('Library root'));
        await tester.pump();
        await tester.tap(find.byKey(const Key('folder-picker-choose')));
        await tester.pumpAndSettle();
      },
    );
    expect(chosen, '');
    await session.close();
    await session.dispose();
  });

  testWidgets('the library root stays out where it is not allowed', (
    tester,
  ) async {
    final session = FakeLibrarySession();
    await _pick(
      tester,
      session,
      names: ['Books'],
      act: (tester) async {
        expect(find.text('Library root'), findsNothing);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      },
    );
    await session.close();
    await session.dispose();
  });
}
