/// What the conflict screen shows of one conflicted file, and which
/// versions those were.
library;

import 'package:meta/meta.dart';

/// Both sides of a conflicted file as they were read for the user, plus
/// the version they last agreed on when history still has it.
///
/// The hashes and the ETag say which versions the user decided on: a
/// resolution carries them back, and the engine refuses to write over a
/// side that moved since. Without that, "Keep this device's" pressed a
/// minute after the screen opened would upload over an edit that reached
/// the server in that minute, and that edit exists nowhere else to come
/// back from.
@immutable
final class ConflictTexts {
  /// The two sides as read, with their [localSha256] and [remoteSha256],
  /// and the [base] when there is one.
  const new({
    required this.local,
    required this.remote,
    required this.localSha256,
    required this.remoteSha256,
    this.base,
    this.remoteEtag,
  });

  /// The file on this device, decoded as UTF-8.
  final String local;

  /// The server's copy, decoded as UTF-8.
  final String remote;

  /// The version both sides last agreed on, or null.
  final String? base;

  /// The sha256 of the local bytes read.
  final String localSha256;

  /// The sha256 of the server's bytes read.
  final String remoteSha256;

  /// The server's ETag for the copy read, when it gives one.
  final String? remoteEtag;
}
