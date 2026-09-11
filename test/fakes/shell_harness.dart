// What every widget test that drives the whole shell needs: the
// directory-picker stub the open flow goes through, the pump helpers for
// a shell full of streams and animations, and the finders for its
// dialogs and tree rows.
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/tree.dart';

/// A [FilePickerPlatform] stub: [directory] is what `getDirectoryPath`
/// returns (null = the user canceled).
final class FakeFilePicker extends FilePickerPlatform {
  /// The folder the picker answers with.
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

/// Installs a [FakeFilePicker] for the current test and restores the
/// previous platform after it.
///
/// Call it from `setUp` or from the test body; the teardown is
/// registered for you, so a test can never leak the stub into the next
/// one.
FakeFilePicker useFakeFilePicker() {
  final picker = FakeFilePicker();
  final previous = FilePickerPlatform.instance;
  FilePickerPlatform.instance = picker;
  addTearDown(() => FilePickerPlatform.instance = previous);
  return picker;
}

/// The text input of whichever dialog is open.
///
/// Scoped to the dialog because the note editor is a text field too, so
/// an unscoped finder is ambiguous inside the shell.
Finder dialogField() => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(TextField),
);

/// The tree pane itself: the width assertions measure its rect.
Finder noteTree() => find.byType(NoteTree);

/// The tree row (not the detail pane) showing [name].
///
/// With [offstage] true it also finds the tree under a pushed screen
/// (trash, settings): the shell keeps rebuilding underneath and stays
/// reachable.
Finder noteRow(String name, {bool offstage = false}) => find.descendant(
  of: find.byType(NoteTree, skipOffstage: !offstage),
  matching: find.text(name, skipOffstage: !offstage),
  skipOffstage: !offstage,
);

/// Pumps enough fake time for streams and dialogs to settle and
/// snackbars to auto-dismiss.
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

/// Taps a control in the desktop tree footer (T-PP-22), dismissing any
/// snackbar first: the footer sits in the strip a fixed snackbar covers.
Future<void> tapTreeFooterAction(WidgetTester tester, Finder finder) async {
  final messenger = find.byType(ScaffoldMessenger);
  if (messenger.evaluate().isNotEmpty) {
    tester.state<ScaffoldMessengerState>(messenger.first).clearSnackBars();
  }
  // Let any snackbar finish its exit before tapping the footer under it.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(finder);
}

/// Opens the create affordance of whichever layout is up: the phone's
/// expandable FAB menu, or the desktop tree footer's "+ New" menu
/// (T-PP-22). The individual actions share their keys across layouts.
Future<void> openNewItemMenu(WidgetTester tester) async {
  final fab = find.byKey(const Key('new-note-fab'));
  if (fab.evaluate().isNotEmpty) {
    await tester.tap(fab);
    await settleFabMenu(tester);
    return;
  }
  await tester.tap(find.byKey(const Key('new-item-menu')));
  await settle(tester);
}

/// Opens a library at `<parent>/<name>` through the "Create new" flow.
Future<void> openLibrary(
  WidgetTester tester,
  FakeFilePicker picker, {
  String parent = '/fake',
  String name = 'library',
}) async {
  picker.directory = parent;
  await tester.tap(find.text('Create new'));
  await settle(tester);
  await tester.enterText(dialogField(), name);
  await tester.pump(); // Frame: "Create" tracks the (trimmed) name.
  await tester.tap(find.text('Create'));
  await settle(tester);
}

/// Emulates a [size] surface (logical pixels) for the current test.
void setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
