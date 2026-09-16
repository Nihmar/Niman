import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/transcription/open_audio_notes.dart';
import 'package:niman/src/transcription/speech_transcriber.dart';
import 'package:niman/src/transcription/transcription_job.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/transcription/transcription_queue.dart';
import 'package:niman/src/ui/kinds/audio_transcript_writer.dart';
import 'package:path/path.dart' as p;

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

void main() {
  late Directory dir;
  late TranscriptionModels models;
  late TranscriptionQueue queue;
  late _Transcriber transcriber;
  late OpenAudioNotes open;
  late Map<String, String> files;
  late AudioTranscriptWriter writer;
  const note = 'library/voice.md';
  const head = '---\ntype: audio\n---\n';

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_writer_');
    await File(p.join(dir.path, transcriptionModelById('base')!.fileName))
        .writeAsBytes([1]);
    await File(p.join(dir.path, 'a.wav')).writeAsBytes([1]);
    models = TranscriptionModels(directory: () async => dir.path, phone: false);
    await models.load();
    transcriber = _Transcriber();
    queue = TranscriptionQueue(
      models: models,
      transcriber: transcriber,
      packageConverts: false,
      // No real WAV needed: the conversion is not what this tests.
      convert: ({required source, required target}) async {
        await File(target).writeAsBytes([1]);
        return (
          sampleRate: 16000,
          channels: 1,
          bits: 16,
          inputFrames: 16000,
          outputFrames: 16000,
          bytesIn: 1,
          bytesOut: 1,
          readMs: 0,
          dspMs: 0,
          writeMs: 0,
          totalMs: 0,
        );
      },
    );
    open = OpenAudioNotes();
    files = {note: '$head![](assets/a.wav)\n> vecchia\n'};
    writer = AudioTranscriptWriter(
      queue: queue,
      open: open,
      read: (path) async => files[path],
      save: (path, text) async => files[path] = text,
    )..start();
  });

  tearDown(() async {
    writer.stop();
    queue.dispose();
    models.dispose();
    open.dispose();
    await dir.delete(recursive: true);
  });

  TranscriptionJob enqueue({
    TranscriptPlacement placement = TranscriptPlacement.replace,
  }) => queue.enqueue(
    notePath: note,
    clipTarget: 'assets/a.wav',
    audioPath: p.join(dir.path, 'a.wav'),
    model: transcriptionModelById('base')!,
    language: 'it',
    placement: placement,
    originalDescription: 'vecchia',
  );

  Future<void> until(bool Function() condition) async {
    for (var i = 0; i < 200 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(condition(), true);
  }

  test('a transcript for a closed note is written into its file', () async {
    enqueue(placement: TranscriptPlacement.append);
    await until(() => transcriber.pending.length == 1);
    transcriber.pending.single.complete('nuova');
    await until(() => files[note]!.contains('nuova'));
    await writer.idle;

    expect(files[note], '$head![](assets/a.wav)\n> vecchia\n> \n> nuova\n');
    expect(queue.jobs, isEmpty);
  });

  test('a note on screen keeps its result for the view', () async {
    open.open(note);
    final job = enqueue();
    await until(() => transcriber.pending.length == 1);
    transcriber.pending.single.complete('nuova');
    await until(() => job.finished);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(files[note], '$head![](assets/a.wav)\n> vecchia\n');
    expect(queue.jobs.single, same(job));

    // The view goes without taking it: now the file gets it.
    open.close(note);
    await until(() => files[note]!.contains('nuova'));
    expect(files[note], '$head![](assets/a.wav)\n> nuova\n');
  });

  test('a failed or silent transcript writes nothing', () async {
    enqueue();
    await until(() => transcriber.pending.length == 1);
    transcriber.pending.single.complete('   [BLANK_AUDIO] ');
    await until(() => queue.jobs.isEmpty);
    await writer.idle;
    expect(files[note], '$head![](assets/a.wav)\n> vecchia\n');
  });

}
