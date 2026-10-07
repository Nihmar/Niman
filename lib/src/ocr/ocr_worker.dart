import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:niman/src/ocr/ocr_engine_locator.dart';
import 'package:niman/src/ocr/ocr_line.dart';
import 'package:niman/src/ocr/ocr_page_source.dart';
import 'package:niman/src/ocr/tesseract.dart';

/// Tesseract on its own isolate, for one recognition job.
///
/// Every Tesseract call blocks for as long as a page takes (a second or
/// several), so none may run on the UI isolate. The worker loads the
/// languages once and reads the pages it is sent one after the other.
/// Stopping it ([close]) kills the isolate. A kill lands between two
/// Dart instructions, so a page Tesseract is reading finishes first: a
/// cancel shows at the end of the current page.
final class OcrWorker {
  new _(
    this._isolate,
    this._requests,
    this._repliesPort,
    this._replies,
    this._exitPort,
    this._exited,
  );

  /// Starts a worker reading [languages] (`ita+eng`) from the models in
  /// [datapath], with the engine library [engine] (a name or a path);
  /// throws [TesseractException] when either does not load.
  static Future<OcrWorker> start({
    required String engine,
    required String datapath,
    required String languages,
  }) async {
    final replies = ReceivePort();
    final exit = ReceivePort();
    final isolate = await Isolate.spawn(
      _run,
      (replies.sendPort, engine, datapath, languages),
      onExit: exit.sendPort,
      debugName: 'ocr-worker',
    );
    final stream = replies.asBroadcastStream();
    final exited = exit.asBroadcastStream();
    final first = await Future.any([
      stream.first,
      exited.first.then((_) => ('error', 'the worker stopped')),
    ]);
    switch (first) {
      case final SendPort requests:
        return OcrWorker._(
          isolate,
          requests,
          replies,
          stream,
          exit,
          // The exit, or [close] shutting the port before it arrives.
          exited.first.then<void>((_) {}, onError: (Object _) {}),
        );
      case ('error', final String reason):
        replies.close();
        exit.close();
        isolate.kill(priority: Isolate.immediate);
        throw TesseractException(reason);
    }
    throw StateError('unexpected reply $first');
  }

  final Isolate _isolate;
  final SendPort _requests;
  final ReceivePort _repliesPort;
  final Stream<Object?> _replies;
  final ReceivePort _exitPort;

  /// Completes when the isolate exits: the one future every page waits
  /// on, rather than a listener on the exit port per page.
  final Future<void> _exited;
  int _next = 0;
  bool _closed = false;

  /// The lines of [page].
  Future<List<OcrLine>> recognize(OcrPixels page) async {
    if (_closed) throw StateError('OcrWorker closed');
    final id = _next++;
    final reply = _replies.firstWhere(
      (message) => switch (message) {
        (final int to, _) => to == id,
        _ => false,
      },
      // [close] shut the port first.
      orElse: () => (id, 'the worker stopped'),
    );
    _requests.send((id, page));
    final answer = await Future.any([
      reply,
      _exited.then((_) => (id, 'the worker stopped')),
    ]);
    return switch (answer) {
      (_, final List<OcrLine> lines) => lines,
      (_, final String reason) => throw TesseractException(reason),
      _ => throw StateError('unexpected reply $answer'),
    };
  }

  /// Stops the worker and frees its languages.
  void close() {
    if (_closed) return;
    _closed = true;
    _isolate.kill(priority: Isolate.immediate);
    _repliesPort.close();
    _exitPort.close();
  }
}

Future<void> _run((SendPort, String, String, String) start) async {
  final (replies, engine, datapath, languages) = start;
  final api = openOcrEngine(engine);
  if (api == null) {
    replies.send(('error', 'the engine $engine does not load'));
    return;
  }
  final Tesseract tesseract;
  try {
    tesseract = Tesseract.open(api, datapath: datapath, languages: languages);
  } on TesseractException catch (error) {
    replies.send(('error', error.reason));
    return;
  }
  final requests = ReceivePort();
  replies.send(requests.sendPort);
  await for (final message in requests) {
    final (int id, OcrPixels page) = message as (int, OcrPixels);
    try {
      final gray = _gray(
        page.data.materialize().asUint8List(),
        bgra: page.bgra,
      );
      replies.send((
        id,
        tesseract.recognize(
          gray,
          width: page.width,
          height: page.height,
          ppi: page.ppi,
        ),
      ));
    } on Object catch (error) {
      replies.send((id, '$error'));
    }
  }
}

/// 8-bit luminance of 4-byte pixels: a quarter of the memory Tesseract
/// would otherwise copy, and the input it binarizes from anyway.
Uint8List _gray(Uint8List pixels, {required bool bgra}) {
  final gray = Uint8List(pixels.length ~/ 4);
  final r = bgra ? 2 : 0;
  final b = bgra ? 0 : 2;
  for (var i = 0, o = 0; o < gray.length; i += 4, o++) {
    gray[o] =
        (pixels[i + r] * 77 + pixels[i + 1] * 150 + pixels[i + b] * 29) >> 8;
  }
  return gray;
}
