/// Reading one zip entry into memory without ever holding more than a budget
/// of it (#492).
///
/// A zip declares each entry's size, and a bomb lies about it: a few
/// kilobytes of deflate that expand to gigabytes. `package:archive` cannot
/// be trusted to stop that — on `dart:io` its `ZLibDecoder.decodeStream`
/// hands the output to the sink only after the whole stream is inflated, so a
/// sink that refuses the excess refuses it after the allocation it was meant
/// to prevent. The inflate is therefore done here, in chunks, against the
/// raw compressed bytes of the entry: each chunk that comes out is counted
/// as it comes out, and the first one past the budget ends the read.
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:meta/meta.dart';

/// How much compressed input is fed to the inflater at a time. What one call
/// expands to is bounded by the inflater's own output buffer, not by this.
const int _inputChunk = 16 * 1024;

/// An entry that would expand past the budget it was read against.
final class EntryOverBudget implements Exception {
  /// An entry that went over [limit] bytes.
  const new(this.limit);

  /// The budget it went over, in bytes.
  final int limit;

  @override
  String toString() => 'EntryOverBudget: expands past $limit bytes';
}

/// The bytes of [file], refusing to produce more than [limit] of them.
///
/// Null when the entry holds no content at all (a symlink, a placeholder):
/// there is nothing to write for it. Throws [EntryOverBudget] when the entry
/// would go over. A deflated entry is
/// inflated in chunks that stop at the budget; a stored one is compared with
/// the budget before it is read. [onInflated] hears the length of every
/// chunk the inflater produces, so a test can say how far the inflation got
/// before the refusal.
Uint8List? readEntryWithin(
  ArchiveFile file,
  int limit, {
  @visibleForTesting void Function(int length)? onInflated,
}) {
  final raw = file.rawContent;
  if (raw == null) return null;
  if (raw is ZipFile) {
    final method = raw.compressionMethod;
    if (method == CompressionType.deflate) {
      return _inflate(raw.getStream(decompress: false), limit, onInflated);
    }
    if (method == CompressionType.none) {
      return _stored(raw.getStream(decompress: false), limit);
    }
  }
  // Any other content: whatever writes its bytes into a sink that counts.
  final output = _BoundedBytes(limit);
  try {
    file.writeContent(output);
  } on _OverLimit {
    throw EntryOverBudget(limit);
  }
  return output.getBytes();
}

Uint8List _stored(InputStream stream, int limit) {
  if (stream.length > limit) throw EntryOverBudget(limit);
  return stream.toUint8List();
}

Uint8List _inflate(
  InputStream stream,
  int limit,
  void Function(int length)? onInflated,
) {
  final out = BytesBuilder();
  final inflater = ZLibCodec(raw: true).decoder
      .startChunkedConversion(_LimitedSink(limit, out, onInflated));
  while (!stream.isEOS) {
    inflater.add(
      stream.readBytes(min(_inputChunk, stream.length)).toUint8List(),
    );
  }
  inflater.close();
  return out.takeBytes();
}

/// Collects what the inflater produces, refusing the chunk that would take it
/// past [limit] — before it is kept, so the excess is never held.
final class _LimitedSink implements Sink<List<int>> {
  new(this.limit, this.out, this.onInflated);

  final int limit;
  final BytesBuilder out;
  final void Function(int length)? onInflated;

  @override
  void add(List<int> chunk) {
    onInflated?.call(chunk.length);
    if (out.length + chunk.length > limit) throw EntryOverBudget(limit);
    out.add(chunk);
  }

  @override
  void close() {}
}

/// An output stream that holds at most a budget's worth of bytes and refuses
/// the rest, ending the decode that writes into it.
final class _BoundedBytes extends OutputMemoryStream {
  new(this.limit);

  /// The most this holds before it refuses more.
  final int limit;

  void _guard(int more) {
    if (length + more > limit) throw const _OverLimit();
  }

  @override
  void writeByte(int value) {
    _guard(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _guard(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _guard(stream.length);
    super.writeStream(stream);
  }

  @override
  void writeBackReference(int distance, int count) {
    _guard(count);
    super.writeBackReference(distance, count);
  }
}

final class _OverLimit implements Exception {
  const new();
}
