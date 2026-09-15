import 'dart:convert';

import 'package:meta/meta.dart';

/// Why a history version was taken (docs/dev/sync.md, "What a version is").
enum HistoryReason {
  /// The note as it was when an editing session started.
  session,

  /// The newest version had grown older than the history interval.
  interval,

  /// Right before a restore overwrote the note.
  restore,

  /// Right before sync overwrote the note with a download or merge.
  sync,

  /// Right before a library-wide replace rewrote the note.
  replace,

  /// Read back from a `.v<n>` file the manifest did not describe.
  unknown;

  /// The reason stored under [name], or [unknown].
  static HistoryReason parse(Object? name) {
    for (final reason in values) {
      if (reason.name == name) return reason;
    }
    return unknown;
  }
}

/// One kept version of a note: the file `.history/<path>.v<number>`.
@immutable
final class HistoryVersion {
  /// Describes version [number].
  const new({
    required this.number,
    required this.savedAt,
    required this.reason,
    required this.size,
    required this.sha256,
  });

  /// The `n` of `.v<n>`: grows forever, never reused — a stable id.
  final int number;

  /// When the version was taken.
  final DateTime savedAt;

  /// Why it was taken.
  final HistoryReason reason;

  /// Its size in bytes.
  final int size;

  /// Hex sha256 of its bytes; empty when unknown (rebuilt entries).
  final String sha256;

  /// The manifest JSON for this version.
  Map<String, Object> toJson() => {
    'v': number,
    'savedAt': savedAt.millisecondsSinceEpoch,
    'reason': reason.name,
    'size': size,
    'sha256': sha256,
  };

  /// The version in [json], or null when it does not decode.
  static HistoryVersion? fromJson(Object? json) {
    if (json is! Map) return null;
    final number = json['v'];
    final savedAt = json['savedAt'];
    final size = json['size'];
    final sha = json['sha256'];
    if (number is! int || number < 1 || savedAt is! int || size is! int) {
      return null;
    }
    return HistoryVersion(
      number: number,
      savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt),
      reason: HistoryReason.parse(json['reason']),
      size: size,
      sha256: sha is String ? sha : '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HistoryVersion &&
      other.number == number &&
      other.savedAt == savedAt &&
      other.reason == reason &&
      other.size == size &&
      other.sha256 == sha256;

  @override
  int get hashCode => Object.hash(number, savedAt, reason, size, sha256);

  @override
  String toString() =>
      'v$number(${reason.name}, $size b, '
      '${sha256.isEmpty ? '?' : sha256.substring(0, 8)})';
}

/// The pin that holds the sync base (docs/dev/sync.md, "Rotation").
const String syncBasePin = 'syncBase';

/// A note's history manifest: `.history/<path>.json`.
///
/// Versions are kept oldest first. Pins name versions rotation must keep.
@immutable
final class HistoryManifest {
  /// A manifest with [versions] (any order; stored oldest first) and
  /// [pins].
  new({
    Iterable<HistoryVersion> versions = const [],
    Map<String, int> pins = const {},
  }) : versions = List<HistoryVersion>.unmodifiable(
         <HistoryVersion>[...versions]
           ..sort((a, b) => a.number.compareTo(b.number)),
       ),
       pins = Map<String, int>.unmodifiable(pins);

  /// Reads a manifest file's [text], tolerating damage: text that is not
  /// a JSON object reads as an empty manifest, and entries that do not
  /// decode are skipped — one bad entry never hides the rest.
  factory decode(String text) {
    if (text.trim().isEmpty) return HistoryManifest();
    Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return HistoryManifest();
    }
    if (json is! Map) return HistoryManifest();
    final rawVersions = json['versions'];
    final rawPins = json['pins'];
    final byNumber = <int, HistoryVersion>{};
    if (rawVersions is List) {
      for (final raw in rawVersions) {
        final v = HistoryVersion.fromJson(raw);
        if (v != null) byNumber[v.number] = v;
      }
    }
    return HistoryManifest(
      versions: byNumber.values,
      pins: {
        if (rawPins is Map)
          for (final e in rawPins.entries)
            if (e.key is String && e.value is int && (e.value as int) > 0)
              e.key as String: e.value as int,
      },
    );
  }

  /// The kept versions, oldest first.
  final List<HistoryVersion> versions;

  /// Pin name → pinned version number.
  final Map<String, int> pins;

  /// The newest version, or null when there is none.
  HistoryVersion? get newest => versions.isEmpty ? null : versions.last;

  /// The number the next version takes: one past the highest ever seen,
  /// pinned ones included.
  int get nextNumber {
    var highest = 0;
    for (final v in versions) {
      if (v.number > highest) highest = v.number;
    }
    for (final n in pins.values) {
      if (n > highest) highest = n;
    }
    return highest + 1;
  }

  /// The version numbered [number], or null.
  HistoryVersion? version(int number) {
    for (final v in versions) {
      if (v.number == number) return v;
    }
    return null;
  }

  /// Whether a pin holds [number].
  bool isPinned(int number) => pins.containsValue(number);

  /// This manifest plus [version].
  HistoryManifest adding(HistoryVersion version) =>
      HistoryManifest(versions: [...versions, version], pins: pins);

  /// This manifest with [pin] on [number] (null removes the pin).
  HistoryManifest pinning(String pin, int? number) {
    final next = {...pins}..remove(pin);
    if (number != null) next[pin] = number;
    return HistoryManifest(versions: versions, pins: next);
  }

  /// The versions rotation drops to keep at most [limit] unpinned ones:
  /// the oldest unpinned first.
  List<HistoryVersion> overflow(int limit) {
    final unpinned = [
      for (final v in versions)
        if (!isPinned(v.number)) v,
    ];
    final excess = unpinned.length - limit;
    if (excess <= 0) return const [];
    return unpinned.sublist(0, excess);
  }

  /// This manifest without the versions numbered in [numbers]; pins on
  /// them are dropped too.
  HistoryManifest removing(Set<int> numbers) => HistoryManifest(
    versions: [
      for (final v in versions)
        if (!numbers.contains(v.number)) v,
    ],
    pins: {
      for (final e in pins.entries)
        if (!numbers.contains(e.value)) e.key: e.value,
    },
  );

  /// The manifest file's text.
  String encode() => jsonEncode({
    'versions': [for (final v in versions) v.toJson()],
    'pins': pins,
  });
}
