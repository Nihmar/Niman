import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/selection_delegate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The platform clipboard behind [SystemChannels.platform] (the same
/// encoding the real [Clipboard] uses: `{'text': ...}` maps).
class _FakeClipboard {
  _FakeClipboard(this.binding);

  final TestWidgetsFlutterBinding binding;

  String? text;
  bool pasteable = false;

  void install() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            text = (call.arguments as Map)['text'] as String?;
            return null;
          case 'Clipboard.getData':
            return text == null
                ? null
                : <String, dynamic>{'text': text};
          case 'Clipboard.hasStrings':
            return <String, dynamic>{'value': pasteable};
          default:
            return null;
        }
      },
    );
  }
}

NoteSelectionDelegate _delegate(
  ComposingInput input, {
  VoidCallback? onSelectAll,
  VoidCallback? onCut,
  Future<void> Function(String text)? onPaste,
  void Function(TextPosition position)? onBringIntoView,
  VoidCallback? onHide,
}) {
  return NoteSelectionDelegate(
    input: input,
    onSelectAll: onSelectAll ?? () {},
    onCut: onCut ?? () {},
    onPaste: onPaste ?? (text) async {},
    onBringIntoView: onBringIntoView ?? (position) {},
    onHide: onHide ?? () {},
  );
}

ComposingInput _selected(String text, TextSelection selection) {
  final input = ComposingInput(text)..setSelection(selection);
  return input;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeClipboard clipboard;

  setUp(() {
    clipboard = _FakeClipboard(binding)..install();
  });

  tearDown(() {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('copySelection copies the selection to the clipboard', () {
    var hidden = 0;
    final input = _selected(
      'hello world',
      const TextSelection(baseOffset: 0, extentOffset: 5),
    );
    final delegate = _delegate(input, onHide: () => hidden++);
    expect(delegate.copyEnabled, isTrue);

    delegate.copySelection(SelectionChangedCause.toolbar);

    expect(clipboard.text, 'hello');
    // The toolbar cause contract: the UI is hidden by the cause.
    expect(hidden, 1);
    // The buffer is untouched by a copy.
    expect(input.text, 'hello world');
    expect(input.hasSelection, isTrue);
  });

  test('copySelection with a non-toolbar cause keeps the UI', () {
    var hidden = 0;
    final input = _selected(
      'hello world',
      const TextSelection(baseOffset: 0, extentOffset: 5),
    );
    final delegate = _delegate(input, onHide: () => hidden++);

    // A selection exists, so copy is enabled.
    expect(delegate.copyEnabled, isTrue);

    delegate.copySelection(SelectionChangedCause.tap);

    expect(clipboard.text, 'hello');
    expect(hidden, 0);
  });

  test('cutSelection copies then deletes the selection', () async {
    var cut = 0;
    final input = _selected(
      'hello world',
      const TextSelection(baseOffset: 0, extentOffset: 5),
    );
    final delegate = _delegate(
      input,
      onCut: () {
        cut++;
        input
          ..deleteSelection()
          ..commitDirectEdit();
      },
    );
    // A selection exists, so copy is enabled.
    expect(delegate.copyEnabled, isTrue);

    delegate.cutSelection(SelectionChangedCause.toolbar);
    // The clipboard write is a platform round trip.
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(clipboard.text, 'hello');
    expect(cut, 1);
    expect(input.text, ' world');
  });

  test('pasteText fetches the clipboard and forwards to onPaste', () async {
    clipboard
      ..pasteable = true
      ..text = 'XY';
    final input = _selected(
      'ab',
      const TextSelection.collapsed(offset: 1),
    );
    String? pasted;
    final delegate = _delegate(
      input,
      onPaste: (text) async {
        pasted = text;
        input
          ..replaceSelection(text)
          ..commitDirectEdit();
      },
    );

    await delegate.pasteText(SelectionChangedCause.toolbar);

    expect(pasted, 'XY');
    expect(input.text, 'aXYb');
  });

  test('pasteText with an empty clipboard is a no-op', () async {
    clipboard.pasteable = true;
    final input = _selected(
      'ab',
      const TextSelection.collapsed(offset: 1),
    );
    final delegate = _delegate(input);

    await delegate.pasteText(SelectionChangedCause.toolbar);

    expect(input.text, 'ab');
  });

  test('selectAll forwards to the select-all callback', () {
    var selectedAll = 0;
    final input = ComposingInput('abcd');
    final delegate = _delegate(input, onSelectAll: () => selectedAll++);
    expect(delegate.copyEnabled, isFalse);

    delegate.selectAll(SelectionChangedCause.toolbar);

    expect(selectedAll, 1);
  });

  test('bringIntoView forwards to the callback', () {
    var forwarded = false;
    final input = ComposingInput('abcd');
    final delegate = _delegate(
      input,
      onBringIntoView: (position) => forwarded = true,
    );
    expect(delegate.copyEnabled, isFalse);

    delegate.bringIntoView(const TextPosition(offset: 2));

    expect(forwarded, isTrue);
  });

  test('hideToolbar hides the UI', () {
    var hidden = 0;
    final input = ComposingInput('abcd');
    final delegate = _delegate(input, onHide: () => hidden++);
    expect(delegate.copyEnabled, isFalse);

    delegate.hideToolbar();

    expect(hidden, 1);
  });

  test('userUpdateTextEditingValue moves only the selection', () {
    final input = ComposingInput('abcd');
    final delegate = _delegate(input);
    expect(delegate.copyEnabled, isFalse);

    delegate.userUpdateTextEditingValue(
      const TextEditingValue(
        text: 'WRONG', // The platform's text is ignored (ours is the truth).
        selection: TextSelection(baseOffset: 2, extentOffset: 3),
      ),
      SelectionChangedCause.toolbar,
    );

    expect(input.text, 'abcd');
    expect(
      input.selection,
      const TextSelection(baseOffset: 2, extentOffset: 3),
    );
  });

  test('copyEnabled/cutEnabled follow the selection', () {
    final input = ComposingInput('abcd');
    final delegate = _delegate(input);

    expect(delegate.copyEnabled, isFalse);
    expect(delegate.cutEnabled, isFalse);
    input.setSelection(const TextSelection(baseOffset: 0, extentOffset: 2));
    expect(delegate.copyEnabled, isTrue);
    expect(delegate.cutEnabled, isTrue);
  });
}
