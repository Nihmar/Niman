// T-UI-02 AC: the phone/narrow layout shows the 5-tab bottom NavigationBar;
// switching tabs preserves the library state (expanded folders, selected
// note); the wide layout stays unchanged (no tab bar).
// T-UI-10 AC: the Quick note tab opens `Quick note.md` at the library root,
// creating it when missing; the Search tab is disabled until M3 (R3).
import 'package:copist/src/app.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/note_view.dart';
import 'package:copist/src/ui/tree.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';

/// Phone-sized surface (390 x 844 logical).
void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// A [FilePickerPlatform] stub: [directory] is what
/// `getDirectoryPath` returns (`null` = the user canceled).
final class _FakeFilePicker extends FilePickerPlatform {
  String? directory;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    return directory;
  }
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 4));
  await tester.pump(const Duration(seconds: 1));
}

Finder noteRow(FakeLibrarySession controller, String name) {
  return find.descendant(
    of: find.byType(NoteTree),
    matching: find.text(name),
  );
}

void main() {
  late FakeLibrarySession controller;
  late _FakeFilePicker filePicker;
  late FilePickerPlatform previousPicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = _FakeFilePicker();
    previousPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = filePicker;
  });

  tearDown(() {
    FilePickerPlatform.instance = previousPicker;
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [librarySessionProvider.overrideWithValue(controller)],
      child: const CopistApp(),
    );
  }

  /// Opens a library at /fake/library through the "Create new" flow.
  Future<void> openLibrary(WidgetTester tester) async {
    filePicker.directory = '/fake';
    await tester.tap(find.text('Create new'));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'library',
    );
    await tester.pump();
    await tester.tap(find.text('Create'));
    await settle(tester);
  }

  testWidgets('phone: 5 destinations show and switching preserves state',
      (tester) async {
    _setPhoneSize(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);
    expect(find.text('No notes yet'), findsOne);

    // Create a folder, expand it, and create a note inside it.
    for (var i = 0; i < 2; i++) {
      await tester.tap(
        find.byTooltip(i == 0 ? 'New folder' : 'New note'),
      );
      await tester.pump();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        i == 0 ? 'Docs' : 'In note',
      );
      await tester.tap(find.text('OK'));
      await settle(tester);
      if (i == 0) {
        await tester.tap(noteRow(controller, 'Docs'));
        await settle(tester);
      }
    }

    // Back to the tree (the note opened full-screen).
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);

    // The bottom navigation bar is there with the 5 mockup destinations.
    expect(find.byType(NavigationBar), findsOne);
    for (final label in ['Files', 'Todo', 'Search', 'Quick note', 'Settings']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOne,
      );
    }

    // Go to the Settings tab and back: the tree keeps its expansion.
    await tester.tap(find.byKey(const Key('tab-settings')));
    await settle(tester);
    expect(
      find.text('Deletions move to .trash/ (off = hard delete)'),
      findsOne,
    );
    await tester.tap(find.byKey(const Key('tab-files')));
    await settle(tester);
    expect(noteRow(controller, 'Docs'), findsOne);
  });

  testWidgets('quick note: created at root when missing and opened',
      (tester) async {
    _setPhoneSize(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Quick note'),
    ));
    await settle(tester);
    expect(find.text('Open quick note'), findsOne);

    await tester.tap(find.text('Open quick note'));
    await settle(tester);
    expect(find.byType(NoteView), findsOneWidget);
    expect(find.text('Quick note.md'), findsOneWidget); // app bar title.
    expect(await controller.ops!.find('Quick note.md'), isNotNull);

    // Back returns to the Quick note tab.
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.text('Open quick note'), findsOne);
  });

  testWidgets('quick note: user-chosen note wins over the default',
      (tester) async {
    _setPhoneSize(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);

    // Seed two notes in the fake: the default and a user-chosen one.
    final chosen = await controller.createNote(
      parentPath: '',
      name: 'Scratch',
    );
    await controller.createNote(parentPath: '', name: 'Other');
    await settle(tester);

    // Choose "Scratch.md" in Settings: the tile shows it after the pick.
    await tester.tap(find.byKey(const Key('tab-settings')));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('quick-note-setting')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(defaultQuickNoteName), findsOne);
    await tester.scrollUntilVisible(
      find.text(defaultQuickNoteName),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    // The tile can still sit behind the bottom NavigationBar: nudge the
    // list up so the subtitle (the tap target) is fully visible.
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -120),
    );
    await settle(tester);
    await tester.tap(find.text(defaultQuickNoteName));
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NoteTree),
        matching: find.text('Scratch.md'),
      ),
    );
    await settle(tester);

    expect(find.text('Scratch.md'), findsOne);
    expect(await controller.ops!.quickNotePath, 'Scratch.md');

    // The Quick note tab opens the chosen note, not the default.
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Quick note'),
    ));
    await settle(tester);
    await tester.tap(find.text('Open quick note'));
    await settle(tester);
    expect(find.byType(NoteView), findsOneWidget);
    expect(find.text('Scratch.md'), findsOneWidget); // app bar title.
    expect(chosen.path, 'Scratch.md');
  });

  testWidgets('search tab is disabled until M3 (R3)', (tester) async {
    _setPhoneSize(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Search'),
    ));
    await settle(tester);
    // The tab does not switch; the tooltip snackbar explains the delay.
    expect(find.text('Search lands in M3'), findsOne);
    expect(find.text('No notes yet'), findsOne);
  });

  testWidgets('wide layout keeps the split, with no tab bar', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);

    // No bottom navigation on the wide split layout.
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Select a note'), findsOne);
  });
}
