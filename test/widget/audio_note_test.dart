// Issue #56 AC: a note with the audio frontmatter type shows the
// recordings view; the user can record clips in sequence and play them
// back; audio files live in the library as ordinary files.
//
// The view runs against fakes (no microphone, no speaker, no isolate),
// so these tests prove the sequencing and the note-text edits.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/ui/kinds/audio_chat_list.dart';
import 'package:niman/src/ui/kinds/audio_note.dart';
import 'package:niman/src/ui/kinds/audio_player.dart';
import 'package:niman/src/ui/kinds/audio_recorder.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

final class _FakeRecorder implements VoiceRecorder {
  bool permission = true;
  bool cancelled = false;
  String? startedPath;
  String? stoppedPath = p.join('tmp', 'clip.wav');

  /// How many times the microphone was asked for.
  int permissionAsks = 0;

  /// Holds [start] until completed: a recorder slow to set up (#766).
  Completer<void>? startGate;

  @override
  Future<bool> hasPermission() async {
    permissionAsks++;
    return permission;
  }

  @override
  Future<void> start({required String path}) async {
    await startGate?.future;
    startedPath = path;
  }

  final calls = <String>[];

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<String?> stop() async => stoppedPath;

  @override
  Future<void> cancel() async {
    cancelled = true;
  }

  @override
  void dispose() {}
}

final class _FakePlayer implements ClipPlayer {
  final done = StreamController<void>.broadcast();
  final positions = StreamController<Duration>.broadcast();
  final durations = StreamController<Duration>.broadcast();
  final played = <String>[];
  final seeks = <Duration>[];
  int stops = 0;
  int pauses = 0;
  int resumes = 0;

  @override
  Future<void> play(String absolutePath) async {
    played.add(absolutePath);
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  Future<void> resume() async {
    resumes++;
  }

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Stream<void> get onFinished => done.stream;

  @override
  Stream<Duration> get onPosition => positions.stream;

  @override
  Stream<Duration> get onDuration => durations.stream;

  @override
  void dispose() {
    unawaited(done.close());
    unawaited(positions.close());
    unawaited(durations.close());
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required String text,
  required List<String> edits,
  VoiceRecorder? recorder,
  _FakePlayer? player,
  String? libraryRoot,
  LinkType linkType = LinkType.wikilink,
  Future<String> Function(String, String)? importAudio,
  Future<String?> Function()? pickAudioPath,
  Future<String> Function(String, String)? renameAudio,
  Map<String, Duration> lengths = const {},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AudioNoteView(
          text: text,
          onChanged: edits.add,
          notePath: p.join('root', 'note.md'),
          libraryRoot: libraryRoot ?? p.join('root'),
          linkType: linkType,
          recorder: recorder ?? _FakeRecorder(),
          player: player ?? _FakePlayer(),
          pickAudioPath: pickAudioPath,
          importAudio:
              importAudio ?? ((_, _) async => p.join('assets', 'imported.wav')),
          renameAudio: renameAudio,
          newRecordPath: () async => p.join('tmp', 'rec.wav'),
          readLengths: (paths) async => {
            for (final path in paths) path: ?lengths[p.basename(path)],
          },
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Pumps an audio note that adopts its own edits, as the kind host does:
/// the recording flow lands in the note and the view rebuilds around it,
/// which is what the scroll tests for #735 need.
Future<void> _pumpLive(
  WidgetTester tester, {
  required String text,
  _FakeRecorder? recorder,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _LiveAudioNote(
          initialText: text,
          recorder: recorder ?? _FakeRecorder(),
        ),
      ),
    ),
  );
  await tester.pump();
}

final class _LiveAudioNote extends StatefulWidget {
  const new({required this.initialText, required this.recorder});

  final String initialText;
  final _FakeRecorder recorder;

  @override
  State<_LiveAudioNote> createState() => _LiveAudioNoteState();
}

final class _LiveAudioNoteState extends State<_LiveAudioNote> {
  late String _text = widget.initialText;
  final _FakePlayer _player = _FakePlayer();

  @override
  Widget build(BuildContext context) => AudioNoteView(
    text: _text,
    onChanged: (text) => setState(() => _text = text),
    notePath: p.join('root', 'note.md'),
    libraryRoot: p.join('root'),
    recorder: widget.recorder,
    player: _player,
    importAudio: (_, _) async => p.join('assets', 'imported.wav'),
    newRecordPath: () async => p.join('tmp', 'rec.wav'),
    readLengths: (_) async => const <String, Duration>{},
  );
}

Future<void> _openClipMenu(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(ValueKey('audio-menu-$index')));
  await tester.pumpAndSettle();
}

/// What the app puts on the clipboard, as it is put there.
List<String> _clipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

void main() {
  /// The scroll of an audio note long enough to scroll, and its position.
  (Finder, ScrollPosition Function()) listOf(WidgetTester tester) {
    final scrollable = find.descendant(
      of: find.byType(AudioChatList),
      matching: find.byType(Scrollable),
    );
    return (
      scrollable,
      () => tester.state<ScrollableState>(scrollable).position,
    );
  }

  /// Records and stops once, as the composer's one button does.
  Future<void> record(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pump();
  }

  // #735: ending a recording brings its turn to the bottom, where its
  // play, rename and transcribe controls are.
  testWidgets('ending a recording brings the new turn to the bottom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Written notes, one turn each: the clip lands as a turn of its own.
    final turns = [for (var i = 0; i < 40; i++) 'turn $i'].join('\n\n');
    await _pumpLive(tester, text: '---\ntype: audio\n---\n$turns\n');
    final (_, position) = listOf(tester);
    expect(
      position().pixels,
      moreOrLessEquals(position().maxScrollExtent, epsilon: 1),
      reason: 'a long note opens at its latest turn',
    );

    await record(tester);
    // The row lands with its own grow animation, and the list keeps the
    // bottom while it grows — and settles once the layout is final.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(
      position().pixels,
      moreOrLessEquals(position().maxScrollExtent, epsilon: 1),
      reason: 'the new turn left the list at the bottom',
    );
    final list = tester.getRect(find.byType(AudioChatList));
    final play = tester.getRect(find.byKey(const ValueKey('audio-play-0')));
    expect(
      play.bottom,
      lessThanOrEqualTo(list.bottom + 0.5),
      reason: 'the new bubble is on screen',
    );
  });

  testWidgets('a reader dragging during the landing is not yanked back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Written notes, one turn each: the clip lands as a turn of its own.
    final turns = [for (var i = 0; i < 40; i++) 'turn $i'].join('\n\n');
    await _pumpLive(tester, text: '---\ntype: audio\n---\n$turns\n');
    final (scrollable, position) = listOf(tester);
    // A little above the bottom, so the new turn comes with a glide
    // (#767): at the bottom there is nothing to glide.
    await tester.drag(scrollable, const Offset(0, 150));
    await tester.pumpAndSettle();

    await record(tester);
    await tester.pump(const Duration(milliseconds: 40));
    expect(
      position().isScrollingNotifier.value,
      isTrue,
      reason: 'the glide to the new turn is under way',
    );
    // The reader takes the list over mid-glide, and it stays where they
    // put it.
    final before = position().pixels;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AudioChatList)),
    );
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    final held = position().pixels;
    expect(
      held,
      lessThan(before),
      reason:
          'the drag moved the list up from where the glide had it, '
          'not from the bottom it was snapped to',
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(position().pixels, moreOrLessEquals(held, epsilon: 1));
    await gesture.up();
    // And once the finger is off, with the landing over (#767): the
    // glide's end is not taken for the reader's, nor pulls them down.
    await tester.pumpAndSettle();
    expect(position().pixels, moreOrLessEquals(held, epsilon: 1));
    expect(position().pixels, lessThan(position().maxScrollExtent - 40));
  });

  // #767: the glide's end is not the reader's, so the jump that finishes
  // it runs for a reader who had scrolled up too.
  testWidgets('a reader scrolled up still gets the new turn at the bottom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final turns = [for (var i = 0; i < 40; i++) 'turn $i'].join('\n\n');
    await _pumpLive(tester, text: '---\ntype: audio\n---\n$turns\n');
    final (scrollable, position) = listOf(tester);
    await tester.drag(scrollable, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(
      position().pixels,
      lessThan(position().maxScrollExtent - 200),
      reason: 'the reader is well above the bottom',
    );

    await record(tester);
    await tester.pumpAndSettle();

    expect(
      position().pixels,
      moreOrLessEquals(position().maxScrollExtent, epsilon: 1),
      reason: 'the glide was finished by the jump',
    );
    final list = tester.getRect(find.byType(AudioChatList));
    final play = tester.getRect(find.byKey(const ValueKey('audio-play-0')));
    expect(play.bottom, lessThanOrEqualTo(list.bottom + 0.5));
  });

  testWidgets('an empty audio note invites a first recording', (tester) async {
    await _pump(tester, text: '---\ntype: audio\n---\n', edits: []);
    expect(find.text('No recordings yet'), findsOneWidget);
    expect(find.byKey(const Key('audio-record-button')), findsOneWidget);
  });

  testWidgets('clips read their title or a numbered name, and their length', (
    tester,
  ) async {
    await _pump(
      tester,
      text:
          '---\ntype: audio\n---\n'
          '> Meeting\n![](assets/a.wav)\n> budget and dates\n\n'
          '![](assets/b.mp3)\n',
      edits: [],
      lengths: {'a.wav': const Duration(seconds: 48)},
    );
    expect(find.text('Meeting'), findsOneWidget);
    expect(find.text('budget and dates'), findsOneWidget);
    expect(find.text('Recording 2'), findsOneWidget);
    // The raw file name stays out of the bubble.
    expect(find.text('a.wav'), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('audio-length-0'))).data,
      '0:48',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('audio-length-1'))).data,
      '--:--',
    );
  });

  testWidgets('play, pause and resume the same clip', (tester) async {
    final player = _FakePlayer();
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n![](assets/a.wav)\n![](assets/b.mp3)\n',
      edits: [],
      player: player,
    );
    await tester.tap(find.byKey(const ValueKey('audio-play-0')));
    await tester.pump();
    expect(
      p.normalize(player.played.single),
      endsWith(p.join('assets', 'a.wav')),
    );
    expect(find.byIcon(Icons.pause), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('audio-play-0')));
    await tester.pump();
    expect(player.pauses, 1);
    expect(find.byIcon(Icons.pause), findsNothing);

    await tester.tap(find.byKey(const ValueKey('audio-play-0')));
    await tester.pump();
    expect(player.resumes, 1);
    expect(player.played, hasLength(1));
  });

  testWidgets('the loaded clip shows its position and seeks on the track', (
    tester,
  ) async {
    final player = _FakePlayer();
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n![](assets/a.mp3)\n',
      edits: [],
      player: player,
    );
    await tester.tap(find.byKey(const ValueKey('audio-play-0')));
    await tester.pump();
    player.durations.add(const Duration(seconds: 40));
    player.positions.add(const Duration(seconds: 12));
    await tester.pump();
    expect(find.text('0:12'), findsOneWidget);
    expect(find.text('0:40'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('audio-progress-0')));
    await tester.pump();
    // The centre of the track is half of the clip.
    expect(player.seeks.single, const Duration(seconds: 20));

    player.done.add(null);
    await tester.pump();
    expect(find.text('0:00'), findsOneWidget);
  });

  testWidgets('an outside edit that drops the playing clip stops it', (
    tester,
  ) async {
    final player = _FakePlayer();
    Widget view(String text) => MaterialApp(
      home: Scaffold(
        body: AudioNoteView(
          text: text,
          onChanged: (_) {},
          notePath: p.join('root', 'note.md'),
          libraryRoot: p.join('root'),
          recorder: _FakeRecorder(),
          player: player,
          readLengths: (_) async => const {},
        ),
      ),
    );
    await tester.pumpWidget(
      view('---\ntype: audio\n---\n![](assets/a.wav)\n\nhello\n'),
    );
    await tester.tap(find.byKey(const ValueKey('audio-play-0')));
    await tester.pump();
    await tester.pumpWidget(view('---\ntype: audio\n---\nhello\n'));
    await tester.pumpAndSettle();
    expect(player.stops, 1);
    expect(find.byKey(const ValueKey('audio-play-0')), findsNothing);
  });

  testWidgets('record appends the imported clip to the note', (tester) async {
    final edits = <String>[];
    final recorder = _FakeRecorder();
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: edits,
      recorder: recorder,
    );

    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pump();
    expect(recorder.startedPath, p.join('tmp', 'rec.wav'));

    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pump();
    // The library writes wikilinks: the clip lands as an embed.
    expect(edits.single, contains('![[${p.join('assets', 'imported.wav')}]]'));
  });

  // #737: the microphone is the messenger's — held to record, released to
  // send, slid up to lock.
  testWidgets('holding the microphone records, and the release saves it', (
    tester,
  ) async {
    final edits = <String>[];
    final recorder = _FakeRecorder();
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: edits,
      recorder: recorder,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('audio-record-button'))),
    );
    // Under the press's own delay nothing has started: it may still be a
    // tap.
    await tester.pump(const Duration(milliseconds: 100));
    expect(recorder.startedPath, isNull);
    // Past it, the hold is the hold: the microphone is live and the bar
    // says how to lock it.
    await tester.pump(const Duration(milliseconds: 100));
    expect(recorder.startedPath, isNotNull);
    expect(find.byKey(const ValueKey('audio-recording-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('audio-lock-hint')), findsOneWidget);

    await gesture.up();
    await tester.pump();
    // The release before any slide is the send.
    expect(edits.single, contains('![[${p.join('assets', 'imported.wav')}]]'));
  });

  testWidgets('a hold slid up locks, and the release leaves it recording', (
    tester,
  ) async {
    final edits = <String>[];
    final recorder = _FakeRecorder();
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: edits,
      recorder: recorder,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('audio-record-button'))),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(find.byKey(const ValueKey('audio-locked')), findsOneWidget);
    expect(find.byKey(const ValueKey('audio-lock-hint')), findsNothing);

    await gesture.up();
    await tester.pump();
    expect(edits, isEmpty, reason: 'the lock kept the recording going');
    expect(find.byKey(const ValueKey('audio-recording-bar')), findsOneWidget);
    // And still says so once the finger is off (#766).
    expect(find.byKey(const ValueKey('audio-locked')), findsOneWidget);

    // The round button, now the stop, saves it on a tap.
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pump();
    expect(edits.single, contains('![[${p.join('assets', 'imported.wav')}]]'));
  });

  testWidgets('sliding back down before the release does not lock', (
    tester,
  ) async {
    final edits = <String>[];
    final recorder = _FakeRecorder();
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: edits,
      recorder: recorder,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('audio-record-button'))),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(find.byKey(const ValueKey('audio-locked')), findsOneWidget);
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    expect(find.byKey(const ValueKey('audio-lock-hint')), findsOneWidget);

    await gesture.up();
    await tester.pump();
    // Nothing was committed until the finger went up.
    expect(edits.single, contains('![[${p.join('assets', 'imported.wav')}]]'));
  });

  // #766: the release acts on what the start did, whenever it lands.
  for (final cancel in [false, true]) {
    testWidgets(
      'a hold ${cancel ? 'cancelled' : 'released'} before the start lands '
      'leaves nothing recording',
      (tester) async {
        final edits = <String>[];
        final recorder = _FakeRecorder()..startGate = Completer<void>();
        await _pump(
          tester,
          text: '---\ntype: audio\n---\n',
          edits: edits,
          recorder: recorder,
        );
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('audio-record-button'))),
        );
        await tester.pump(const Duration(milliseconds: 200));
        // The start is running: the microphone says it cannot be pressed.
        final mic = tester.widget<IconButton>(
          find.byKey(const Key('audio-record-button')),
        );
        expect(mic.onPressed, isNull);

        // The finger leaves (or the permission dialog takes the pointer)
        // before the recorder is ready.
        if (cancel) {
          await gesture.cancel();
        } else {
          await gesture.up();
        }
        await tester.pump();
        recorder.startGate!.complete();
        await tester.pumpAndSettle();

        expect(recorder.startedPath, isNotNull);
        expect(recorder.cancelled, isTrue, reason: 'nothing was said');
        expect(edits, isEmpty);
        expect(
          find.byKey(const ValueKey('audio-recording-bar')),
          findsNothing,
          reason: 'the microphone is not left live, hands-free',
        );
      },
    );
  }

  testWidgets('a hold refused the microphone is not started again on release', (
    tester,
  ) async {
    final recorder = _FakeRecorder()..permission = false;
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: [],
      recorder: recorder,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('audio-record-button'))),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(recorder.permissionAsks, 1);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(recorder.permissionAsks, 1, reason: 'the release is no new start');
  });

  testWidgets('a right-button hold does not record', (tester) async {
    final recorder = _FakeRecorder();
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: [],
      recorder: recorder,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('audio-record-button'))),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(recorder.startedPath, isNull);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(recorder.startedPath, isNull);
  });

  testWidgets('a long hold shows no tooltip under the thumb', (tester) async {
    await _pump(tester, text: '---\ntype: audio\n---\n', edits: []);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('audio-record-button'))),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(AppStrings.audioStop), findsNothing);
    expect(find.text(AppStrings.audioRecord), findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a second finger lifting off does not end the hold', (
    tester,
  ) async {
    final edits = <String>[];
    await _pump(tester, text: '---\ntype: audio\n---\n', edits: edits);
    final center = tester.getCenter(
      find.byKey(const Key('audio-record-button')),
    );
    final first = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('audio-recording-bar')), findsOneWidget);

    final second = await tester.startGesture(center);
    await tester.pump();
    await second.up();
    await tester.pump();
    expect(edits, isEmpty, reason: 'the first finger is still down');
    expect(find.byKey(const ValueKey('audio-recording-bar')), findsOneWidget);

    await first.up();
    await tester.pump();
    expect(edits.single, contains('![[${p.join('assets', 'imported.wav')}]]'));
  });

  testWidgets('a quick tap keeps the start/stop toggle it had', (tester) async {
    final edits = <String>[];
    final recorder = _FakeRecorder();
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: edits,
      recorder: recorder,
    );
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pump();
    expect(recorder.startedPath, isNotNull);
    expect(find.byKey(const ValueKey('audio-recording-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('audio-lock-hint')), findsNothing);

    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pump();
    expect(edits.single, contains('![[${p.join('assets', 'imported.wav')}]]'));
  });

  testWidgets('a Markdown library appends an image-style link', (tester) async {
    final edits = <String>[];
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: edits,
      linkType: LinkType.markdown,
    );

    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pump();
    expect(edits.single, contains('![](${p.join('assets', 'imported.wav')})'));
  });

  testWidgets('the record button turns red while recording', (tester) async {
    await _pump(tester, text: '---\ntype: audio\n---\n', edits: []);
    expect(find.byIcon(Icons.mic_outlined), findsOneWidget);
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byIcon(Icons.mic_outlined), findsNothing);
    // The field gives way to the recording clock.
    expect(find.byKey(const Key('audio-message-field')), findsNothing);
    expect(find.text('Recording… 0:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Recording… 0:03'), findsOneWidget);

    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.mic_outlined), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsNothing);
    expect(find.byKey(const Key('audio-message-field')), findsOneWidget);
  });

  testWidgets('pause holds the clock and resume carries on', (tester) async {
    final recorder = _FakeRecorder();
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: [],
      recorder: recorder,
    );
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Recording… 0:02'), findsOneWidget);

    await tester.tap(find.byKey(const Key('audio-record-pause')));
    await tester.pump();
    expect(recorder.calls, ['pause']);
    await tester.pump(const Duration(seconds: 3));
    // The breathing dot repeats, so no pumpAndSettle while paused.
    expect(find.text('Paused 0:02'), findsOneWidget);

    await tester.tap(find.byKey(const Key('audio-record-pause')));
    await tester.pump();
    expect(recorder.calls, ['pause', 'resume']);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Recording… 0:03'), findsOneWidget);

    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pumpAndSettle();
  });

  testWidgets('stop keeps the bar, saving, until the clip lands', (
    tester,
  ) async {
    final edits = <String>[];
    final imported = Completer<String>();
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: edits,
      importAudio: (_, _) => imported.future,
    );
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // No in-between state: the bar stays, reading "Saving…", and the
    // field has not come back yet.
    expect(find.text('Saving…'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('audio-recording-saving')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('audio-message-field')), findsNothing);
    expect(edits, isEmpty);

    imported.complete(p.join('assets', 'imported.wav'));
    await tester.pumpAndSettle();
    expect(edits.single, contains(p.join('assets', 'imported.wav')));
    expect(find.byKey(const Key('audio-message-field')), findsOneWidget);
    expect(find.byIcon(Icons.mic_outlined), findsOneWidget);
  });

  testWidgets('discard throws the recording away', (tester) async {
    final edits = <String>[];
    final recorder = _FakeRecorder();
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: edits,
      recorder: recorder,
    );
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('audio-record-discard')));
    await tester.pumpAndSettle();
    expect(recorder.cancelled, isTrue);
    expect(edits, isEmpty);
    expect(find.byIcon(Icons.mic_outlined), findsOneWidget);
  });

  testWidgets('import attaches a picked file', (tester) async {
    final edits = <String>[];
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: edits,
      pickAudioPath: () async => p.join('tmp', 'picked.mp3'),
      importAudio: (_, _) async => p.join('assets', 'picked.wav'),
    );
    await tester.tap(find.byKey(const Key('audio-import-button')));
    await tester.pump();
    expect(edits.single, contains(p.join('assets', 'picked.wav')));
  });

  testWidgets('the mic turns into send while typing', (tester) async {
    final edits = <String>[];
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n![](assets/a.wav)\n',
      edits: edits,
    );
    expect(find.byKey(const Key('audio-send-button')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('audio-message-field')),
      'a written note',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('audio-record-button')), findsNothing);
    await tester.tap(find.byKey(const Key('audio-send-button')));
    await tester.pumpAndSettle();
    expect(edits.single, endsWith('\n\na written note\n'));
    // The sent text leaves the field, and the mic comes back.
    expect(find.byKey(const Key('audio-record-button')), findsOneWidget);
  });

  testWidgets('delete from the clip menu removes the vocal', (tester) async {
    final edits = <String>[];
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n> title\n![](assets/a.wav)\n> said\n',
      edits: edits,
    );
    await _openClipMenu(tester, 0);
    await tester.tap(find.byKey(const ValueKey('audio-delete-0')));
    await tester.pumpAndSettle();
    expect(edits.single, '---\ntype: audio\n---\n');
  });

  testWidgets('the clip menu titles a recording', (tester) async {
    final edits = <String>[];
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n![](assets/a.wav)\n> said\n',
      edits: edits,
    );
    await _openClipMenu(tester, 0);
    await tester.tap(find.byKey(const ValueKey('audio-title-0')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Meeting');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      edits.single,
      '---\ntype: audio\n---\n> Meeting\n![](assets/a.wav)\n> said\n',
    );
  });

  testWidgets("the ⋮ menu copies a clip's description", (tester) async {
    final copied = _clipboard(tester);
    final edits = <String>[];
    await _pump(
      tester,
      text:
          '---\ntype: audio\n---\n> title\n![](assets/a.wav)\n> said it all\n',
      edits: edits,
    );
    await _openClipMenu(tester, 0);
    await tester.tap(find.byKey(const ValueKey('audio-copy-0')));
    await tester.pumpAndSettle();

    expect(copied, ['said it all'], reason: 'the description, as it stands');
    expect(find.text(AppStrings.audioDescriptionCopied), findsOneWidget);
    expect(edits, isEmpty, reason: 'copying is not an edit');
  });

  testWidgets('a clip with no description offers no copy', (tester) async {
    final edits = <String>[];
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n![](assets/a.wav)\n',
      edits: edits,
    );
    await _openClipMenu(tester, 0);

    expect(find.byKey(const ValueKey('audio-delete-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('audio-copy-0')), findsNothing);
  });

  testWidgets('rename updates the embed through the file seam', (tester) async {
    final edits = <String>[];
    final renamed = <String>[];
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n![](assets/a.wav)\n',
      edits: edits,
      renameAudio: (oldRelative, wanted) async {
        renamed.add('$oldRelative->$wanted');
        return p.join('assets', 'b.wav');
      },
    );
    await _openClipMenu(tester, 0);
    // The file name heads the menu.
    expect(find.text('a.wav'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('audio-rename-0')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'b.wav');
    await tester.pump();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(renamed.single, contains('a.wav'));
    expect(edits.single, contains(p.join('assets', 'b.wav')));
    expect(edits.single, isNot(contains('assets/a.wav')));
  });

  testWidgets('a tap edits a written note, a long press deletes it', (
    tester,
  ) async {
    final edits = <String>[];
    await _pump(tester, text: '---\ntype: audio\n---\nhello\n', edits: edits);
    await tester.tap(find.text('hello'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'changed');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(edits.single, '---\ntype: audio\n---\nchanged\n');

    await tester.longPress(find.text('hello'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('audio-note-delete-0')));
    await tester.pumpAndSettle();
    expect(edits.last, '---\ntype: audio\n---\n');
  });
}
