import 'dart:io';

import 'package:crypto/crypto.dart';

/// [handle]'s bytes from its start, chunk by chunk, with their digest
/// handed to [sent] once the file has gone: one subscription reads the
/// file again, for a body a redirect hop sends twice. A body the client
/// stopped early still hands its digest over — the caller must see it
/// did not send the whole file.
Stream<List<int>> webDavFileBody(
  RandomAccessFile handle,
  void Function(String sha) sent,
) async* {
  final digest = sha256.startChunkedConversion(
    _TakeDigest((value) => sent(value.toString())),
  );
  try {
    await handle.setPosition(0);
    while (true) {
      final chunk = await handle.read(64 << 10);
      if (chunk.isEmpty) break;
      digest.add(chunk);
      yield chunk;
    }
  } finally {
    digest.close();
  }
}

/// Takes the one digest a chunked hash makes when it is closed.
final class _TakeDigest implements Sink<Digest> {
  new(this._take);

  final void Function(Digest digest) _take;

  @override
  void add(Digest data) => _take(data);

  @override
  void close() {}
}
