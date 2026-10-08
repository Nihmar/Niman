// Paste as Markdown in the shell (#531): the command palette lists it as
// an editor command, with Ctrl+Shift+V beside it, once a note is there to
// take the paste. (What the paste does to the note is
// `paste_markdown_test.dart`'s: the shell's own editor never loads its note
// under fake async.)
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/capture/paste/clipboard_html.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/capture/paste_markdown_flow.dart';
import 'package:niman/src/ui/palette/command_palette.dart';
import 'package:niman/src/ui/palette/palette_command.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> chord(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  testWidgets('the palette lists it, with its key, once a note is open', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(1400, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          pasteServicesProvider.overrideWithValue(
            const PasteServices(html: NoClipboardHtml()),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    Set<AppCommand> offered() => {
      for (final command
          in tester
              .widget<CommandPalette>(find.byType(CommandPalette))
              .commands)
        command.command,
    };

    await chord(tester, LogicalKeyboardKey.keyP);
    expect(offered(), isNot(contains(AppCommand.pasteAsMarkdown)));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);

    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await chord(tester, LogicalKeyboardKey.keyP);
    expect(offered(), contains(AppCommand.pasteAsMarkdown));
    final command = PaletteCommand.of(AppCommand.pasteAsMarkdown);
    expect(command.name, 'Editor: Paste as Markdown');
    expect(describeActivator(command.binding!), 'Ctrl+Shift+V');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    await controller.close();
    await controller.dispose();
  });
}
