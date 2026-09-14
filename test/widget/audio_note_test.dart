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
  String? startedPath;
  String? stoppedPath = p.join('tmp', 'clip.wav');

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start({required String path}) async {
    startedPath = path;
  }

  @override
  Future<String?> stop() async => stoppedPath;

  @override
  Future<void> cancel() async {}

  @override
  void dispose() {}
}

final class _FakePlayer implements ClipPlayer {
  final done = StreamController<void>.broadcast();
  final played = <String>[];
  int stops = 0;

  @override
  Future<void> play(String absolutePath) async {
    played.add(absolutePath);
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Stream<void> get onFinished => done.stream;

  @override
  void dispose() {
    unawaited(done.close());
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
          player: player,
          pickAudioPath: pickAudioPath,
          importAudio:
              importAudio ?? ((_, _) async => p.join('assets', 'imported.wav')),
          newRecordPath: () async => p.join('tmp', 'rec.wav'),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('an empty audio note invites a first recording', (tester) async {
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: [],
      player: _FakePlayer(),
    );
    expect(find.text('No recordings yet'), findsOneWidget);
    expect(find.byKey(const Key('audio-record-button')), findsOneWidget);
  });

  testWidgets('clips list with play and delete', (tester) async {
    final player = _FakePlayer();
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n![](assets/a.wav)\n![](assets/b.mp3)\n',
      edits: [],
      player: player,
    );
    expect(find.text('a.wav'), findsOneWidget);
    expect(find.text('b.mp3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('audio-play-0')));
    await tester.pump();
    expect(player.played.single.endsWith(p.join('assets', 'a.wav')), isTrue);
  });

  testWidgets('record appends the imported clip to the note', (tester) async {
    final edits = <String>[];
    final recorder = _FakeRecorder();
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: edits,
      recorder: recorder,
      player: _FakePlayer(),
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
      recorder: _FakeRecorder(),
      player: _FakePlayer(),
      linkType: LinkType.markdown,
    );

    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pump();
    expect(edits.single, contains('![](${p.join('assets', 'imported.wav')})'));
  });

  testWidgets('delete removes the clip line', (tester) async {
    final edits = <String>[];
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n![](assets/a.wav)\n',
      edits: edits,
      player: _FakePlayer(),
    );
    await tester.tap(find.byKey(const ValueKey('audio-delete-0')));
    await tester.pump();
    expect(edits.single, isNot(contains('a.wav')));
  });

  testWidgets('import attaches a picked file', (tester) async {
    final edits = <String>[];
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: edits,
      player: _FakePlayer(),
      pickAudioPath: () async => p.join('tmp', 'picked.mp3'),
      importAudio: (_, _) async => p.join('assets', 'picked.wav'),
    );
    await tester.tap(find.byKey(const Key('audio-import-button')));
    await tester.pump();
    expect(edits.single, contains(p.join('assets', 'picked.wav')));
  });

  testWidgets('written notes send from the input as right bubbles', (
    tester,
  ) async {
    final edits = <String>[];
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n![](assets/a.wav)\n',
      edits: edits,
      player: _FakePlayer(),
    );
    await tester.tap(find.byKey(const Key('audio-compose-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('audio-message-field')),
      'a written note',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('audio-send-button')));
    await tester.pump();
    expect(edits.single, contains('a written note'));
  });

  testWidgets('compose toggles the input field', (tester) async {
    final edits = <String>[];
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: edits,
      player: _FakePlayer(),
    );
    expect(find.byKey(const Key('audio-message-field')), findsNothing);
    await tester.tap(find.byKey(const Key('audio-compose-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('audio-message-field')), findsOneWidget);
    await tester.tap(find.byKey(const Key('audio-compose-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('audio-message-field')), findsNothing);
  });

  testWidgets('the mic closes the open input and expands the record button', (
    tester,
  ) async {
    final edits = <String>[];
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: edits,
      recorder: _FakeRecorder(),
      player: _FakePlayer(),
    );
    await tester.tap(find.byKey(const Key('audio-compose-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('audio-message-field')), findsOneWidget);
    // Pressing the mic closes the input and hands the bar back to the
    // record button, which expands and starts the recording.
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('audio-message-field')), findsNothing);
    expect(find.byKey(const ValueKey('audio-actions-row')), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsOneWidget);
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pumpAndSettle();
    expect(edits.single, contains(p.join('assets', 'imported.wav')));
  });

  testWidgets('the record button turns red while recording', (tester) async {
    await _pump(
      tester,
      text: '---\ntype: audio\n---\n',
      edits: [],
      recorder: _FakeRecorder(),
      player: _FakePlayer(),
    );
    final icon = find.byIcon(Icons.mic_outlined);
    expect(icon, findsOneWidget);
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byIcon(Icons.mic_outlined), findsNothing);
    await tester.tap(find.byKey(const Key('audio-record-button')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.mic_outlined), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsNothing);
  });

  testWidgets('rename updates the embed through the file seam', (tester) async {
    final edits = <String>[];
    final renamed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AudioNoteView(
            text: '---\ntype: audio\n---\n![](assets/a.wav)\n',
            onChanged: edits.add,
            notePath: p.join('root', 'note.md'),
            libraryRoot: p.join('root'),
            recorder: _FakeRecorder(),
            player: _FakePlayer(),
            importAudio: (_, _) async => p.join('assets', 'imported.wav'),
            renameAudio: (oldRelative, wanted) async {
              renamed.add('$oldRelative->$wanted');
              return p.join('assets', 'b.wav');
            },
            newRecordPath: () async => p.join('tmp', 'rec.wav'),
          ),
        ),
      ),
    );
    await tester.pump();
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
}
