import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// The part of Tesseract's C API (`tesseract/capi.h`) the app calls,
/// bound by hand like hunspell's: a few functions do not need ffigen.
///
/// Every handle is a `Pointer<Void>`: `TessBaseAPI*`, `TessResultIterator*`
/// and `TessPageIterator*` are opaque on the C side too.
final class TesseractBindings {
  /// Looks every function up in [library]; throws `ArgumentError` when the
  /// library lacks one (not a Tesseract, or too old).
  new(DynamicLibrary library)
    : version = library
          .lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
            'TessVersion',
          ),
      create = library
          .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
            'TessBaseAPICreate',
          ),
      delete = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('TessBaseAPIDelete'),
      init = library
          .lookupFunction<
            Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>),
            int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>)
          >('TessBaseAPIInit3'),
      setPageSegMode = library
          .lookupFunction<
            Void Function(Pointer<Void>, Int32),
            void Function(Pointer<Void>, int)
          >('TessBaseAPISetPageSegMode'),
      setImage = library
          .lookupFunction<
            Void Function(
              Pointer<Void>,
              Pointer<Uint8>,
              Int32,
              Int32,
              Int32,
              Int32,
            ),
            void Function(Pointer<Void>, Pointer<Uint8>, int, int, int, int)
          >('TessBaseAPISetImage'),
      setSourceResolution = library
          .lookupFunction<
            Void Function(Pointer<Void>, Int32),
            void Function(Pointer<Void>, int)
          >('TessBaseAPISetSourceResolution'),
      recognize = library
          .lookupFunction<
            Int32 Function(Pointer<Void>, Pointer<Void>),
            int Function(Pointer<Void>, Pointer<Void>)
          >('TessBaseAPIRecognize'),
      getIterator = library
          .lookupFunction<
            Pointer<Void> Function(Pointer<Void>),
            Pointer<Void> Function(Pointer<Void>)
          >('TessBaseAPIGetIterator'),
      clear = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('TessBaseAPIClear'),
      end = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('TessBaseAPIEnd'),
      iteratorDelete = library
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('TessResultIteratorDelete'),
      iteratorNext = library
          .lookupFunction<
            Int32 Function(Pointer<Void>, Int32),
            int Function(Pointer<Void>, int)
          >('TessResultIteratorNext'),
      iteratorText = library
          .lookupFunction<
            Pointer<Utf8> Function(Pointer<Void>, Int32),
            Pointer<Utf8> Function(Pointer<Void>, int)
          >('TessResultIteratorGetUTF8Text'),
      pageIterator = library
          .lookupFunction<
            Pointer<Void> Function(Pointer<Void>),
            Pointer<Void> Function(Pointer<Void>)
          >('TessResultIteratorGetPageIterator'),
      isAtBeginningOf = library
          .lookupFunction<
            Int32 Function(Pointer<Void>, Int32),
            int Function(Pointer<Void>, int)
          >('TessPageIteratorIsAtBeginningOf'),
      boundingBox = library
          .lookupFunction<
            Int32 Function(
              Pointer<Void>,
              Int32,
              Pointer<Int32>,
              Pointer<Int32>,
              Pointer<Int32>,
              Pointer<Int32>,
            ),
            int Function(
              Pointer<Void>,
              int,
              Pointer<Int32>,
              Pointer<Int32>,
              Pointer<Int32>,
              Pointer<Int32>,
            )
          >('TessPageIteratorBoundingBox'),
      deleteText = library
          .lookupFunction<
            Void Function(Pointer<Utf8>),
            void Function(Pointer<Utf8>)
          >('TessDeleteText');

  /// `PSM_AUTO`: page segmentation without orientation detection.
  static const int pageSegAuto = 3;

  /// `RIL_PARA`.
  static const int levelParagraph = 1;

  /// `RIL_TEXTLINE`.
  static const int levelLine = 2;

  /// `TessVersion`.
  final Pointer<Utf8> Function() version;

  /// `TessBaseAPICreate`.
  final Pointer<Void> Function() create;

  /// `TessBaseAPIDelete`.
  final void Function(Pointer<Void>) delete;

  /// `TessBaseAPIInit3(handle, datapath, language)`: 0 on success.
  final int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>) init;

  /// `TessBaseAPISetPageSegMode`.
  final void Function(Pointer<Void>, int) setPageSegMode;

  /// `TessBaseAPISetImage(handle, data, width, height, bytesPerPixel,
  /// bytesPerLine)`.
  final void Function(Pointer<Void>, Pointer<Uint8>, int, int, int, int)
  setImage;

  /// `TessBaseAPISetSourceResolution`.
  final void Function(Pointer<Void>, int) setSourceResolution;

  /// `TessBaseAPIRecognize(handle, monitor)`: 0 on success.
  final int Function(Pointer<Void>, Pointer<Void>) recognize;

  /// `TessBaseAPIGetIterator`: null when nothing was recognized.
  final Pointer<Void> Function(Pointer<Void>) getIterator;

  /// `TessBaseAPIClear`: drops the image and the results, keeps the
  /// loaded languages.
  final void Function(Pointer<Void>) clear;

  /// `TessBaseAPIEnd`.
  final void Function(Pointer<Void>) end;

  /// `TessResultIteratorDelete`.
  final void Function(Pointer<Void>) iteratorDelete;

  /// `TessResultIteratorNext(iterator, level)`: false past the last.
  final int Function(Pointer<Void>, int) iteratorNext;

  /// `TessResultIteratorGetUTF8Text`: freed with [deleteText].
  final Pointer<Utf8> Function(Pointer<Void>, int) iteratorText;

  /// `TessResultIteratorGetPageIterator`: the same iterator, seen as a
  /// page iterator; not deleted on its own.
  final Pointer<Void> Function(Pointer<Void>) pageIterator;

  /// `TessPageIteratorIsAtBeginningOf`.
  final int Function(Pointer<Void>, int) isAtBeginningOf;

  /// `TessPageIteratorBoundingBox(iterator, level, &l, &t, &r, &b)`.
  final int Function(
    Pointer<Void>,
    int,
    Pointer<Int32>,
    Pointer<Int32>,
    Pointer<Int32>,
    Pointer<Int32>,
  )
  boundingBox;

  /// `TessDeleteText`.
  final void Function(Pointer<Utf8>) deleteText;

  /// The library's version string (`5.5.3`).
  String versionString() => version().toDartString();
}
