// The Mac's menu bar (docs/records/apple-platforms.md): the command
// registry in the system's bar, each command with its key unless a note
// needs that key first.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/ui/app_menu.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/mac_menu_bar.dart';

void main() {
  final sent = <MethodCall>[];

  setUp(() {
    sent.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.menu, (call) async {
          sent.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.menu, null);
  });

  Widget host(Map<AppCommand, VoidCallback> handlers) => MaterialApp(
    home: MacMenuBar(
      handlers: () => handlers,
      features: () => const Features(),
      child: const SizedBox(),
    ),
  );

  /// The menus as handed to the system, flattened to their items.
  List<Map<Object?, Object?>> items() {
    final menus = sent.last.arguments as Map<Object?, Object?>;
    final out = <Map<Object?, Object?>>[];
    void walk(Object? node) {
      if (node is! Map) return;
      out.add(node);
      (node['children'] as List? ?? const <Object?>[]).forEach(walk);
    }

    (menus['0']! as List).forEach(walk);
    return out;
  }

  Map<Object?, Object?> itemLabelled(String label) =>
      items().firstWhere((item) => item['label'] == label);

  testWidgets('a command that can run is enabled, with its key', (
    tester,
  ) async {
    await tester.pumpWidget(host({AppCommand.newNote: () {}}));

    final newNote = itemLabelled(appMenuLabel(AppCommand.newNote));
    expect(newNote['enabled'], true);
    // ⌘N on a Mac.
    expect(
      newNote['shortcutCharacter'] ?? newNote['shortcutTrigger'],
      isNotNull,
    );
    expect(itemLabelled(appMenuLabel(AppCommand.closeTab))['enabled'], false);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets("a key the note needs first is not the menu's", (tester) async {
    await tester.pumpWidget(host({AppCommand.toggleSidebar: () {}}));

    // ⌘B is bold in the note: the sidebar keeps its key, the menu shows none.
    final sidebar = itemLabelled(appMenuLabel(AppCommand.toggleSidebar));
    expect(sidebar['shortcutTrigger'], isNull);
    expect(sidebar['shortcutCharacter'], isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('the menus go to the system again only when they change', (
    tester,
  ) async {
    final handlers = <AppCommand, VoidCallback>{AppCommand.newNote: () {}};
    // PlatformMenuBar itself sends on its first update whatever changed:
    // what is held here is that the shell's frames after it send nothing.
    await tester.pumpWidget(host(handlers));
    await tester.pumpWidget(host(handlers));
    final first = sent.length;

    await tester.pumpWidget(host(handlers));
    expect(sent.length, first);

    await tester.pumpWidget(host({...handlers, AppCommand.closeTab: () {}}));
    expect(sent.length, greaterThan(first));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('elsewhere there is no menu bar', (tester) async {
    await tester.pumpWidget(host({AppCommand.newNote: () {}}));
    expect(find.byType(PlatformMenuBar), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
