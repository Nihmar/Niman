// A picture on the clipboard pasted into a note (device report, 2026-11-03:
// the Snipping Tool's capture did nothing): kept as a file a paste attaches
// like a copied one (#1249), never when text is there beside it — a
// spreadsheet's cells come with a picture of themselves (#1248). The
// native halves are pinned to what the Dart half asks, as
// `clipboard_files_test.dart` pins the files'.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/paste/clipboard_files.dart';
import 'package:niman/src/capture/paste/clipboard_picture.dart';
import 'package:path/path.dart' as p;

/// The source at [parts] of the repo root, its comments taken out.
String code(List<String> parts) =>
    File(p.joinAll(parts))
        .readAsStringSync()
        .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
        .replaceAll(RegExp(r'//[^\n]*'), '');

/// A `CF_DIB` of a 40-byte header, [bitCount] bits a pixel, [compression],
/// [colors] palette entries and [pixels] after them.
Uint8List dib({
  required int width,
  required int height,
  required int bitCount,
  int compression = 0,
  int colors = 0,
  int masks = 0,
  List<int> pixels = const [],
}) {
  final header = ByteData(40)
    ..setUint32(0, 40, Endian.little)
    ..setInt32(4, width, Endian.little)
    ..setInt32(8, height, Endian.little)
    ..setUint16(12, 1, Endian.little)
    ..setUint16(14, bitCount, Endian.little)
    ..setUint32(16, compression, Endian.little)
    ..setUint32(32, colors, Endian.little);
  final paletteSize =
      (colors != 0 ? colors : (bitCount <= 8 ? 1 << bitCount : 0)) * 4;
  return Uint8List.fromList([
    ...header.buffer.asUint8List(),
    ...List<int>.filled(masks + paletteSize, 0),
    ...pixels,
  ]);
}

int pixelOffset(Uint8List bmp) =>
    ByteData.sublistView(bmp).getUint32(10, Endian.little);

const pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a pasted picture is named for when it came', () {
    expect(
      clipboardPictureName(DateTime(2026, 11, 3, 17, 5, 9)),
      'pasted-image-2026-11-03-170509.png',
    );
  });

  test('it is kept in a folder of its own, the last one gone', () async {
    final base = Directory.systemTemp.createTempSync('niman_picture_');
    addTearDown(() => base.deleteSync(recursive: true));
    final first = await keepClipboardPicture(
      Uint8List.fromList([1, 2]),
      now: DateTime(2026, 11, 3, 17),
      base: base,
    );
    final second = await keepClipboardPicture(
      Uint8List.fromList([3, 4]),
      now: DateTime(2026, 11, 3, 17, 1),
      base: base,
    );
    expect(File(first).existsSync(), isFalse);
    expect(File(second).readAsBytesSync(), [3, 4]);
    expect(p.basename(second), 'pasted-image-2026-11-03-170100.png');
  });

  group('a CF_DIB made a BMP', () {
    test('24 bits: the pixels right after the headers', () {
      final bmp = bmpOfDib(dib(width: 1, height: 1, bitCount: 24))!;
      expect(bmp.sublist(0, 2), [0x42, 0x4D]);
      expect(pixelOffset(bmp), 14 + 40);
      expect(ByteData.sublistView(bmp).getUint32(2, Endian.little), bmp.length);
    });

    test('8 bits: after the palette', () {
      final bmp = bmpOfDib(dib(width: 1, height: 1, bitCount: 8))!;
      expect(pixelOffset(bmp), 14 + 40 + 256 * 4);
      final few = bmpOfDib(dib(width: 1, height: 1, bitCount: 8, colors: 2))!;
      expect(pixelOffset(few), 14 + 40 + 2 * 4);
    });

    test('bit fields: after the three masks', () {
      final bmp = bmpOfDib(
        dib(width: 1, height: 1, bitCount: 32, compression: 3, masks: 12),
      )!;
      expect(pixelOffset(bmp), 14 + 40 + 12);
    });

    test('too short to be one is none', () {
      expect(bmpOfDib(Uint8List(10)), isNull);
    });
  });

  testWidgets('a BMP is kept as a PNG of the same picture', (tester) async {
    // Two pixels of 24 bits, blue then red (BGR), a row padded to four.
    final bmp = bmpOfDib(
      dib(
        width: 2,
        height: 1,
        bitCount: 24,
        pixels: [255, 0, 0, 0, 0, 255, 0, 0],
      ),
    )!;
    final png = (await tester.runAsync(() => pngOf(bmp)))!;
    expect(png.sublist(0, 8), pngSignature);
    final size = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      return (frame.image.width, frame.image.height);
    });
    expect(size, (2, 1));
    expect(await tester.runAsync(() => pngOf(Uint8List(4))), isNull);
  });

  test('a Windows block is cut at the end of its PNG', () {
    final png = Uint8List.fromList([
      ...pngSignature,
      0, 0, 0, 0, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
      0, 0, 0, 0,
    ]);
    expect(trimmedPng(png), hasLength(png.length - 4));
    expect(trimmedPng(Uint8List.fromList([1, 2, 3])), [1, 2, 3]);
  });

  test('over the channel: no files, then the picture', () async {
    const channel = MethodChannel('niman/clipboard');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final png = Uint8List.fromList([...pngSignature, 1, 2, 3]);

    messenger.setMockMethodCallHandler(
      channel,
      (call) async => switch (call.method) {
        'readFiles' => <String>[],
        'readImage' => png,
        _ => null,
      },
    );
    final kept = await const ChannelClipboardFiles().read();
    expect(kept, hasLength(1));
    expect(p.extension(kept.single), '.png');
    expect(File(kept.single).readAsBytesSync(), png);

    // A runner without it (Android, iOS) has handed its pictures over as
    // files already.
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'readFiles'
          ? <String>[]
          : throw MissingPluginException(),
    );
    expect(await const ChannelClipboardFiles().read(), isEmpty);
  });

  group('the native halves', () {
    test('Linux asks for the picture only when there is no text', () {
      final source = code(['linux', 'runner', 'clipboard_html.cc']);
      expect(source, contains('"readImage"'));
      expect(source, contains('gtk_targets_include_text'));
      expect(source, contains('gtk_clipboard_request_image'));
      expect(source, contains('"png"'));
      expect(source, isNot(contains('gtk_clipboard_wait_for')));
    });

    test('macOS answers a PNG, its TIFF made one, never over text', () {
      final sources = [
        'packages',
        'niman_apple',
        'darwin',
        'niman_apple',
        'Sources',
        'niman_apple',
      ];
      expect(
        code([...sources, 'ClipboardBridge.swift']),
        contains('"readImage"'),
      );
      final files = code([...sources, 'ClipboardFiles.swift']);
      expect(files, contains('types.contains(.string)'));
      expect(files, contains('forType: .png'));
      expect(files, contains('forType: .tiff'));
    });

    test('Windows asks about text before it reads a picture', () {
      final source = code([
        'lib',
        'src',
        'capture',
        'paste',
        'windows_clipboard_files.dart',
      ]);
      expect(source, contains('_cfUnicodeText = 13'));
      expect(source, contains('_cfDib = 8'));
      expect(source, contains("_register('PNG')"));
      final text = source.indexOf('_formatAvailable(_cfUnicodeText)');
      final picture = source.indexOf('_block(png ? _png : _cfDib)');
      expect(text, isNonNegative);
      expect(text, lessThan(picture));
    });
  });
}
