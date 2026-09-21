// The IME probe, verified by driving it through the platform channel the way
// Android does: a delta-model update, a whole-value update, an action, and the
// connection closing. The probe's *answers* come from a device (that is what it
// is for); what a test can hold is that it applies what it is handed and writes
// down what it saw.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/text_input_probe.dart';

/// The message the framework's own handler answers to for delta updates
/// (`TextInputClient.updateEditingStateWithDeltas`): the client id and a map of
/// encoded deltas, exactly as `TextEditingDelta.fromJSON` reads them.
Future<void> _fromPlatform(WidgetTester tester, MethodCall call) async {
  // `channelBuffers.push` is the engine's own direction: a message from the
  // platform to the framework. The test messenger's mock handlers are for the
  // other one (`tester.testTextInput` answers those), so an injected delta has
  // to arrive here.
  ServicesBinding.instance.channelBuffers.push(
    'flutter/textinput',
    const JSONMethodCodec().encodeMethodCall(call),
    (_) {},
  );
  await tester.pump();
}

Future<void> _sendDelta(
  WidgetTester tester, {
  required String oldText,
  required int start,
  required int end,
  required String text,
  int caret = 0,
  int composingStart = -1,
  int composingEnd = -1,
}) => _fromPlatform(
  tester,
  MethodCall('TextInputClient.updateEditingStateWithDeltas', <dynamic>[
    -1,
    <String, dynamic>{
      'deltas': <dynamic>[
        <String, dynamic>{
          'oldText': oldText,
          'deltaStart': start,
          'deltaEnd': end,
          'deltaText': text,
          'selectionBase': caret,
          'selectionExtent': caret,
          'composingBase': composingStart,
          'composingExtent': composingEnd,
        },
      ],
    },
  ]),
);

String _state(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('input-probe-state'))).data!;

/// Whether the log lists an event starting with [prefix].
bool _logged(WidgetTester tester, String prefix) => tester
    .widgetList<Text>(find.byType(Text))
    .any((widget) => widget.data?.startsWith(prefix) ?? false);

/// Whether a line starting with [prefix] also contains [contains].
///
/// The framework decides whether a delta is an insertion, a deletion or a
/// replacement (`TextEditingDelta.fromJSON` compares the replaced text with the
/// replacement), and the probe's job is to apply and record whichever it is
/// handed — so a test of the *probe* asks for the range, not for the taxonomy.
bool _loggedWith(WidgetTester tester, String prefix, String contains) => tester
    .widgetList<Text>(find.byType(Text))
    .any(
      (widget) =>
          (widget.data?.startsWith(prefix) ?? false) &&
          (widget.data?.contains(contains) ?? false),
    );

/// Pumps the probe on a viewport tall enough that its whole list is laid out:
/// the area to type in sits below the instructions, and a `ListView` does not
/// build what is off screen.
Future<void> _pumpProbe(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: TextInputProbeScreen()));
  await tester.pump();
}

void main() {
  testWidgets('it attaches, and applies the deltas a platform sends', (
    tester,
  ) async {
    await _pumpProbe(tester);
    await tester.tap(find.byKey(const Key('input-probe-area')));
    await tester.pump();
    expect(_state(tester), contains('text 0 chars'));
    expect(_logged(tester, 'attach deltaModel=true'), isTrue);

    // Typing "cia" — one delta per character, as Android sends them.
    await _sendDelta(
      tester,
      oldText: '',
      start: 0,
      end: 0,
      text: 'c',
      caret: 1,
    );
    await _sendDelta(
      tester,
      oldText: 'c',
      start: 1,
      end: 1,
      text: 'i',
      caret: 2,
    );
    await _sendDelta(
      tester,
      oldText: 'ci',
      start: 2,
      end: 2,
      text: 'a',
      caret: 3,
    );
    expect(_state(tester), contains('text 3 chars'));
    expect(_state(tester), contains('selection 3..3'));
    expect(_logged(tester, 'DELTA insert @2 +"a"'), isTrue);

    // A word being composed: the composing range travels with the delta.
    await _sendDelta(
      tester,
      oldText: 'cia',
      start: 0,
      end: 3,
      text: 'ciao',
      caret: 4,
      composingStart: 0,
      composingEnd: 4,
    );
    expect(_state(tester), contains('composing 0..4'));
    expect(_loggedWith(tester, 'DELTA ', 'comp 0..4'), isTrue);
  });

  testWidgets('a whole-value update is applied and its size recorded', (
    tester,
  ) async {
    await _pumpProbe(tester);
    // The fallback path: the platform sends the entire text.
    await tester.tap(find.byKey(const Key('input-probe-area')));
    await tester.pump();
    await _fromPlatform(
      tester,
      const MethodCall('TextInputClient.updateEditingState', <dynamic>[
        -1,
        <String, dynamic>{
          'text': 'autocorrected',
          'selectionBase': 13,
          'selectionExtent': 13,
          'composingBase': -1,
          'composingExtent': -1,
        },
      ]),
    );
    expect(_state(tester), contains('text 13 chars'));
    expect(_logged(tester, 'WHOLE 13 chars'), isTrue);
  });

  testWidgets('a stale delta is caught rather than applied blind', (
    tester,
  ) async {
    await _pumpProbe(tester);
    await tester.tap(find.byKey(const Key('input-probe-area')));
    await tester.pump();
    // The probe's buffer is empty; the platform thinks it holds "abc". The
    // design's guard says the platform's copy wins and the mismatch is worth
    // saying out loud — this is the case that writes the wrong bytes to disk.
    await _sendDelta(
      tester,
      oldText: 'abc',
      start: 3,
      end: 3,
      text: 'd',
      caret: 4,
    );
    expect(_logged(tester, 'STALE delta'), isTrue);
    expect(_state(tester), contains('text 4 chars'));
  });

  testWidgets('Enter inserts a newline and the platform can close us', (
    tester,
  ) async {
    await _pumpProbe(tester);
    await tester.tap(find.byKey(const Key('input-probe-area')));
    await tester.pump();
    await _fromPlatform(
      tester,
      const MethodCall('TextInputClient.performAction', <dynamic>[
        -1,
        'TextInputAction.newline',
      ]),
    );
    expect(_state(tester), contains('text 1 chars'));
    expect(_logged(tester, 'ACTION newline'), isTrue);

    await _fromPlatform(
      tester,
      const MethodCall('TextInputClient.onConnectionClosed', <dynamic>[-1]),
    );
    expect(_logged(tester, 'CLOSED by the platform'), isTrue);
  });
}
