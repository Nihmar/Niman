/// The IME probe: what an Android keyboard actually sends (§8.7.1's spike).
///
/// Phase 3's gate, and it is a *gate* rather than a chore because the framework
/// does not exercise the path this surface depends on: nothing under
/// `packages/flutter/lib/` sets `enableDeltaModel: true`, and `EditableText`
/// does not implement `DeltaTextInputClient` — only the two `services` files
/// reference it. So whether a delta model delivers deltas on a real Gboard,
/// what it does with a word being composed, whether autocorrect arrives as a
/// replacement or as a whole value, and what `setEditingState` costs when the
/// note is 934 KB are questions a device answers, not a source tree.
///
/// This screen is that device's microphone: it owns a bare
/// [TextInputConnection] and writes down every event it is handed, on screen
/// and in the app log (logger `input`, exported from Settings → Diagnostics).
/// The instructions are on the screen itself, in English: it is a maintainer's
/// tool, not a surface a user meets, and `AppStrings` would need 38
/// translations for a screen that exists for one afternoon.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/logging.dart';

/// A screen that talks to the platform's text input directly and records what
/// comes back.
final class TextInputProbeScreen extends StatefulWidget {
  /// Creates the probe.
  const new({super.key});

  @override
  State<TextInputProbeScreen> createState() => _TextInputProbeScreenState();
}

final class _TextInputProbeScreenState extends State<TextInputProbeScreen>
    with TextInputClient, DeltaTextInputClient {
  static const AppLogger _log = AppLogger(name: 'input');

  /// How many events stay on screen (the log file keeps them all).
  static const int _kept = 40;

  /// The buffer the platform and this screen agree on.
  TextEditingValue _value = TextEditingValue.empty;

  /// Whether the connection asks for the delta model. Flipping it reconnects,
  /// because the flag is part of the configuration.
  bool _deltaModel = true;

  /// Whether a keyboard is attached right now.
  bool _attached = false;

  /// What came back, newest first.
  final List<String> _events = <String>[];

  /// The last `setEditingState` cost, which is the whole-value echo's price.
  Duration? _lastSend;

  /// [_lastSend] as a number of milliseconds, for the state line.
  int get _sent => _lastSend?.inMilliseconds ?? 0;

  /// The text area, for the transform Android needs to place the keyboard.
  final GlobalKey _area = GlobalKey();

  TextInputConnection? _connection;

  @override
  void dispose() {
    // Not `_detach`: that updates the screen, and a disposed state may not.
    _connection?.close();
    _connection = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Text input probe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'What to do, with the keyboard that matters (Gboard on Android):',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Tap the box below and type a few words. Do the letters arrive '
            'as DELTA lines or as WHOLE ones?\n'
            '2. While a word is still being suggested (underlined), keep '
            'typing: does the composing range move?\n'
            '3. Let autocorrect change a word: DELTA or WHOLE?\n'
            '4. Delete a letter, then a whole word (backspace held).\n'
            '5. Move the caret by tapping inside a word, and by dragging.\n'
            '6. Press Enter (an ACTION line), then close the keyboard with the '
            'back gesture (a CLOSED line).\n'
            '7. Turn "delta model" off and do 1-3 again — the whole-value path '
            'is the fallback and has to work too.\n'
            '8. Tap "fill 900 KB" and type one character: the WHOLE lines then '
            'carry that many chars, which is what the design calls untenable.',
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            key: const Key('input-probe-delta'),
            contentPadding: EdgeInsets.zero,
            value: _deltaModel,
            title: const Text('delta model (enableDeltaModel)'),
            subtitle: const Text('off = the whole-TextEditingValue fallback'),
            onChanged: (on) {
              setState(() => _deltaModel = on);
              if (_attached) {
                _detach();
                _attach();
              }
            },
          ),
          Row(
            children: <Widget>[
              FilledButton.tonal(
                key: const Key('input-probe-fill'),
                onPressed: () => _fill(900 * 1024),
                child: const Text('fill 900 KB'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                key: const Key('input-probe-clear-text'),
                onPressed: () => _setValue(TextEditingValue.empty),
                child: const Text('clear text'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                key: const Key('input-probe-clear-log'),
                onPressed: () => setState(_events.clear),
                child: const Text('clear log'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'text ${_value.text.length} chars · '
            'selection ${_value.selection.start}..${_value.selection.end} · '
            'composing ${_value.composing.start}..${_value.composing.end}'
            '${_lastSend == null ? '' : ' · send $_sent ms'}',
            key: const Key('input-probe-state'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            _tally,
            key: const Key('input-probe-tally'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            key: const Key('input-probe-area'),
            onTap: _attach,
            child: Container(
              // The box Android is told about (`setEditableSizeAndTransform`).
              key: _area,
              height: 160,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _attached
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                ),
              ),
              child: SingleChildScrollView(
                // The text, with the **composing range underlined** when the
                // platform reports one: if the keyboard underlines the word
                // being typed and this does not, the IME is composing and the
                // range is not reaching the app — which is the one question the
                // first device run could not answer by reading event lines
                // alone (2026-09-21: 56 deltas, not one composing range).
                child: Text.rich(
                  _display(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('events (newest first)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          for (final event in _events)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                event,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          if (_events.isEmpty)
            const Text(
              'nothing yet — tap the box above',
              style: TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 24),
          Text(
            'The same lines are in the app log under [input]: share it from '
            'Settings → Diagnostics.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- the connection

  /// Opens the connection, asking for the delta model or the whole-value one.
  void _attach() {
    if (_attached) return;
    final connection = TextInput.attach(
      this,
      TextInputConfiguration(
        enableDeltaModel: _deltaModel,
        inputType: TextInputType.multiline,
        inputAction: TextInputAction.newline,
      ),
    );
    _connection = connection;
    _send();
    connection.show();
    // Android places its keyboard, cursor handle and magnifier from the box's
    // transform and the caret's rect. The caret rect here is the top-left of
    // the area, which is enough for the questions this screen asks (it is *not*
    // enough for the handle to follow the caret, which the real surface will
    // feed from its own caret geometry).
    final box = _area.currentContext?.findRenderObject();
    if (box is RenderBox) {
      final origin = box.localToGlobal(Offset.zero);
      final transform = Matrix4.identity()
        ..translateByDouble(origin.dx, origin.dy, 0, 1);
      connection
        ..setEditableSizeAndTransform(box.size, transform)
        ..setCaretRect(Rect.fromLTWH(origin.dx, origin.dy, 2, box.size.height));
    }
    setState(() => _attached = true);
    _record('attach deltaModel=$_deltaModel chars=${_value.text.length}');
  }

  /// Closes the connection; the keyboard goes with it.
  void _detach() {
    final connection = _connection;
    _connection = null;
    connection?.close();
    if (!_attached) return;
    _attached = false;
    _record('detach (connection closed)');
    if (mounted) setState(() {});
  }

  /// Hands the platform the whole value, and times what that costs to
  /// hand over — the number the design calls untenable at note size.
  void _send() {
    final connection = _connection;
    if (connection == null) return;
    final clock = Stopwatch()..start();
    connection.setEditingState(_value);
    clock.stop();
    _lastSend = clock.elapsed;
  }

  /// Replaces the buffer and tells the platform.
  void _setValue(TextEditingValue value) {
    setState(() => _value = value);
    _send();
  }

  /// Fills the buffer with roughly [bytes] of text, so the echo has a size to
  /// carry: the line of a real note is what the design calls untenable.
  void _fill(int bytes) {
    const sentence = 'the quick brown fox jumps over the lazy dog. ';
    final buffer = StringBuffer();
    while (buffer.length < bytes) {
      buffer.write(sentence);
    }
    final text = buffer.toString().substring(0, bytes);
    _record('fill ${text.length} chars');
    _setValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
  }

  /// The buffer as it is shown, with the composing range underlined.
  TextSpan _display() {
    if (_value.text.isEmpty) return const TextSpan(text: 'tap here and type');
    final text = _value.text;
    final shown = text.length > 4000 ? text.substring(0, 4000) : text;
    final composing = _value.composing;
    if (!composing.isValid ||
        composing.isCollapsed ||
        composing.end > shown.length) {
      return TextSpan(text: shown);
    }
    return TextSpan(
      children: <TextSpan>[
        TextSpan(text: shown.substring(0, composing.start)),
        TextSpan(
          text: shown.substring(composing.start, composing.end),
          style: const TextStyle(decoration: TextDecoration.underline),
        ),
        TextSpan(text: shown.substring(composing.end)),
      ],
    );
  }

  /// One line under the text: how many of each kind of update has arrived.
  ///
  /// A screenshot of this is the answer to "does the delta model work here" —
  /// and to "is a word ever composed" — without reading a log.
  String get _tally =>
      'delta $_deltaCount · whole $_wholeCount · '
      'composing $_composingCount · replace $_replaceCount';

  int _deltaCount = 0;
  int _wholeCount = 0;
  int _composingCount = 0;
  int _replaceCount = 0;

  /// Writes [line] on screen and in the app log.
  void _record(String line) {
    _log.info(line);
    if (!mounted) return;
    setState(() {
      _events.insert(0, line);
      if (_events.length > _kept) _events.removeLast();
    });
  }

  /// One line for a delta, with everything the spike is asking about.
  String _describe(TextEditingDelta delta) => switch (delta) {
    TextEditingDeltaInsertion() =>
      'DELTA insert @${delta.insertionOffset} '
          '+"${_short(delta.textInserted)}" '
          'sel ${delta.selection.start}..${delta.selection.end} '
          'comp ${delta.composing.start}..${delta.composing.end}',
    TextEditingDeltaDeletion() =>
      'DELTA delete ${delta.deletedRange.start}..${delta.deletedRange.end} '
          'sel ${delta.selection.start}..${delta.selection.end} '
          'comp ${delta.composing.start}..${delta.composing.end}',
    TextEditingDeltaReplacement() =>
      'DELTA replace ${delta.replacedRange.start}..${delta.replacedRange.end} '
          '+"${_short(delta.replacementText)}" '
          'sel ${delta.selection.start}..${delta.selection.end} '
          'comp ${delta.composing.start}..${delta.composing.end}',
    TextEditingDeltaNonTextUpdate() =>
      'DELTA non-text sel ${delta.selection.start}..${delta.selection.end} '
          'comp ${delta.composing.start}..${delta.composing.end}',
    _ => 'DELTA ${delta.runtimeType}',
  };

  static String _short(String text) =>
      text.length > 24 ? '${text.substring(0, 24)}…' : text;

  /// One line for a whole-value update: the size is the point of the line.
  String _describeValue(TextEditingValue value) =>
      'WHOLE ${value.text.length} chars '
      'sel ${value.selection.start}..${value.selection.end} '
      'comp ${value.composing.start}..${value.composing.end}';

  // -------------------------------------------------------- TextInputClient

  @override
  TextEditingValue? get currentTextEditingValue => _value;

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void updateEditingValue(TextEditingValue value) {
    _wholeCount += 1;
    if (value.composing.isValid && !value.composing.isCollapsed) {
      _composingCount += 1;
    }
    _record(_describeValue(value));
    _setValue(value);
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> deltas) {
    var value = _value;
    for (final delta in deltas) {
      _deltaCount += 1;
      if (delta is TextEditingDeltaReplacement) _replaceCount += 1;
      if (delta.composing.isValid && !delta.composing.isCollapsed) {
        _composingCount += 1;
      }
      _record(_describe(delta));
      // The design's staleness guard, and the reason it is worth watching on a
      // device: a delta describes the platform's copy, not ours (`oldText`),
      // and applying one to a buffer it does not belong to writes the wrong
      // bytes to disk.
      if (delta.oldText != value.text) {
        _record(
          'STALE delta: oldText ${delta.oldText.length} chars, '
          'ours ${value.text.length}',
        );
        value = TextEditingValue(
          text: delta.oldText,
          selection: delta.selection,
          composing: delta.composing,
        );
      }
      value = delta.apply(value);
    }
    _setValue(value);
  }

  @override
  void performAction(TextInputAction action) {
    _record('ACTION ${action.name}');
    if (action != TextInputAction.newline) return;
    final at = _value.selection.isValid
        ? _value.selection
        : TextSelection.collapsed(offset: _value.text.length);
    _record('  → newline at ${at.start}');
    _setValue(
      TextEditingValue(
        text: _value.text.replaceRange(at.start, at.end, '\n'),
        selection: TextSelection.collapsed(offset: at.start + 1),
      ),
    );
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) =>
      _record('PRIVATE $action $data');

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) =>
      _record('FLOATING ${point.state.name} ${point.offset}');

  @override
  void showAutocorrectionPromptRect(int start, int end) =>
      _record('PROMPT RECT $start..$end');

  @override
  void connectionClosed() {
    _record('CLOSED by the platform');
    if (_attached) setState(() => _attached = false);
    _connection = null;
  }
}
