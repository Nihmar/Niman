// A pack is published as one `.tar` of its four files: one download per pack,
// one size and one SHA-256 to pin. A tar and not a zip because the app can
// unpack it as a stream, header by header, with no central directory to find
// at the far end of a 300 MB file and no dependency: each member is a 512-byte
// header and the file's bytes, padded to 512. It is stored uncompressed, since
// `.dict.dz` is compressed already and the rest is small beside it.
//
// The members are flat (`niman-it.ifo`, not `niman-it/niman-it.ifo`): the app
// chooses the folder, so no name in a download can leave it.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

const int _block = 512;

/// The members of a pack, in the order they are written: the `.ifo` first, so
/// a reader knows what it has before it reads the rest.
const List<String> packMemberExtensions = ['ifo', 'idx', 'syn', 'dict.dz'];

/// Writes the files of the pack [id] in [packDir] into the tar [target]. A
/// pack without dictzip (a plain `.dict`) is archived with that instead.
void writePackTar(Directory packDir, String id, File target) {
  final out = target.openSync(mode: FileMode.write);
  try {
    for (final extension in packMemberExtensions) {
      var file = File(p.join(packDir.path, '$id.$extension'));
      if (!file.existsSync() && extension == 'dict.dz') {
        file = File(p.join(packDir.path, '$id.dict'));
      }
      _writeMember(out, p.basename(file.path), file);
    }
    out.writeFromSync(Uint8List(_block * 2));
  } finally {
    out.closeSync();
  }
}

void _writeMember(RandomAccessFile out, String name, File file) {
  final size = file.lengthSync();
  if (name.length > 99) throw StateError('A tar name holds 99 bytes: $name');
  out.writeFromSync(_header(name, size));
  final input = file.openSync();
  try {
    final buffer = Uint8List(1 << 20);
    for (;;) {
      final read = input.readIntoSync(buffer);
      if (read == 0) break;
      out.writeFromSync(buffer, 0, read);
    }
  } finally {
    input.closeSync();
  }
  final padding = (_block - size % _block) % _block;
  if (padding > 0) out.writeFromSync(Uint8List(padding));
}

/// A ustar header for a regular file: fixed times and owners, so the same
/// pack always archives to the same bytes.
Uint8List _header(String name, int size) {
  final header = Uint8List(_block);
  void put(int offset, String text) =>
      header.setRange(offset, offset + text.length, ascii.encode(text));
  put(0, name);
  put(100, '0000644\u0000');
  put(108, '0000000\u0000');
  put(116, '0000000\u0000');
  put(124, '${size.toRadixString(8).padLeft(11, '0')}\u0000');
  put(136, '00000000000\u0000');
  put(148, '        ');
  put(156, '0');
  put(257, 'ustar\u0000');
  put(263, '00');
  final sum = header.fold<int>(0, (a, b) => a + b);
  put(148, '${sum.toRadixString(8).padLeft(6, '0')}\u0000 ');
  return header;
}

/// One member of a tar: its name, and where its bytes start.
typedef TarMember = ({String name, int size, int offset});

/// The members of a tar file, read from the headers alone.
List<TarMember> readTarMembers(File file) {
  final input = file.openSync();
  try {
    final members = <TarMember>[];
    var at = 0;
    final length = input.lengthSync();
    while (at + _block <= length) {
      input.setPositionSync(at);
      final header = input.readSync(_block);
      if (header.every((b) => b == 0)) break;
      final nameEnd = header.indexOf(0);
      final name = ascii.decode(header.sublist(0, nameEnd));
      final sizeText = ascii.decode(header.sublist(124, 135));
      final size = int.parse(sizeText, radix: 8);
      members.add((name: name, size: size, offset: at + _block));
      at += _block + ((size + _block - 1) ~/ _block) * _block;
    }
    return members;
  } finally {
    input.closeSync();
  }
}

/// The bytes of [member] in the tar [file].
Uint8List readTarMember(File file, TarMember member) {
  final input = file.openSync()..setPositionSync(member.offset);
  try {
    return input.readSync(member.size);
  } finally {
    input.closeSync();
  }
}
