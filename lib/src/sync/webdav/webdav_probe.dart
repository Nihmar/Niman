import 'dart:convert';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';

/// What a destination can do, as measured by [probeWebDav]
/// (docs/records/sync.md, "Server capabilities").
///
/// Every flag off is a working server in compatible mode; the flags only
/// turn optimizations on.
@immutable
final class WebDavCapabilities {
  /// Capabilities measured at [probedAt].
  const new({
    required this.probedAt,
    this.davClasses = const {},
    this.fileEtags = false,
    this.collectionEtags = false,
    this.ifMatch = false,
    this.ifNoneMatch = false,
    this.move = false,
    this.fileIds = false,
    this.checksums = false,
    this.ocMtime = false,
  });

  /// How old a probe may get before a sync runs it again.
  static const maxAge = Duration(days: 30);

  /// When the probe ran.
  final DateTime probedAt;

  /// The `DAV:` classes `OPTIONS` advertised (may be empty: some servers
  /// answer `PROPFIND` without advertising anything).
  final Set<String> davClasses;

  /// Files carry an ETag that changes when their content does.
  final bool fileEtags;

  /// A folder's ETag changes when anything below it changes, so an
  /// unchanged folder can be skipped whole.
  final bool collectionEtags;

  /// A `PUT` with a stale `If-Match` is refused with 412.
  final bool ifMatch;

  /// A `PUT` with `If-None-Match: *` onto an existing file is refused.
  final bool ifNoneMatch;

  /// `MOVE` works (renames without re-uploading).
  final bool move;

  /// Items carry `oc:fileid` (remote renames are detectable).
  final bool fileIds;

  /// Items carry `oc:checksums`.
  final bool checksums;

  /// The server keeps the `X-OC-Mtime` sent with an upload.
  final bool ocMtime;

  /// Whether the probe is old enough to run again at [now].
  bool isStale(DateTime now) => now.difference(probedAt) > maxAge;

  /// One line for the log: every capability with the fallback it picks.
  String describe() => [
    if (fileEtags)
      'file etags'
    else
      'no file etags (size + mtime, hash on doubt)',
    if (collectionEtags)
      'collection etags'
    else
      'no collection etags (Depth 1 per folder)',
    if (ifMatch) 'If-Match' else 'no If-Match (PROPFIND before PUT)',
    if (ifNoneMatch)
      'If-None-Match'
    else
      'no If-None-Match (PROPFIND before PUT)',
    if (move) 'MOVE' else 'no MOVE (DELETE + PUT)',
    if (fileIds) 'file ids' else 'no file ids (renames = delete + create)',
    if (checksums) 'checksums' else 'no checksums (sha256 while streaming)',
    if (ocMtime) 'X-OC-Mtime' else "no X-OC-Mtime (server's mtime)",
  ].join('; ');

  /// The JSON stored in `sync_destinations.capabilities`.
  Map<String, Object> toJson() => {
    'probedAt': probedAt.millisecondsSinceEpoch,
    'dav': davClasses.toList()..sort(),
    'fileEtags': fileEtags,
    'collectionEtags': collectionEtags,
    'ifMatch': ifMatch,
    'ifNoneMatch': ifNoneMatch,
    'move': move,
    'fileIds': fileIds,
    'checksums': checksums,
    'ocMtime': ocMtime,
  };

  /// [toJson]'s JSON as text.
  String encode() => jsonEncode(toJson());

  /// The capabilities in [json], or null when there are none (never
  /// probed, `{}`, or unreadable).
  static WebDavCapabilities? fromJson(Object? json) {
    if (json is! Map) return null;
    final probedAt = json['probedAt'];
    if (probedAt is! int) return null;
    bool flag(String key) => json[key] == true;
    final dav = json['dav'];
    return WebDavCapabilities(
      probedAt: DateTime.fromMillisecondsSinceEpoch(probedAt),
      davClasses: {
        if (dav is List)
          for (final c in dav)
            if (c is String) c,
      },
      fileEtags: flag('fileEtags'),
      collectionEtags: flag('collectionEtags'),
      ifMatch: flag('ifMatch'),
      ifNoneMatch: flag('ifNoneMatch'),
      move: flag('move'),
      fileIds: flag('fileIds'),
      checksums: flag('checksums'),
      ocMtime: flag('ocMtime'),
    );
  }

  /// [fromJson] on stored text; null for `''`, `{}` or garbage.
  static WebDavCapabilities? decode(String text) {
    if (text.trim().isEmpty) return null;
    try {
      return fromJson(jsonDecode(text));
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is WebDavCapabilities && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;

  @override
  String toString() => 'WebDavCapabilities(${describe()})';
}

const _log = AppLogger(name: 'webdav');

/// Measures what the destination behind [client] can do
/// (docs/records/sync.md, "The probe").
///
/// Works inside a scratch folder `.niman-probe-<random>/` that it deletes
/// at the end, also on failure. Throws [WebDavAuthFailure] for wrong
/// credentials, [WebDavUnsupported] when the folder does not speak
/// WebDAV or refuses the verbs the sync needs, and the transport
/// failures as they come; every optional capability that fails only
/// comes back false.
Future<WebDavCapabilities> probeWebDav(
  WebDavClient client, {
  DateTime Function() now = DateTime.now,
  Random? random,
}) async {
  final clock = Stopwatch()..start();
  _log.info('probe: start');
  final dav = await _checkWebDav(client);
  final rng = random ?? Random.secure();
  final suffix = [
    for (var i = 0; i < 4; i++)
      rng.nextInt(1 << 16).toRadixString(16).padLeft(4, '0'),
  ].join();
  final scratch = '.niman-probe-$suffix';
  final file = '$scratch/sub/a.txt';

  try {
    try {
      await client.createFolder(scratch);
      await client.createFolder('$scratch/sub');
    } on WebDavUnsupported catch (e) {
      throw WebDavUnsupported(
        'folders cannot be created (MKCOL refused)',
        status: e.status,
      );
    }
    await _put(client, file, 'niman probe 1');
    final folder1 = await client.stat(scratch, collection: true);
    final file1 = await client.stat(file);
    if (file1 == null) {
      throw const WebDavUnsupported('an uploaded file is not listed');
    }
    await _put(client, file, 'niman probe 2, longer');
    final folder2 = await client.stat(scratch, collection: true);
    final file2 = await client.stat(file);

    final fileEtags =
        file1.etag != null && file2?.etag != null && file1.etag != file2?.etag;
    final collectionEtags =
        folder1?.etag != null &&
        folder2?.etag != null &&
        folder1?.etag != folder2?.etag;

    final ifMatch = await _refused(
      () => _put(client, file, 'niman probe 3', ifMatch: '"niman-wrong"'),
    );
    final ifNoneMatch = await _refused(
      () => _put(client, file, 'niman probe 4', ifNoneMatch: true),
    );

    var ocMtime = false;
    final stamp = DateTime.utc(2001, 2, 3, 4, 5, 6);
    try {
      final upload = await _put(client, file, 'niman probe 5', modified: stamp);
      final after = await client.stat(file);
      ocMtime = upload.mtimeAccepted || after?.modified == stamp;
    } on WebDavFailure catch (e) {
      if (e is WebDavAuthFailure || e is WebDavRetryable) rethrow;
    }

    var move = false;
    try {
      await client.move(file, '$scratch/sub/b.txt');
      move =
          await client.stat('$scratch/sub/b.txt') != null &&
          await client.stat(file) == null;
    } on WebDavFailure catch (e) {
      if (e is WebDavAuthFailure || e is WebDavRetryable) rethrow;
    }

    final capabilities = WebDavCapabilities(
      probedAt: now(),
      davClasses: dav,
      fileEtags: fileEtags,
      collectionEtags: collectionEtags,
      ifMatch: ifMatch,
      ifNoneMatch: ifNoneMatch,
      move: move,
      fileIds: file1.fileId != null,
      checksums: file1.checksums.isNotEmpty,
      ocMtime: ocMtime,
    );
    _log.info(
      'probe: done in ${clock.elapsedMilliseconds} ms: '
      '${capabilities.describe()}',
    );
    return capabilities;
  } finally {
    try {
      await client.delete(scratch, collection: true);
    } on WebDavFailure catch (e) {
      _log.warning('probe: could not delete the scratch folder: $e');
    }
  }
}

/// `OPTIONS`, then `PROPFIND` on the folder when `OPTIONS` is refused or
/// advertises nothing (some proxies eat it). Returns the `DAV:` classes.
Future<Set<String>> _checkWebDav(WebDavClient client) async {
  var dav = <String>{};
  try {
    final info = await client.options();
    dav = info.davClasses;
    if (info.isWebDav) return dav;
    _log.info('probe: OPTIONS advertises no DAV class, trying PROPFIND');
  } on WebDavUnsupported {
    _log.info('probe: OPTIONS refused, trying PROPFIND');
  } on WebDavProtocolFailure {
    _log.info('probe: OPTIONS failed, trying PROPFIND');
  }
  try {
    await client.propfind('', depth: 0, collection: true);
    return dav;
  } on WebDavNotFound catch (e) {
    throw WebDavNotFound('the folder does not exist', status: e.status);
  } on WebDavUnsupported catch (e) {
    throw WebDavUnsupported('not a WebDAV folder', status: e.status);
  } on WebDavProtocolFailure catch (e) {
    throw WebDavUnsupported('not a WebDAV folder', status: e.status);
  }
}

Future<WebDavUpload> _put(
  WebDavClient client,
  String path,
  String text, {
  String? ifMatch,
  bool ifNoneMatch = false,
  DateTime? modified,
}) {
  final bytes = utf8.encode(text);
  return client.upload(
    path,
    open: () => Stream.value(bytes),
    length: bytes.length,
    ifMatch: ifMatch,
    ifNoneMatch: ifNoneMatch,
    modified: modified,
  );
}

/// Whether [write] was refused with 412 (the precondition is honored).
Future<bool> _refused(Future<Object?> Function() write) async {
  try {
    await write();
    return false;
  } on WebDavPrecondition {
    return true;
  } on WebDavFailure catch (e) {
    if (e is WebDavAuthFailure || e is WebDavRetryable) rethrow;
    return false;
  }
}
