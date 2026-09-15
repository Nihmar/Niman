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

void main() {
  late Directory dir;
  late HttpServer server;
  var status = HttpStatus.ok;
  final payload = Uint8List.fromList(List<int>.filled(4096, 7));

  final tiny = transcriptionModelById('tiny')!;
  final base = transcriptionModelById('base')!;
  final small = transcriptionModelById('small')!;

  setUp(() async {
    status = HttpStatus.ok;
    dir = await Directory.systemTemp.createTemp('niman_transcription_models_');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
      ..listen((request) async {
        request.response.statusCode = status;
        if (status == HttpStatus.ok) {
          request.response
            ..contentLength = payload.length
            ..add(payload);
        }
        await request.response.close();
      });
  });

  tearDown(() async {
    await server.close(force: true);
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  /// The controller over [dir], downloading from the local server
  /// whatever model it asks for.
  TranscriptionModels models({bool phone = false}) => TranscriptionModels(
    directory: () async => dir.path,
    phone: phone,
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

  test('phones are not offered large-v3', () {
    expect(models(phone: true).models.map((m) => m.id), [
      'tiny',
      'base',
      'small',
      'medium',
    ]);
    expect(models().models.last.id, 'large-v3');
  });

  test('load finds the models on disk and drops stale partial files', () async {
    await install(base, bytes: 42);
    final stale = File(p.join(dir.path, '${small.fileName}.part'));
    await stale.writeAsString('half');
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
    expect(stale.existsSync(), false);
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
    expect(File(p.join(dir.path, tiny.fileName)).lengthSync(), payload.length);
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

  test('a failed download is reported and leaves nothing', () async {
    status = HttpStatus.notFound;
    final controller = models();
    addTearDown(controller.dispose);
    await controller.load();

    await controller.download(small);

    expect(
      controller.stateOf(small),
      isA<ModelFailed>().having((s) => s.reason, 'reason', 'HTTP 404'),
    );
    expect(
      dir.listSync().where((e) => p.basename(e.path).startsWith('ggml-')),
      isEmpty,
    );
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
