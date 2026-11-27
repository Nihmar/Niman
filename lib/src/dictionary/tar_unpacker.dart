import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Unpacks the uncompressed ustar archive a dictionary pack is published
/// as (`niman-it.tar`, written by `tool/dictionary_pack/pack_archive.dart`):
/// the pack's four files, flat, one header and one run of bytes each.
///
/// Written by hand and read as a stream, header by header, so a 300 MB pack
/// is never in memory and no central directory has to be found at its end;
/// `package:archive` would hold the whole archive. It is strict, because
/// what it reads came from the network: a member that is not a plain file
/// of a flat name, a bad checksum, a name the caller does not expect or an
/// archive that ends before its end marker is [FormatException], never a
/// half-written folder that looks complete.
final class TarUnpacker {
  const new _();

  static const int _block = 512;

  /// Writes every member of [archive] into [folder] (made if it is not
  /// there) and returns their names, in the order they were stored.
  ///
  /// [accepts] says which member names the caller expects; any other is
  /// refused before a byte of it is written. Synchronous: call it on an
  /// isolate of its own.
  static List<String> unpackSync(
    File archive,
    Directory folder, {
    bool Function(String name)? accepts,
  }) {
    final input = archive.openSync();
    try {
      final length = input.lengthSync();
      folder.createSync(recursive: true);
      final names = <String>[];
      var at = 0;
      for (;;) {
        if (at + _block > length) {
          throw const FormatException('the archive ends before its end marker');
        }
        input.setPositionSync(at);
        final header = input.readSync(_block);
        if (header.length < _block) {
          throw const FormatException('the archive ends inside a header');
        }
        // Two zero blocks close an archive; the first is enough to know.
        if (header.every((byte) => byte == 0)) return names;
        final (:name, :size) = _readHeader(header);
        if (accepts != null && !accepts(name)) {
          throw FormatException('unexpected member $name');
        }
        if (names.contains(name)) {
          throw FormatException('member $name twice');
        }
        final padded = (size + _block - 1) ~/ _block * _block;
        if (at + _block + padded > length) {
          throw FormatException('the archive ends inside $name');
        }
        _copy(input, File(p.join(folder.path, name)), size);
        names.add(name);
        at += _block + padded;
      }
    } finally {
      input.closeSync();
    }
  }

  /// The name and size of the member whose header is [header]; refuses
  /// whatever is not a regular file with a flat name.
  static ({String name, int size}) _readHeader(Uint8List header) {
    final stored = _octal(header, 148, 8);
    var sum = 0;
    for (var i = 0; i < _block; i++) {
      // The checksum field counts as eight spaces.
      sum += i >= 148 && i < 156 ? 0x20 : header[i];
    }
    if (stored != sum) throw const FormatException('a header is corrupt');
    final type = header[156];
    if (type != 0x30 && type != 0) {
      throw FormatException('member of type ${String.fromCharCode(type)}');
    }
    if (header[345] != 0) {
      throw const FormatException('a member has a path prefix');
    }
    final name = _text(header, 0, 100);
    if (!_isFlat(name)) throw FormatException('member name "$name"');
    final size = _octal(header, 124, 12);
    return (name: name, size: size);
  }

  /// Whether [name] is a bare file name: nothing in it can reach another
  /// folder or another drive.
  static bool _isFlat(String name) =>
      name.isNotEmpty &&
      name != '.' &&
      name != '..' &&
      !name.contains(RegExp(r'[/\\:\u0000]')) &&
      !name.startsWith('.');

  static String _text(Uint8List bytes, int start, int length) {
    var end = start;
    while (end < start + length && bytes[end] != 0) {
      end++;
    }
    try {
      return utf8.decode(bytes.sublist(start, end));
    } on FormatException {
      throw const FormatException('a member name is not UTF-8');
    }
  }

  static int _octal(Uint8List bytes, int start, int length) {
    final text = _text(bytes, start, length).trim();
    final value = int.tryParse(text.isEmpty ? '0' : text, radix: 8);
    if (value == null || value < 0) {
      throw FormatException('a header number is not octal: "$text"');
    }
    return value;
  }

  /// Copies [size] bytes from where [input] is to [target].
  static void _copy(RandomAccessFile input, File target, int size) {
    final output = target.openSync(mode: FileMode.write);
    try {
      final buffer = Uint8List(1 << 20);
      var left = size;
      while (left > 0) {
        final read = input.readIntoSync(
          buffer,
          0,
          left < buffer.length ? left : buffer.length,
        );
        if (read == 0) throw const FormatException('a member is cut short');
        output.writeFromSync(buffer, 0, read);
        left -= read;
      }
    } finally {
      output.closeSync();
    }
  }
}
