// #230: where no keyboard has been seen, nothing tells the reader about
// keys they cannot press — not the palette's rows, not its footer, not
// the Commands page.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/keyboard_presence.dart';
import 'package:niman/src/ui/palette/command_palette.dart';
import 'package:niman/src/ui/palette/palette_command.dart';
import 'package:niman/src/ui/settings_commands.dart';
import 'package:niman/src/ui/strings.dart';

void main() {
  late bool wasAttached;

  setUp(() => wasAttached = KeyboardPresence.shared.attached);
  tearDown(() => KeyboardPresence.shared.attached = wasAttached);

  /// The key `Ctrl+Shift+P` reads as on the palette's rows.
  String paletteKeys() =>
      describeActivator(KeyMap.defaults.bindingOf(AppCommand.openPalette)!);

  Future<void> pumpPalette(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommandPalette(
            commands: [PaletteCommand.of(AppCommand.openPalette)],
            searchNotes: (_) async => const <String>[],
            onTogglePin: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with a keyboard the palette shows the keys', (tester) async {
    KeyboardPresence.shared.attached = true;
    await pumpPalette(tester);
    expect(find.text(paletteKeys()), findsOne);
    expect(find.textContaining(AppStrings.palettePinFooter), findsOne);
  });

  testWidgets('without one it shows neither keys nor key hints', (
    tester,
  ) async {
    KeyboardPresence.shared.attached = false;
    await pumpPalette(tester);
    expect(find.text(paletteKeys()), findsNothing);
    expect(find.text(AppStrings.paletteFooterTouch), findsOne);
    // The pin is still there: it is a tap, not a key.
    expect(
      find.byKey(Key('palette-pin-${AppCommand.openPalette.name}')),
      findsOne,
    );
  });

  testWidgets('the Commands page drops its keys, not its conditions', (
    tester,
  ) async {
    KeyboardPresence.shared.attached = false;
    await tester.pumpWidget(const MaterialApp(home: SettingsCommandsScreen()));
    await tester.pumpAndSettle();
    expect(find.text(paletteKeys()), findsNothing);
    expect(find.text(AppStrings.commandNeedNone), findsWidgets);
  });
}
