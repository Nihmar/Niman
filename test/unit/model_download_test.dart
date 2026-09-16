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
      onHeaders: (total, _, _) => announced = total,
      onProgress: progress.add,
      progressInterval: Duration.zero,
    );
    expect(await download.done, payload.length);
    expect(announced, payload.length);
    expect(progress.last, payload.length);
    expect(await File(target()).readAsBytes(), payload);
    expect(File('${target()}${ModelFiles.partSuffix}').existsSync(), false);
  });

  test('a cut-off download resumes from its partial file', () async {
    final ranges = <String?>[];
    handler = (request) async {
      final range = request.headers.value(HttpHeaders.rangeHeader);
      ranges.add(range);
      final from = range == null
          ? 0
          : int.parse(range.substring('bytes='.length, range.length - 1));
      request.response
        ..statusCode = from == 0 ? HttpStatus.ok : HttpStatus.partialContent
        ..contentLength = payload.length - from;
      if (from > 0) {
        request.response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $from-${payload.length - 1}/${payload.length}',
        );
      }
      request.response.add(payload.sublist(from));
      await request.response.close();
    };
    // What a download cut off at 120 kB leaves behind.
    final part = File('${target()}${ModelFiles.partSuffix}');
    await part.parent.create(recursive: true);
    await part.writeAsBytes(payload.sublist(0, 120000));

    int? resumedFrom;
    final download = await ModelDownload.start(
      uri: url(),
      target: target(),
      onHeaders: (_, _, from) => resumedFrom = from,
      onProgress: (_) {},
    );

    expect(await download.done, payload.length);
    expect(ranges, ['bytes=120000-']);
    expect(resumedFrom, 120000);
    expect(await File(target()).readAsBytes(), payload);
  });

  test('a response cut short fails, keeping the bytes for a resume', () async {
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
    await expectLater(
      download.done,
      throwsA(
        isA<ModelDownloadException>().having(
          (e) => e.transient,
          'transient',
          true,
        ),
      ),
    );
    expect(File(target()).existsSync(), false);
    expect(File('${target()}${ModelFiles.partSuffix}').lengthSync(), 1000);
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
          (e) => (e.reason, e.transient),
          'reason, transient',
          ('HTTP 404', false),
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
      onHeaders: (_, _, _) => headers.complete(),
      onProgress: (_) {},
    );
    await headers.future;
    await download.cancel();
    await expectLater(download.done, throwsA(isA<ModelDownloadCancelled>()));
    expect(File(target()).existsSync(), false);
    expect(File('${target()}${ModelFiles.partSuffix}').existsSync(), false);
  });
}
