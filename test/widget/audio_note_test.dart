// Issue #56 AC: a note with the audio frontmatter type shows the
// recordings view; the user can record clips in sequence and play them
// back; audio files live in the library as ordinary files.
//
// The view runs against fakes (no microphone, no speaker, no isolate),
// so these tests prove the sequencing and the note-text edits.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/ui/kinds/audio_note.dart';
import 'package:niman/src/ui/kinds/audio_player.dart';
import 'package:niman/src/ui/kinds/audio_recorder.dart';
import 'package:path/path.dart' as p;

final class _FakeRecorder implements VoiceRecorder {
  bool permission = true;
  bool cancelled = false;
  String? startedPath;
  String? stoppedPath = p.join('tmp', 'clip.wav');

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start({required String path}) async {
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

Future<void> _openClipMenu(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(ValueKey('audio-menu-$index')));
  await tester.pumpAndSettle();
}

void main() {
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
