// Phase 2 of the on-device transcription (docs/dev/transcription.md): a
// clip's menu offers Transcribe, the bubble shows the progress, and the
// text lands in the clip's description with an Undo.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/transcription/speech_transcriber.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/transcription/transcription_queue.dart';
import 'package:niman/src/transcription/transcription_settings.dart';
import 'package:niman/src/transcription/transcription_settings_store.dart';
import 'package:niman/src/ui/kinds/audio_note.dart';
import 'package:niman/src/ui/kinds/audio_player.dart';
import 'package:niman/src/ui/kinds/audio_recorder.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

final class _Recorder implements VoiceRecorder {
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<void> start({required String path}) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<String?> stop() async => null;
  @override
  Future<void> cancel() async {}
  @override
  void dispose() {}
}

final class _Player implements ClipPlayer {
  @override
  Future<void> play(String absolutePath) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> stop() async {}
  @override
  Stream<void> get onFinished => const Stream.empty();
  @override
  Stream<Duration> get onPosition => const Stream.empty();
  @override
  Stream<Duration> get onDuration => const Stream.empty();
  @override
  void dispose() {}
}

final class _Transcriber implements SpeechTranscriber {
  final List<Completer<String>> pending = [];

  @override
  Future<String> transcribe({
    required TranscriptionModel model,
    required String audioPath,
    required String language,
    void Function(int percent)? onProgress,
  }) {
    final completer = Completer<String>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<void> release() async {}
}

/// The note host: keeps the text the view edits, like the editor does.
final class _Host extends StatefulWidget {
  const new({required this.initial, required this.build, super.key});

  final String initial;
  final Widget Function(String text, ValueChanged<String> onChanged) build;

  @override
  State<_Host> createState() => _HostState();
}

final class _HostState extends State<_Host> {
  late String text = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.build(text, (next) => setState(() => text = next));
}

/// A short silent 44.1 kHz mono WAV.
Uint8List _wav() {
  const frames = 4410;
  final bytes = ByteData(44 + frames * 2);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      bytes.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  bytes.setUint32(4, 36 + frames * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  bytes
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, 44100, Endian.little)
    ..setUint32(28, 88200, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  tag(36, 'data');
  bytes.setUint32(40, frames * 2, Endian.little);
  return bytes.buffer.asUint8List();
}

void main() {
  late Directory library;
  late Directory modelsDir;
  late TranscriptionModels models;
  late TranscriptionQueue queue;
  late _Transcriber transcriber;
  final key = GlobalKey<_HostState>();

  Future<void> pump(WidgetTester tester, String text) async {
    await tester.runAsync(() async {
      library = await Directory.systemTemp.createTemp('niman_note_tr_');
      modelsDir = await Directory.systemTemp.createTemp('niman_models_tr_');
      await Directory(p.join(library.path, 'assets')).create();
      await File(p.join(library.path, 'assets', 'a.wav')).writeAsBytes(_wav());
      await File(
        p.join(modelsDir.path, transcriptionModelById('base')!.fileName),
      ).writeAsBytes([1]);
      await TranscriptionSettingsStore(() async => modelsDir.path)
          .save(const TranscriptionSettings(modelId: 'base', language: 'it'));
      models = TranscriptionModels(
        directory: () async => modelsDir.path,
        phone: false,
      );
      await models.load();
    });
    transcriber = _Transcriber();
    queue = TranscriptionQueue(
      models: models,
      transcriber: transcriber,
      packageConverts: false,
    );
    addTearDown(() async {
      queue.dispose();
      models.dispose();
      await tester.runAsync(() async {
        for (final dir in [library, modelsDir]) {
          if (dir.existsSync()) await dir.delete(recursive: true);
        }
      });
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _Host(
            key: key,
            initial: text,
            build: (text, onChanged) => AudioNoteView(
              text: text,
              onChanged: onChanged,
              notePath: p.join(library.path, 'note.md'),
              libraryRoot: library.path,
              recorder: _Recorder(),
              player: _Player(),
              readLengths: (_) async => const {},
              transcriptionModels: models,
              transcriptionQueue: queue,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Real time for the isolate conversion, then a frame.
  Future<void> settle(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(done(), true);
  }

  testWidgets('the menu offers Transcribe with the model and language', (
    tester,
  ) async {
    await pump(tester, '---\ntype: audio\n---\n![](assets/a.wav)\n');
    await tester.tap(find.byKey(const ValueKey('audio-menu-0')));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.audioTranscribe), findsOne);
    expect(find.text('Base · Italiano'), findsOne);
  });

  testWidgets('the transcript fills the description, and Undo empties it', (
    tester,
  ) async {
    await pump(tester, '---\ntype: audio\n---\n![](assets/a.wav)\n');
    await tester.tap(find.byKey(const ValueKey('audio-menu-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('audio-transcribe-0')));
    // The strip's bar animates while the audio is prepared: no settling.
    await tester.pump(const Duration(milliseconds: 500));

    await settle(tester, () => transcriber.pending.length == 1);
    expect(find.byKey(const ValueKey('audio-transcription-running')), findsOne);

    transcriber.pending.single.complete('Ciao a tutti [BLANK_AUDIO]');
    await settle(
      tester,
      () => key.currentState!.text.contains('> Ciao a tutti'),
    );
    await tester.pumpAndSettle();

    expect(
      key.currentState!.text,
      '---\ntype: audio\n---\n![](assets/a.wav)\n> Ciao a tutti\n',
    );
    expect(find.text('Ciao a tutti'), findsOne);
    expect(
      find.byKey(const ValueKey('audio-transcription-running')),
      findsNothing,
    );
    expect(find.text(AppStrings.transcriptionSaved), findsOne);

    await tester.tap(find.text(AppStrings.actionUndo));
    await tester.pumpAndSettle();
    expect(
      key.currentState!.text,
      '---\ntype: audio\n---\n![](assets/a.wav)\n',
    );
    // Nothing was written next to the clip.
    expect(
      Directory(p.join(library.path, 'assets'))
          .listSync()
          .map((e) => p.basename(e.path)),
      ['a.wav'],
    );
  });

  testWidgets('the notice with its Undo goes away by itself', (tester) async {
    await pump(tester, '---\ntype: audio\n---\n![](assets/a.wav)\n');
    await tester.tap(find.byKey(const ValueKey('audio-menu-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('audio-transcribe-0')));
    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester, () => transcriber.pending.length == 1);
    transcriber.pending.single.complete('Ciao');
    await settle(tester, () => key.currentState!.text.contains('> Ciao'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.transcriptionSaved), findsOne);

    // A snack bar with an action persists unless it is told not to.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.transcriptionSaved), findsNothing);
  });

  /// Transcribes clip 0 over an existing description, answering the
  /// dialog with [choice] (null cancels it).
  Future<void> transcribeOver(WidgetTester tester, Key? choice) async {
    await pump(
      tester,
      '---\ntype: audio\n---\n![](assets/a.wav)\n> scritta a mano\n',
    );
    await tester.tap(find.byKey(const ValueKey('audio-menu-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('audio-transcribe-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('transcription-placement-dialog')), findsOne);
    expect(find.text('scritta a mano'), findsWidgets);
    if (choice == null) {
      await tester.tap(find.text(AppStrings.actionCancel));
      await tester.pumpAndSettle();
      return;
    }
    await tester.tap(find.byKey(choice));
    // The strip's bar animates while the audio is prepared: no settling.
    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester, () => transcriber.pending.length == 1);
    transcriber.pending.single.complete('dettata');
    await settle(tester, () => key.currentState!.text.contains('dettata'));
  }

  testWidgets('over a description, Add below keeps it above the transcript', (
    tester,
  ) async {
    await transcribeOver(tester, const Key('transcription-placement-append'));
    expect(
      key.currentState!.text,
      '---\ntype: audio\n---\n![](assets/a.wav)\n'
      '> scritta a mano\n> \n> dettata\n',
    );
  });

  testWidgets('over a description, Replace puts the transcript instead', (
    tester,
  ) async {
    await transcribeOver(tester, const Key('transcription-placement-replace'));
    expect(
      key.currentState!.text,
      '---\ntype: audio\n---\n![](assets/a.wav)\n> dettata\n',
    );
  });

  testWidgets('cancelling the dialog queues nothing', (tester) async {
    await transcribeOver(tester, null);
    expect(queue.jobs, isEmpty);
    expect(
      key.currentState!.text,
      '---\ntype: audio\n---\n![](assets/a.wav)\n> scritta a mano\n',
    );
  });

  testWidgets('Cancel on the strip stops the transcription', (tester) async {
    await pump(tester, '---\ntype: audio\n---\n![](assets/a.wav)\n');
    await tester.tap(find.byKey(const ValueKey('audio-menu-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('audio-transcribe-0')));
    // The strip's bar animates while the audio is prepared: no settling.
    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester, () => transcriber.pending.length == 1);

    await tester.tap(find.byKey(const ValueKey('audio-transcription-cancel')));
    await tester.pump();
    expect(queue.jobs, isEmpty);

    transcriber.pending.single.complete('troppo tardi');
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(key.currentState!.text, isNot(contains('troppo tardi')));
  });
}
