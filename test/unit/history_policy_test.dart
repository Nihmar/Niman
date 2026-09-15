import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/snapshot_policy.dart';

void main() {
  final t0 = DateTime(2026, 9, 15, 10);

  HistoryVersion version(int n, DateTime at, {String sha = 'old'}) =>
      HistoryVersion(
        number: n,
        savedAt: at,
        reason: HistoryReason.session,
        size: 3,
        sha256: sha,
      );

  SnapshotRequest request({
    DateTime? now,
    bool sessionStart = false,
    HistoryReason? forced,
    int limit = 10,
  }) => SnapshotRequest(
    limit: limit,
    interval: const Duration(minutes: 5),
    now: now ?? t0,
    sessionStart: sessionStart,
    forced: forced,
  );

  SnapshotDecision decide(
    HistoryManifest manifest,
    SnapshotRequest request, {
    String? oldSha = 'current',
  }) => decideSnapshot(manifest: manifest, oldSha: oldSha, request: request);

  test('a new note has nothing to keep', () {
    final d = decide(
      HistoryManifest(),
      request(sessionStart: true),
      oldSha: null,
    );
    expect(d.take, isFalse);
  });

  test('history off keeps nothing, even a restore', () {
    final d = decide(
      HistoryManifest(),
      request(limit: 0, forced: HistoryReason.restore),
    );
    expect(d.take, isFalse);
  });

  test('text identical to the newest version is not kept twice', () {
    final m = HistoryManifest(versions: [version(4, t0, sha: 'current')]);
    final d = decide(m, request(sessionStart: true));
    expect(d.take, isFalse);
    expect(d.why, contains('v4'));
  });

  test('the first save of a session keeps the text', () {
    final m = HistoryManifest(versions: [version(1, t0)]);
    final d = decide(
      m,
      request(now: t0.add(const Duration(seconds: 10)), sessionStart: true),
    );
    expect(d.reason, HistoryReason.session);
  });

  test('inside the interval nothing is kept', () {
    final m = HistoryManifest(versions: [version(1, t0)]);
    final d = decide(m, request(now: t0.add(const Duration(minutes: 4))));
    expect(d.take, isFalse);
  });

  test('past the interval the text is kept', () {
    final m = HistoryManifest(versions: [version(1, t0)]);
    final d = decide(m, request(now: t0.add(const Duration(minutes: 5))));
    expect(d.reason, HistoryReason.interval);
  });

  test('a forced reason ignores the interval', () {
    final m = HistoryManifest(versions: [version(1, t0)]);
    final d = decide(
      m,
      request(
        now: t0.add(const Duration(seconds: 1)),
        forced: HistoryReason.restore,
      ),
    );
    expect(d.reason, HistoryReason.restore);
  });

  test('a note with no version yet gets its first one', () {
    final d = decide(HistoryManifest(), request());
    expect(d.reason, HistoryReason.interval);
  });

  group('manifest', () {
    test('rotation drops the oldest unpinned versions', () {
      final m = HistoryManifest(
        versions: [for (var n = 1; n <= 5; n++) version(n, t0)],
        pins: const {syncBasePin: 1},
      );
      expect(m.overflow(2).map((v) => v.number), [2, 3]);
    });

    test('numbers are never reused, pinned ones included', () {
      final m = HistoryManifest(
        versions: [version(3, t0)],
        pins: const {syncBasePin: 7},
      );
      expect(m.nextNumber, 8);
    });

    test('moving a pin releases the old one', () {
      final m = HistoryManifest(
        versions: [version(1, t0), version(2, t0)],
        pins: const {syncBasePin: 1},
      ).pinning(syncBasePin, 2);
      expect(m.pins, {syncBasePin: 2});
      expect(m.pinning(syncBasePin, null).pins, isEmpty);
    });

    test('encodes and decodes round trip', () {
      final m = HistoryManifest(
        versions: [version(2, t0), version(1, t0)],
        pins: const {syncBasePin: 2},
      );
      final back = HistoryManifest.decode(m.encode());
      expect(back.versions.map((v) => v.number), [1, 2]);
      expect(back.versions.first, m.versions.first);
      expect(back.pins, {syncBasePin: 2});
    });

    test('a damaged file reads what it can', () {
      expect(HistoryManifest.decode('not json').versions, isEmpty);
      final partial = HistoryManifest.decode(
        '{"versions": [{"v": 1, "savedAt": 5, "size": 1, "sha256": "a", '
        '"reason": "interval"}, {"v": "bad"}, 7], "pins": {"x": "y"}}',
      );
      expect(partial.versions.single.reason, HistoryReason.interval);
      expect(partial.pins, isEmpty);
    });
  });
}
