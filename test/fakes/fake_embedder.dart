// A platform text input that behaves like the three embedders Niman ships on,
// for tests that must hold the *pair* — the note and the platform's copy of
// it — and not only the note.
//
// Every bug the source surface's device runs found was a disagreement between
// the two: the platform typing at a caret it was never told about, deleting
// before it, inserting a line break the surface then inserted again. A mock
// that records calls cannot see any of that, because it has no copy. This one
// has:
// its own text, selection and composing range, updated by `setEditingState` and
// by its own edits, and every delta it sends is computed from **its** copy —
// `oldText` in full, the way Android's `TextEditingDelta.toJSON` sends it.
//
// What each profile does is read from the embedders' own sources, not guessed:
//
// * **Linux** (`fl_text_input_handler.cc`): a key reaches the framework first.
//   Unhandled, Enter inserts `\n` into the embedder's model, sends it as a delta
//   and *then* calls the `newline` action; Home/End move the embedder's own
//   caret to the text's ends; Backspace, Delete and the arrows are "already
//   handled inside the framework" and do nothing.
// * **Windows** (`text_input_plugin.cc`): only Enter is handled, the same
//   way as Linux; and `setClient` without a `viewId` is refused.
// * **Android**: a hardware key reaches the framework first; the soft keyboard
//   types and deletes through its `InputConnection`, at its own selection.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which platform the fake behaves like.
enum EmbedderProfile {
  /// The GTK embedder.
  linux,

  /// The Win32 embedder.
  windows,

  /// Android, with a soft keyboard (Gboard-like: no composing range).
  android,
}

/// The platform side of text input, with a copy of its own.
final class FakeEmbedder {
  /// A fake for [profile], driven through [tester].
  new(this.tester, this.profile);

  /// The test the fake belongs to.
  final WidgetTester tester;

  /// Which embedder this is.
  final EmbedderProfile profile;

  /// The platform's copy of the text.
  String text = '';

  /// The platform's copy of the selection.
  TextSelection selection = const TextSelection.collapsed(offset: 0);

  /// The platform's copy of the composing range.
  TextRange composing = TextRange.empty;

  /// Whether a client is set.
  bool attached = false;

  /// Whether the keyboard was asked for since the last `hide`.
  bool shown = false;

  /// How many times the framework sent the whole value.
  int editingStates = 0;

  /// How many times the keyboard was asked for.
  int shows = 0;

  /// The configuration the last `setClient` carried.
  Map<String, dynamic>? configuration;

  /// The errors the fake answered with, the way the embedder would.
  final List<String> errors = <String>[];

  /// When true, `setEditingState` is held back until [flush], so a test can
  /// have the platform act on a copy that predates what the app told it.
  bool holdEchoes = false;

  final List<Map<String, dynamic>> _held = <Map<String, dynamic>>[];

  /// Installs the fake on the text input channel for the rest of the test.
  void install() {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.textInput,
      _handle,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        null,
      ),
    );
  }

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'TextInput.setClient':
        final args = call.arguments as List<dynamic>;
        final config = (args[1] as Map).cast<String, dynamic>();
        if (profile == EmbedderProfile.windows && config['viewId'] == null) {
          errors.add('Could not set client, view ID is null.');
          throw PlatformException(
            code: 'Bad Arguments',
            message: 'Could not set client, view ID is null.',
          );
        }
        configuration = config;
        attached = true;
      case 'TextInput.clearClient':
        attached = false;
      case 'TextInput.show':
        shown = true;
        shows++;
      case 'TextInput.hide':
        shown = false;
      case 'TextInput.setEditingState':
        if (!attached) {
          errors.add(
            'Set editing state has been invoked, but no client is set.',
          );
          throw PlatformException(
            code: 'Internal Consistency Error',
            message:
                'Set editing state has been invoked, but no client is set.',
          );
        }
        final value = (call.arguments as Map).cast<String, dynamic>();
        if (holdEchoes) {
          _held.add(value);
        } else {
          _adopt(value);
        }
    }
    return null;
  }

  void _adopt(Map<String, dynamic> encoded) {
    final value = TextEditingValue.fromJSON(encoded);
    editingStates++;
    text = value.text;
    selection = value.selection;
    composing = value.composing;
  }

  /// Delivers the echoes held back by [holdEchoes], in order.
  void flush() {
    _held
      ..forEach(_adopt)
      ..clear();
  }

  // ------------------------------------------------------------ the platform

  /// Sends one delta computed from this copy: `[start, end)` replaced with
  /// [insert], the caret after it.
  Future<void> _edit(int start, int end, String insert) async {
    final old = text;
    text = old.replaceRange(start, end, insert);
    selection = TextSelection.collapsed(offset: start + insert.length);
    composing = TextRange.empty;
    await _send(<Map<String, dynamic>>[
      <String, dynamic>{
        'oldText': old,
        'deltaStart': start,
        'deltaEnd': end,
        'deltaText': insert,
        'selectionBase': selection.baseOffset,
        'selectionExtent': selection.extentOffset,
        'composingBase': -1,
        'composingExtent': -1,
      },
    ]);
  }

  /// A caret move the platform made itself.
  Future<void> _moveTo(int offset) async {
    selection = TextSelection.collapsed(offset: offset);
    await _send(<Map<String, dynamic>>[
      <String, dynamic>{
        'oldText': text,
        'deltaStart': -1,
        'deltaEnd': -1,
        'deltaText': '',
        'selectionBase': offset,
        'selectionExtent': offset,
        'composingBase': -1,
        'composingExtent': -1,
      },
    ]);
  }

  Future<void> _send(List<Map<String, dynamic>> deltas) async {
    await _fromPlatform(
      MethodCall('TextInputClient.updateEditingStateWithDeltas', <dynamic>[
        -1,
        <String, dynamic>{'deltas': deltas},
      ]),
    );
  }

  Future<void> _action(String action) => _fromPlatform(
    MethodCall('TextInputClient.performAction', <dynamic>[-1, action]),
  );

  /// Closes the connection from the platform's side (the keyboard dismissed,
  /// the activity paused).
  Future<void> closeConnection() async {
    attached = false;
    await _fromPlatform(
      const MethodCall('TextInputClient.onConnectionClosed', <dynamic>[-1]),
    );
  }

  Future<void> _fromPlatform(MethodCall call) async {
    // The platform's direction: `channelBuffers.push`, which is what the
    // engine does (the messenger's mock handlers are the other direction).
    ServicesBinding.instance.channelBuffers.push(
      SystemChannels.textInput.name,
      const JSONMethodCodec().encodeMethodCall(call),
      (_) {},
    );
    await tester.idle();
  }

  // ---------------------------------------------------------------- the user

  /// Types [characters] one keystroke at a time, the way an IME commits them.
  ///
  /// A printable character is not a shortcut anywhere in the app, so it goes
  /// straight to the platform's input on every embedder.
  Future<void> type(String characters) async {
    for (final unit in characters.split('')) {
      await _edit(selection.start, selection.end, unit);
    }
  }

  /// Composes [word] one keystroke at a time, the way an IME with a composing
  /// region does it (a Windows IME, Android keyboards other than Gboard): each
  /// step replaces the whole region, and the region travels with the delta.
  Future<void> compose(String word) async {
    final start = selection.start;
    for (var length = 1; length <= word.length; length++) {
      final old = text;
      final end = composing.isValid ? composing.end : start;
      final piece = word.substring(0, length);
      text = old.replaceRange(start, end, piece);
      selection = TextSelection.collapsed(offset: start + length);
      composing = TextRange(start: start, end: start + length);
      await _send(<Map<String, dynamic>>[
        <String, dynamic>{
          'oldText': old,
          'deltaStart': start,
          'deltaEnd': end,
          'deltaText': piece,
          'selectionBase': selection.baseOffset,
          'selectionExtent': selection.extentOffset,
          'composingBase': composing.start,
          'composingExtent': composing.end,
        },
      ]);
    }
  }

  /// Ends a composition: the text stays, the region goes.
  Future<void> commit() async {
    composing = TextRange.empty;
    await _send(<Map<String, dynamic>>[
      <String, dynamic>{
        'oldText': text,
        'deltaStart': -1,
        'deltaEnd': -1,
        'deltaText': '',
        'selectionBase': selection.baseOffset,
        'selectionExtent': selection.extentOffset,
        'composingBase': -1,
        'composingExtent': -1,
      },
    ]);
  }

  /// Presses Enter.
  Future<void> enter() async {
    if (profile == EmbedderProfile.android) {
      // The soft keyboard commits the line break as text.
      await _edit(selection.start, selection.end, '\n');
      return;
    }
    if (await tester.sendKeyEvent(LogicalKeyboardKey.enter)) return;
    // Unhandled by the framework: the embedder inserts it and then asks for
    // the action — both, in this order.
    await _edit(selection.start, selection.end, '\n');
    await _action('TextInputAction.newline');
  }

  /// Presses Backspace.
  ///
  /// On the desktop the key is the framework's or nobody's; on Android the
  /// soft keyboard deletes through its connection, before *its* caret.
  Future<void> backspace() async {
    if (profile == EmbedderProfile.android) {
      if (!selection.isCollapsed) {
        await _edit(selection.start, selection.end, '');
      } else if (selection.start > 0) {
        await _edit(selection.start - 1, selection.start, '');
      }
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
  }

  /// Presses [key] on a hardware keyboard: the framework first, then whatever
  /// this embedder does with a key the framework left alone.
  Future<bool> press(LogicalKeyboardKey key) async {
    final handled = await tester.sendKeyEvent(key);
    if (handled) return true;
    if (profile == EmbedderProfile.linux) {
      if (key == LogicalKeyboardKey.home) await _moveTo(0);
      if (key == LogicalKeyboardKey.end) await _moveTo(text.length);
    }
    if (key == LogicalKeyboardKey.enter) {
      await _edit(selection.start, selection.end, '\n');
      await _action('TextInputAction.newline');
    }
    return false;
  }
}
