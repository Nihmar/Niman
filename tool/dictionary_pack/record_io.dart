// Sequential binary files for the pack pipeline: a buffered writer, and the
// reader of a run of key/value records. Synchronous on purpose: the pipeline is
// a command line, and a `RandomAccessFile` with its own buffer is several times
// faster than a stream of one-record chunks.
import 'dart:io';
import 'dart:typed_data';

/// One record of a sorted run: a [key] the order is taken from and a [value].
final class SortRecord {
  /// A record of [key] and [value].
  const new(this.key, this.value);

  /// What the record is sorted by.
  final Uint8List key;

  /// The rest of the record; it breaks a tie between equal keys.
  final Uint8List value;

  /// The bytes the record takes in memory, roughly: the buffer budget's unit.
  int get weight => key.length + value.length + 96;
}

/// A file written through a buffer of `bufferSize` bytes.
final class BufferedFileWriter {
  /// Creates [file], replacing what was there.
  new(File file, {int bufferSize = 1 << 20})
    : _raf = file.openSync(mode: FileMode.write),
      _buffer = Uint8List(bufferSize);

  final RandomAccessFile _raf;
  final Uint8List _buffer;
  int _used = 0;

  /// The bytes written so far, buffered or not.
  int position = 0;

  /// Appends [bytes].
  void write(List<int> bytes) {
    if (bytes.length > _buffer.length - _used) {
      flush();
      if (bytes.length > _buffer.length) {
        _raf.writeFromSync(bytes);
        position += bytes.length;
        return;
      }
    }
    _buffer.setRange(_used, _used + bytes.length, bytes);
    _used += bytes.length;
    position += bytes.length;
  }

  /// Appends a 32-bit big-endian number, as StarDict writes its offsets.
  void writeUint32(int value) {
    write([
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ]);
  }

  /// Appends one record of [key] and [value], length-prefixed.
  void writeRecord(Uint8List key, Uint8List value) {
    final header = ByteData(8)
      ..setUint32(0, key.length)
      ..setUint32(4, value.length);
    write(header.buffer.asUint8List());
    write(key);
    write(value);
  }

  /// Hands the buffer to the file.
  void flush() {
    if (_used > 0) {
      _raf.writeFromSync(_buffer, 0, _used);
      _used = 0;
    }
  }

  /// Flushes and closes the file.
  void close() {
    flush();
    _raf.closeSync();
  }
}

/// A file read forward through a buffer.
final class BufferedFileReader {
  /// Opens [file].
  new(File file) : _raf = file.openSync();

  final RandomAccessFile _raf;
  Uint8List _buffer = Uint8List(1 << 18);
  int _start = 0;
  int _end = 0;

  /// Makes [count] bytes available; false when the file ends first.
  bool _ensure(int count) {
    if (_end - _start >= count) return true;
    if (_start > 0) {
      _buffer.setRange(0, _end - _start, _buffer, _start);
      _end -= _start;
      _start = 0;
    }
    if (_buffer.length < count) {
      final size = count > _buffer.length * 2 ? count : _buffer.length * 2;
      _buffer = Uint8List(size)..setRange(0, _end, _buffer);
    }
    while (_end < count) {
      final read = _raf.readIntoSync(_buffer, _end, _buffer.length);
      if (read == 0) return false;
      _end += read;
    }
    return true;
  }

  /// The next [count] bytes (a copy), or null at the end of the file.
  Uint8List? read(int count) {
    if (!_ensure(count)) return null;
    final bytes = Uint8List.fromList(
      Uint8List.sublistView(_buffer, _start, _start + count),
    );
    _start += count;
    return bytes;
  }

  /// The next 32-bit big-endian number, or null at the end of the file.
  int? readUint32() {
    if (!_ensure(4)) return null;
    final value = ByteData.sublistView(
      _buffer,
      _start,
      _start + 4,
    ).getUint32(0);
    _start += 4;
    return value;
  }

  /// The next record written by [BufferedFileWriter.writeRecord].
  SortRecord? readRecord() {
    if (!_ensure(8)) return null;
    final header = ByteData.sublistView(_buffer, _start, _start + 8);
    final keyLength = header.getUint32(0);
    final valueLength = header.getUint32(4);
    _start += 8;
    final key = read(keyLength);
    final value = read(valueLength);
    if (key == null || value == null) {
      throw const FormatException('A run ends inside a record.');
    }
    return SortRecord(key, value);
  }

  /// Closes the file.
  void close() => _raf.closeSync();
}
