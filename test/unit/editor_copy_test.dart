// #161: what reaches the clipboard from the source editor.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/markdown_editing_controller.dart';
import 'package:re_editor/re_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? copied;
  setUp(() {
    copied = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
  });

  MarkdownEditingController controllerOver(String text) {
    final controller = MarkdownEditingController(
      delegate: CodeLineEditingController.fromText(text),
      isPlain: (_) => true,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  const note = 'first line\nsecond line\nthird line';

  test('a partial selection copies what is selected', () async {
    final controller = controllerOver(note)
      ..selection = const CodeLineSelection(
        baseIndex: 0,
        baseOffset: 0,
        extentIndex: 1,
        extentOffset: 6,
      );
    await controller.copy();
    expect(copied, 'first line\nsecond');
  });

  test('select all copies the whole note', () async {
    final controller = controllerOver(note)..selectAll();
    expect(controller.selection.isCollapsed, isFalse);
    await controller.copy();
    expect(copied, note);
  });

  test('a collapsed caret copies its own line, whole', () async {
    final controller = controllerOver(note)
      ..selection = const CodeLineSelection.collapsed(index: 1, offset: 3);
    await controller.copy();
    expect(copied, 'second line\n');
  });
}
