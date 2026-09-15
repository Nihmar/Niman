import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/transcription/model_download.dart';
import 'package:niman/src/transcription/model_files.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;
  late HttpServer server;
  late Future<void> Function(HttpRequest request) handler;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_model_download_');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
      ..listen((request) => unawaited(handler(request)));
  });

  tearDown(() async {
    await server.close(force: true);
    // The download isolate may still be letting go of a handle.
    for (var i = 0; i < 20 && dir.existsSync(); i++) {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  });

  Uri url() => Uri.parse('http://127.0.0.1:${server.port}/ggml-tiny.bin');
  String target() => p.join(dir.path, 'models', 'ggml-tiny.bin');
  final payload = Uint8List.fromList(
    List<int>.generate(300000, (i) => i % 251),
  );

  test('writes the model under its final name and reports progress', () async {
    handler = (request) async {
      request.response.contentLength = payload.length;
      for (var i = 0; i < payload.length; i += 65536) {
        request.response.add(payload.sublist(i, (i + 65536).clamp(0, 300000)));
        await request.response.flush();
      }
      await request.response.close();
    };
    int? announced;
    final progress = <int>[];
    final download = await ModelDownload.start(
      uri: url(),
      target: target(),
      onHeaders: (total, _) => announced = total,
      onProgress: progress.add,
      progressInterval: Duration.zero,
    );
    expect(await download.done, payload.length);
    expect(announced, payload.length);
    expect(progress.last, payload.length);
    expect(await File(target()).readAsBytes(), payload);
    expect(File('${target()}${ModelFiles.partSuffix}').existsSync(), false);
  });

  test('a response cut short fails and leaves no file', () async {
    // A raw socket: announce the full length, send a little, hang up.
    final raw = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(raw.close);
    raw.listen((socket) async {
      await socket.first;
      socket
        ..write(
          'HTTP/1.1 200 OK\r\n'
          'Content-Length: ${payload.length}\r\n\r\n',
        )
        ..add(payload.sublist(0, 1000));
      await socket.flush();
      socket.destroy();
    });
    final download = await ModelDownload.start(
      uri: Uri.parse('http://127.0.0.1:${raw.port}/ggml-tiny.bin'),
      target: target(),
      onProgress: (_) {},
    );
    await expectLater(download.done, throwsA(isA<ModelDownloadException>()));
    expect(File(target()).existsSync(), false);
    expect(File('${target()}${ModelFiles.partSuffix}').existsSync(), false);
  });

  test('an HTTP error fails with the status', () async {
    handler = (request) async {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    };
    final download = await ModelDownload.start(
      uri: url(),
      target: target(),
      onProgress: (_) {},
    );
    await expectLater(
      download.done,
      throwsA(
        isA<ModelDownloadException>().having(
          (e) => e.reason,
          'reason',
          'HTTP 404',
        ),
      ),
    );
  });

  test('cancel stops the download and removes the partial file', () async {
    handler = (request) async {
      request.response.contentLength = payload.length;
      request.response.add(payload.sublist(0, 1000));
      await request.response.flush();
      // Never finishes on its own.
      await Future<void>.delayed(const Duration(seconds: 20));
    };
    final headers = Completer<void>();
    final download = await ModelDownload.start(
      uri: url(),
      target: target(),
      onHeaders: (_, _) => headers.complete(),
      onProgress: (_) {},
    );
    await headers.future;
    await download.cancel();
    await expectLater(download.done, throwsA(isA<ModelDownloadCancelled>()));
    expect(File(target()).existsSync(), false);
    expect(File('${target()}${ModelFiles.partSuffix}').existsSync(), false);
  });
}
