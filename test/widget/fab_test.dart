// T-UI-05: the "+" FAB expands into New note / New folder mini FABs
// above it; the main button just toggles the menu.
import 'package:copist/src/app.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/ui/tree.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';

/// A [FilePickerPlatform] stub: [directory] is what
/// getDirectoryPath returns (null = the user canceled).
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

/// The text input of whichever dialog is open.
Finder dialogField() => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );

/// The tree row (not the detail pane) showing [name].
Finder noteRow(String name) => find.descendant(
      of: find.byType(NoteTree),
      matching: find.text(name),
    );

/// Pumps enough fake time for streams/dialogs to settle and snackbars to
/// auto-dismiss.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 4));
  await tester.pump(const Duration(seconds: 1));
}

/// Animates the FAB menu to its resting state (the minis take 150 ms).
Future<void> settleFabMenu(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// The mini FAB [key]'s AnimatedOpacity target (0 = hidden, 1 = shown).
double miniOpacity(WidgetTester tester, Key key) {
  return tester
      .widget<AnimatedOpacity>(find.descendant(
        of: find.byKey(key),
        matching: find.byType(AnimatedOpacity),
      ))
      .opacity;
}

/// Whether the mini FAB [key] ignores taps (true = collapsed).
bool miniIgnored(WidgetTester tester, Key key) {
  return tester
      .widget<IgnorePointer>(find.descendant(
        of: find.byKey(key),
        matching: find.byType(IgnorePointer),
      ))
      .ignoring;
}

/// Whether the FAB-menu scrim ignores taps (true = collapsed). The scrim
/// stays mounted so the reveal can animate back to the FAB.
bool scrimInert(WidgetTester tester) => tester
    .widget<IgnorePointer>(find.byKey(const Key('fab-scrim')))
    .ignoring;

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
    await tester.enterText(dialogField(), 'library');
    await tester.pump(); // Frame: "Create" tracks the (trimmed) name.
    await tester.tap(find.text('Create'));
    await settle(tester);
  }

  testWidgets('the FAB expands into note and folder actions (T-UI-05)', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);

    // Collapsed: the minis are hidden and ignore taps; inert scrim.
    expect(find.byKey(const Key('new-note-fab')), findsOneWidget);
    expect(scrimInert(tester), isTrue);
    expect(miniOpacity(tester, const Key('new-note-action')), 0);
    expect(miniIgnored(tester, const Key('new-note-action')), isTrue);
    expect(miniOpacity(tester, const Key('new-folder-action')), 0);
    expect(miniIgnored(tester, const Key('new-folder-action')), isTrue);

    // Expand: both minis become visible and tappable.
    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    expect(scrimInert(tester), isFalse);
    expect(miniOpacity(tester, const Key('new-note-action')), 1);
    expect(miniIgnored(tester, const Key('new-note-action')), isFalse);
    expect(miniOpacity(tester, const Key('new-folder-action')), 1);
    expect(miniIgnored(tester, const Key('new-folder-action')), isFalse);

    // The New note mini opens the name dialog; the menu collapses.
    await tester.tap(find.byKey(const Key('new-note-action')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(miniOpacity(tester, const Key('new-note-action')), 0);
    expect(miniIgnored(tester, const Key('new-note-action')), isTrue);
    await tester.enterText(dialogField(), 'First note');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('First note.md'), findsOneWidget);
    expect(scrimInert(tester), isTrue);

    // Expand again; the New folder mini creates a folder.
    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    await tester.tap(find.byKey(const Key('new-folder-action')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(dialogField(), 'Docs');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('Docs'), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('tapping the FAB again closes the menu without a dialog', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);

    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    expect(miniOpacity(tester, const Key('new-note-action')), 1);

    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    expect(miniOpacity(tester, const Key('new-note-action')), 0);
    expect(miniIgnored(tester, const Key('new-note-action')), isTrue);
    expect(miniOpacity(tester, const Key('new-folder-action')), 0);
    expect(scrimInert(tester), isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await controller.ops!.find('New note.md'), isNull);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('tapping the scrim dismisses the menu without a dialog', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester);

    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    expect(miniOpacity(tester, const Key('new-note-action')), 1);
    expect(scrimInert(tester), isFalse);

    // A tap anywhere on the body (the scrim) closes the menu.
    await tester.tap(find.byKey(const Key('fab-scrim')));
    await settleFabMenu(tester);
    expect(scrimInert(tester), isTrue);
    expect(miniOpacity(tester, const Key('new-note-action')), 0);
    expect(miniIgnored(tester, const Key('new-note-action')), isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await controller.ops!.find('New note.md'), isNull);

    // The main FAB is still usable: expand, then create a note.
    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    await tester.tap(find.byKey(const Key('new-note-action')));
    await settle(tester);
    await tester.enterText(dialogField(), 'Scrim note');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('Scrim note.md'), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });
}
