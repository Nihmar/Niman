/// A picture on the clipboard — a screenshot tool's capture, an image a
/// browser copied — as a file a paste attaches like a copied one (#1249):
/// the platform hands over its encoded bytes, kept here under a name of
/// their own in the temporary folder, from where the attachment's copy
/// takes them into the library.
///
/// A clipboard that holds text as well is left to the text: a spreadsheet's
/// cells come with a picture of themselves, and they paste as a table
/// (#1248). Each platform's reader asks that first.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:niman/src/core/logging.dart';
import 'package:path/path.dart' as p;

const _log = AppLogger(name: 'paste');

/// The name a picture pasted at [at] is kept under: there is no file name
/// to keep, so it says what it is and when it came.
String clipboardPictureName(DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'pasted-image-${at.year}-${two(at.month)}-${two(at.day)}-'
      '${two(at.hour)}${two(at.minute)}${two(at.second)}.png';
}

/// Writes the PNG [png] into a folder of its own under [base] — the system
/// temporary folder's `niman-clipboard-picture` unless a test names
/// another — and answers its path. The folder is emptied first: the last
/// paste's picture has been copied into the library by then.
Future<String> keepClipboardPicture(
  Uint8List png, {
  DateTime? now,
  Directory? base,
}) async {
  final at = now ?? DateTime.now();
  final root = base ?? Directory(p.join(Directory.systemTemp.path, _folder));
  try {
    if (await root.exists()) await root.delete(recursive: true);
  } on FileSystemException catch (error) {
    // A picture still held open by a scanner stays behind; the next one
    // goes into a folder of its own all the same.
    _log.debug('picture: the last one stays ($error)');
  }
  final folder = Directory(
    p.join(root.path, at.microsecondsSinceEpoch.toString()),
  );
  await folder.create(recursive: true);
  final file = File(p.join(folder.path, clipboardPictureName(at)));
  await file.writeAsBytes(png, flush: true);
  _log.info('picture: ${png.length} b kept for the paste');
  return file.path;
}

const _folder = 'niman-clipboard-picture';

/// The BMP file a Windows clipboard's `CF_DIB` is the body of: the
/// clipboard leaves out the 14-byte file header, which says where the
/// pixels start — after the info header, the colour masks a 40-byte header
/// is followed by when it says bit fields, and the colour table. Null when
/// [dib] is too short to be one.
Uint8List? bmpOfDib(Uint8List dib) {
  if (dib.length < _infoHeader) return null;
  final view = ByteData.sublistView(dib);
  final headerSize = view.getUint32(0, Endian.little);
  if (headerSize < _infoHeader || headerSize > dib.length) return null;
  final bitCount = view.getUint16(14, Endian.little);
  final compression = view.getUint32(16, Endian.little);
  final colorsUsed = view.getUint32(32, Endian.little);
  final masks = headerSize == _infoHeader
      ? switch (compression) {
          _biBitfields => 12,
          _biAlphaBitfields => 16,
          _ => 0,
        }
      : 0;
  final colors = colorsUsed != 0
      ? colorsUsed
      : (bitCount <= 8 ? 1 << bitCount : 0);
  final offset = _fileHeader + headerSize + masks + colors * 4;
  final file = Uint8List(_fileHeader + dib.length);
  if (offset > file.length) return null;
  ByteData.sublistView(file, 0, _fileHeader)
    ..setUint8(0, 0x42) // 'B'
    ..setUint8(1, 0x4D) // 'M'
    ..setUint32(2, file.length, Endian.little)
    ..setUint32(10, offset, Endian.little);
  file.setRange(_fileHeader, file.length, dib);
  return file;
}

/// [png] up to the end of its `IEND` chunk: a Windows clipboard block is as
/// long as its allocation, which may round the file up with bytes after it.
/// As it came when it has no such end.
Uint8List trimmedPng(Uint8List png) {
  for (var i = png.length - 8; i >= 8; i--) {
    if (png[i] == 0x49 &&
        png[i + 1] == 0x45 &&
        png[i + 2] == 0x4E &&
        png[i + 3] == 0x44) {
      // The type, then its CRC: the file ends there.
      return Uint8List.sublistView(png, 0, i + 8);
    }
  }
  return png;
}

const _fileHeader = 14;
const _infoHeader = 40;
const _biBitfields = 3;
const _biAlphaBitfields = 6;

/// [encoded] — a BMP, a JPEG, anything the engine decodes — as a PNG, the
/// one format a pasted picture is kept in; null when it decodes to nothing.
Future<Uint8List?> pngOf(Uint8List encoded) async {
  try {
    final codec = await ui.instantiateImageCodec(encoded);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final image = frame.image;
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image.dispose();
    }
  } on Object catch (error) {
    _log.warning('picture: not decoded ($error)');
    return null;
  }
}
