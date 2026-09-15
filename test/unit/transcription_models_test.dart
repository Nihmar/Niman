import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/transcription/model_download.dart';
import 'package:niman/src/transcription/model_files.dart';
import 'package:niman/src/transcription/model_state.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/transcription/transcription_settings.dart';
import 'package:niman/src/transcription/transcription_settings_store.dart';
import 'package:path/path.dart' as p;

/// A raw HTTP server that honors `Range` and hangs up after [cutAfter]
/// bytes on the first [cuts] requests: a connection Android dropped.
final class _FlakyServer {
  new _(this._socket, this.payload);

  static Future<_FlakyServer> start(Uint8List payload) async => _FlakyServer._(
    await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
    payload,
  ).._listen();

  final ServerSocket _socket;
  final Uint8List payload;

  /// Requests still to cut short.
  int cuts = 0;

  /// Bytes sent before a cut.
  int cutAfter = 1000;

  /// Whether every request answers 404.
  bool missing = false;

  /// The `Range` headers received, null for none.
  final List<String?> ranges = [];

  int get port => _socket.port;

  void _listen() {
    _socket.listen((client) async {
      final head = StringBuffer();
      await for (final chunk in client) {
        head.write(latin1.decode(chunk));
        if (head.toString().contains('\r\n\r\n')) break;
      }
      final range = RegExp(
        r'^range: bytes=(\d+)-',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(head.toString());
      ranges.add(range?.group(0));
      if (missing) {
        client.write('HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n');
        await client.flush();
        client.destroy();
        return;
      }
      final from = range == null ? 0 : int.parse(range.group(1)!);
      final body = payload.sublist(from);
      client
        ..write(
          from == 0
              ? 'HTTP/1.1 200 OK\r\n'
              : 'HTTP/1.1 206 Partial Content\r\n'
                    'Content-Range: bytes $from-${payload.length - 1}/'
                    '${payload.length}\r\n',
        )
        ..write('Content-Length: ${body.length}\r\n\r\n');
      if (cuts > 0) {
        cuts--;
        client.add(body.sublist(0, cutAfter.clamp(0, body.length)));
        await client.flush();
        client.destroy();
        return;
      }
      client.add(body);
      await client.flush();
      await client.close();
    });
  }

  Future<void> close() => _socket.close();
}

void main() {
  late Directory dir;
  late _FlakyServer server;
  final payload = Uint8List.fromList(List<int>.generate(20000, (i) => i % 256));

  final tiny = transcriptionModelById('tiny')!;
  final base = transcriptionModelById('base')!;
  final small = transcriptionModelById('small')!;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_transcription_models_');
    server = await _FlakyServer.start(payload);
  });

  tearDown(() async {
    await server.close();
    for (var i = 0; i < 20 && dir.existsSync(); i++) {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  });

  /// The controller over [dir], downloading from the local server
  /// whatever model it asks for.
  TranscriptionModels models({bool phone = false}) => TranscriptionModels(
    directory: () async => dir.path,
    phone: phone,
    retryDelays: const [
      Duration(milliseconds: 20),
      Duration(milliseconds: 20),
      Duration(milliseconds: 20),
    ],
    startDownload:
        ({required uri, required target, required onProgress, onHeaders}) =>
            ModelDownload.start(
              uri: Uri.parse(
                'http://127.0.0.1:${server.port}/${p.basename(target)}',
              ),
              target: target,
              onProgress: onProgress,
              onHeaders: onHeaders,
            ),
  );

  Future<void> install(TranscriptionModel model, {int bytes = 10}) =>
      File(p.join(dir.path, model.fileName))
          .writeAsBytes(List.filled(bytes, 1));

  File partOf(TranscriptionModel model) =>
      File(p.join(dir.path, '${model.fileName}${ModelFiles.partSuffix}'));

  test('phones are not offered large-v3', () {
    expect(models(phone: true).models.map((m) => m.id), [
      'tiny',
      'base',
      'small',
      'medium',
    ]);
    expect(models().models.last.id, 'large-v3');
  });

  test('load finds the models on disk and the interrupted ones', () async {
    await install(base, bytes: 42);
    await partOf(small).writeAsString('half');
    await TranscriptionSettingsStore(() async => dir.path)
        .save(const TranscriptionSettings(modelId: 'base', language: 'it'));

    final controller = models();
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.installed, [base]);
    expect(controller.installedBytes, 42);
    expect(controller.defaultModel, base);
    expect(controller.settings.language, 'it');
    expect(controller.stateOf(tiny), isA<ModelAbsent>());
    expect(
      controller.stateOf(small),
      isA<ModelFailed>().having((s) => s.received, 'received', 4),
    );
    // Kept for the resume, not cleaned up.
    expect(partOf(small).existsSync(), true);
  });

  test('the first download becomes the default', () async {
    final controller = models();
    addTearDown(controller.dispose);
    await controller.load();
    final states = <ModelState>[];
    controller.addListener(() => states.add(controller.stateOf(tiny)));

    await controller.download(tiny);

    expect(states.first, isA<ModelDownloading>());
    expect(controller.stateOf(tiny), isA<ModelInstalled>());
    expect(await File(p.join(dir.path, tiny.fileName)).readAsBytes(), payload);
    expect(controller.defaultModel, tiny);
    // Persisted, not only in memory.
    expect(
      await TranscriptionSettingsStore(() async => dir.path).load(),
      const TranscriptionSettings(modelId: 'tiny'),
    );
  });

  test('a second download keeps the existing default', () async {
    await install(tiny);
    final controller = models();
    addTearDown(controller.dispose);
    await controller.load();
    await controller.setDefault(tiny);

    await controller.download(base);

    expect(controller.installed, [tiny, base]);
    expect(controller.defaultModel, tiny);
  });

  test('a dropped connection retries and resumes by itself', () async {
    server
      ..cuts = 2
      ..cutAfter = 7000;
    final controller = models();
    addTearDown(controller.dispose);
    await controller.load();
    var retrying = false;
    controller.addListener(() {
      if (controller.stateOf(base) case ModelDownloading(retrying: true)) {
        retrying = true;
      }
    });

    await controller.download(base);

    expect(controller.stateOf(base), isA<ModelInstalled>());
    expect(retrying, true);
    expect(server.ranges, [null, 'range: bytes=7000-', 'range: bytes=14000-']);
    expect(await File(p.join(dir.path, base.fileName)).readAsBytes(), payload);
  });

  test('when the retries run out the bytes stay for a resume', () async {
    server
      ..cuts = 4
      ..cutAfter = 3000;
    final controller = models();
    addTearDown(controller.dispose);
    await controller.load();

    await controller.download(small);

    expect(
      controller.stateOf(small),
      isA<ModelFailed>()
          .having((s) => s.resumable, 'resumable', true)
          .having((s) => s.received, 'received', 12000),
    );
    expect(partOf(small).lengthSync(), 12000);

    // Back in the foreground.
    await controller.resumeInterrupted();
    expect(controller.stateOf(small), isA<ModelInstalled>());
    expect(await File(p.join(dir.path, small.fileName)).readAsBytes(), payload);
  });

  test('cancel while waiting to retry discards the partial file', () async {
    server
      ..cuts = 100
      ..cutAfter = 2000;
    final controller = TranscriptionModels(
      directory: () async => dir.path,
      phone: false,
      retryDelays: const [Duration(seconds: 5)],
      startDownload:
          ({required uri, required target, required onProgress, onHeaders}) =>
              ModelDownload.start(
                uri: Uri.parse(
                  'http://127.0.0.1:${server.port}/${p.basename(target)}',
                ),
                target: target,
                onProgress: onProgress,
                onHeaders: onHeaders,
              ),
    );
    addTearDown(controller.dispose);
    await controller.load();
    final waiting = Completer<void>();
    controller.addListener(() {
      if (controller.stateOf(tiny) case ModelDownloading(retrying: true)) {
        if (!waiting.isCompleted) waiting.complete();
      }
    });

    final running = controller.download(tiny);
    await waiting.future;
    await controller.cancel(tiny);
    await running;

    expect(controller.stateOf(tiny), isA<ModelAbsent>());
    expect(partOf(tiny).existsSync(), false);
  });

  test('a missing file fails at once, with nothing kept', () async {
    server.missing = true;
    final controller = models();
    addTearDown(controller.dispose);
    await controller.load();

    await controller.download(small);

    expect(
      controller.stateOf(small),
      isA<ModelFailed>()
          .having((s) => s.reason, 'reason', 'HTTP 404')
          .having((s) => s.resumable, 'resumable', false),
    );
    expect(server.ranges, hasLength(1));
  });

  test('deleting the default hands it to the smallest model left', () async {
    await install(tiny);
    await install(small);
    final controller = models();
    addTearDown(controller.dispose);
    await controller.load();
    await controller.setDefault(small);

    await controller.delete(small);

    expect(File(p.join(dir.path, small.fileName)).existsSync(), false);
    expect(controller.installed, [tiny]);
    expect(controller.defaultModel, tiny);

    await controller.delete(tiny);
    expect(controller.defaultModel, null);
    expect(controller.settings.modelId, null);
  });

  test('the model file name is the one whisper_ggml loads', () {
    expect(tiny.fileName, 'ggml-tiny.bin');
    expect(transcriptionModelById('large-v3')!.fileName, 'ggml-large-v3.bin');
    expect(ModelFiles.partSuffix, '.part');
  });
}
