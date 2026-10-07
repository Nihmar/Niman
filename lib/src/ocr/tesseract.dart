import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:niman/src/ocr/ocr_line.dart';
import 'package:niman/src/ocr/tesseract_bindings.dart';

/// One Tesseract instance with its languages loaded, recognizing a page at
/// a time.
///
/// Loading the languages is the slow part (hundreds of ms for a best
/// model), so a job keeps one instance for all its pages. Every call
/// blocks: it belongs on a worker isolate, never on the UI one.
final class Tesseract {
  new _(this._api, this._handle);

  /// Loads [languages] (`ita+eng`) from the `.traineddata` files in
  /// [datapath]; throws [TesseractException] when they do not load.
  factory open(
    TesseractBindings api, {
    required String datapath,
    required String languages,
  }) {
    final handle = api.create();
    final path = datapath.toNativeUtf8();
    final langs = languages.toNativeUtf8();
    try {
      if (api.init(handle, path, langs) != 0) {
        api.delete(handle);
        throw TesseractException('cannot load "$languages" from $datapath');
      }
    } finally {
      malloc
        ..free(path)
        ..free(langs);
    }
    api.setPageSegMode(handle, TesseractBindings.pageSegAuto);
    return Tesseract._(api, handle);
  }

  final TesseractBindings _api;
  final Pointer<Void> _handle;
  bool _disposed = false;

  /// The lines of the 8-bit gray page [gray], [width] × [height] pixels
  /// scanned at [ppi], top to bottom, blank ones left out.
  List<OcrLine> recognize(
    Uint8List gray, {
    required int width,
    required int height,
    int ppi = 300,
  }) {
    if (_disposed) throw StateError('Tesseract disposed');
    if (gray.length != width * height) {
      throw ArgumentError('${gray.length} bytes for $width × $height');
    }
    final pixels = malloc<Uint8>(gray.length);
    final box = malloc<Int32>(4);
    try {
      pixels.asTypedList(gray.length).setAll(0, gray);
      _api
        ..setImage(_handle, pixels, width, height, 1, width)
        ..setSourceResolution(_handle, ppi);
      if (_api.recognize(_handle, nullptr) != 0) {
        throw const TesseractException('recognition failed');
      }
      final iterator = _api.getIterator(_handle);
      if (iterator == nullptr) return const [];
      try {
        return _lines(iterator, box, width, height);
      } finally {
        _api.iteratorDelete(iterator);
      }
    } finally {
      _api.clear(_handle);
      malloc
        ..free(pixels)
        ..free(box);
    }
  }

  List<OcrLine> _lines(
    Pointer<Void> iterator,
    Pointer<Int32> box,
    int width,
    int height,
  ) {
    const line = TesseractBindings.levelLine;
    final page = _api.pageIterator(iterator);
    final lines = <OcrLine>[];
    var paragraph = true;
    do {
      paragraph |=
          _api.isAtBeginningOf(page, TesseractBindings.levelParagraph) != 0;
      final raw = _api.iteratorText(iterator, line);
      if (raw == nullptr) continue;
      final text = raw.toDartString().trimRight();
      _api.deleteText(raw);
      if (text.trim().isEmpty) continue;
      if (_api.boundingBox(page, line, box, box + 1, box + 2, box + 3) == 0) {
        continue;
      }
      lines.add(
        OcrLine(
          text,
          left: box[0] / width,
          top: box[1] / height,
          right: box[2] / width,
          bottom: box[3] / height,
          paragraphStart: paragraph,
        ),
      );
      paragraph = false;
    } while (_api.iteratorNext(iterator, line) != 0);
    return lines;
  }

  /// Frees the instance and its languages.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _api
      ..end(_handle)
      ..delete(_handle);
  }
}

/// Tesseract refused: languages that do not load, a page it cannot read.
final class TesseractException implements Exception {
  /// The failure, short and loggable.
  const new(this.reason);

  /// What went wrong.
  final String reason;

  @override
  String toString() => 'TesseractException: $reason';
}
