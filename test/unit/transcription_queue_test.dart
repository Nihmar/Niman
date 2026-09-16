import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/transcription/model_download.dart';
import 'package:niman/src/transcription/model_state.dart';
import 'package:niman/src/transcription/speech_transcriber.dart';
import 'package:niman/src/transcription/transcription_job.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/transcription/transcription_queue.dart';
import 'package:path/path.dart' as p;

/// A transcriber whose calls finish when the test says so.
final class _FakeTranscriber implements SpeechTranscriber {
  final List<({String audioPath, String language, String model})> calls = [];
  final List<Completer<String>> pending = [];
  int releases = 0;

  @override
  Future<String> transcribe({
    required TranscriptionModel model,
    required String audioPath,
    required String language,
    void Function(int percent)? onProgress,
  }) {
    calls.add((audioPath: audioPath, language: language, model: model.id));
    // What whisper_ggml does with its input: a converted file beside it.
    expect(File(audioPath).existsSync(), true);
    onProgress?.call(50);
    final completer = Completer<String>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<void> release() async => releases++;
}

/// A 0.2 s silent 44.1 kHz stereo WAV, like the app records.
Uint8List _wav() {
  const frames = 8820;
  final header = ByteData(44);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      header.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  header.setUint32(4, 36 + frames * 4, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  header
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 2, Endian.little)
    ..setUint32(24, 44100, Endian.little)
    ..setUint32(28, 44100 * 4, Endian.little)
    ..setUint16(32, 4, Endian.little)
    ..setUint16(34, 16, Endian.little);
  tag(36, 'data');
  header.setUint32(40, frames * 4, Endian.little);
  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add(Uint8List(frames * 4)))
      .takeBytes();
}

void main() {
  late Directory dir;
  late Directory library;
  late TranscriptionModels models;
  late _FakeTranscriber transcriber;
  late TranscriptionQueue queue;
  final base = transcriptionModelById('base')!;
  final work = <Directory>[];

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_queue_models_');
    library = await Directory.systemTemp.createTemp('niman_queue_library_');
    await File(p.join(library.path, 'a.wav')).writeAsBytes(_wav());
    await File(p.join(library.path, 'b.wav')).writeAsBytes(_wav());
    await File(p.join(dir.path, base.fileName)).writeAsBytes([1, 2, 3]);
    models = TranscriptionModels(directory: () async => dir.path, phone: false);
    await models.load();
    transcriber = _FakeTranscriber();
    work.clear();
    queue = TranscriptionQueue(
      models: models,
      transcriber: transcriber,
      packageConverts: false,
      workDirectory: () async {
        final created = await Directory.systemTemp.createTemp('niman_q_');
        work.add(created);
        return created;
      },
    );
  });

  tearDown(() async {
    queue.dispose();
    models.dispose();
    for (final folder in [dir, library, ...work]) {
      if (folder.existsSync()) await folder.delete(recursive: true);
    }
  });

  TranscriptionJob enqueue(String clip, {TranscriptionModel? model}) =>
      queue.enqueue(
        notePath: p.join(library.path, 'note.md'),
        clipTarget: clip,
        audioPath: p.join(library.path, clip),
        model: model ?? base,
        language: 'it',
      );

  /// Lets the isolate conversion and the queue's awaits run.
  Future<void> until(bool Function() condition) async {
    for (var i = 0; i < 200 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(condition(), true);
  }

  test(
    'a clip is converted in a temp folder, transcribed and cleaned',
    () async {
      final job = enqueue('a.wav');
      await until(() => transcriber.pending.length == 1);

      expect(job.phase, TranscriptionPhase.transcribing);
      final call = transcriber.calls.single;
      expect(p.isWithin(work.single.path, call.audioPath), true);
      expect(call.language, 'it');
      expect(call.model, 'base');

      transcriber.pending.single.complete(' Ciao [BLANK_AUDIO]  a tutti.\n');
      await until(() => job.finished);

      expect(job.phase, TranscriptionPhase.done);
      expect(job.text, 'Ciao a tutti.');
      // Nothing left behind, and nothing written next to the clip.
      await until(() => !work.single.existsSync());
      expect(library.listSync().map((e) => p.basename(e.path)).toSet(), {
        'a.wav',
        'b.wav',
      });
      await until(() => transcriber.releases == 1);
    },
  );

  test('clips run one at a time, in order', () async {
    final first = enqueue('a.wav');
    final second = enqueue('b.wav');
    await until(() => transcriber.pending.length == 1);
    expect(second.phase, TranscriptionPhase.queued);
    // Asking again for a queued clip returns its job.
    expect(enqueue('b.wav'), same(second));

    transcriber.pending.first.complete('uno');
    await until(() => transcriber.pending.length == 2);
    expect(first.phase, TranscriptionPhase.done);
    expect(second.phase, TranscriptionPhase.transcribing);
    transcriber.pending.last.complete('due');
    await until(() => second.finished);
    // The model was loaded once and released once, at the end.
    await until(() => transcriber.releases == 1);

    final taken = queue.takeFinished(p.join(library.path, 'note.md'));
    expect(taken.map((j) => j.text), ['uno', 'due']);
    expect(queue.jobs, isEmpty);
  });

  test('a cancelled running job is discarded and the next one runs', () async {
    final first = enqueue('a.wav');
    enqueue('b.wav');
    await until(() => transcriber.pending.length == 1);

    queue.cancel(first);
    expect(queue.jobFor(first.notePath, 'a.wav'), null);
    transcriber.pending.first.complete('scartato');
    await until(() => transcriber.pending.length == 2);

    expect(queue.jobs.single.clipTarget, 'b.wav');
  });

  test('a job waits for its model to finish downloading', () async {
    final small = transcriptionModelById('small')!;
    final release = Completer<void>();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await release.future;
      request.response
        ..contentLength = 8
        ..add(List.filled(8, 1));
      await request.response.close();
    });
    final downloading = TranscriptionModels(
      directory: () async => dir.path,
      phone: false,
      startDownload:
          ({required uri, required target, required onProgress, onHeaders}) =>
              ModelDownload.start(
                uri: Uri.parse('http://127.0.0.1:${server.port}/m.bin'),
                target: target,
                onProgress: onProgress,
                onHeaders: onHeaders,
              ),
    );
    await downloading.load();
    addTearDown(downloading.dispose);
    final waiting = TranscriptionQueue(
      models: downloading,
      transcriber: transcriber,
      packageConverts: false,
    );
    addTearDown(waiting.dispose);

    final download = downloading.download(small);
    final job = waiting.enqueue(
      notePath: 'note.md',
      clipTarget: 'a.wav',
      audioPath: p.join(library.path, 'a.wav'),
      model: small,
      language: 'it',
    );
    expect(job.phase, TranscriptionPhase.waitingForModel);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(transcriber.calls, isEmpty);

    release.complete();
    await download;
    await until(() => transcriber.pending.length == 1);
    expect(job.phase, TranscriptionPhase.transcribing);
    transcriber.pending.single.complete('ok');
    await until(() => job.finished);
  });

  test('a job whose model is not coming fails at once', () async {
    final job = enqueue('a.wav', model: transcriptionModelById('medium'));
    expect(job.phase, TranscriptionPhase.failed);
    expect(job.error, contains('not downloaded'));
    expect(
      models.stateOf(transcriptionModelById('medium')!),
      isA<ModelAbsent>(),
    );
  });

  test('a format this platform cannot read fails with a reason', () async {
    await File(p.join(library.path, 'c.m4a')).writeAsBytes([1, 2, 3]);
    expect(queue.supports(p.join(library.path, 'c.m4a')), false);
    final job = enqueue('c.m4a');
    await until(() => job.finished);
    expect(job.phase, TranscriptionPhase.failed);
    expect(job.error, contains('unsupported'));
    expect(transcriber.calls, isEmpty);
  });
}
