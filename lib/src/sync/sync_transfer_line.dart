import 'package:niman/src/sync/sync_report.dart';

/// What a run moved and where its time went, as the one fragment its log
/// line carries (#1107): sizes a person can read, and the rate of the two
/// phases that move bytes, so a slow run says whether the link or the work
/// is to blame.
///
/// The hash phase is rated by the files it downloaded to hash them, the
/// apply phase by what it uploaded and downloaded; a phase that moved
/// nothing, or took no measurable time, carries no rate.
String transferLine(SyncReport report) {
  final moved = report.bytesUp + report.bytesDown;
  return 'up ${formatBytes(report.bytesUp)}, '
      'down ${formatBytes(report.bytesDown)}, '
      'hashed ${formatBytes(report.bytesHashed)}; '
      'scan ${report.scanMs} ms, '
      'hash ${report.hashMs} ms${_rated(report.bytesHashed, report.hashMs)}, '
      'apply ${report.applyMs} ms${_rated(moved, report.applyMs)}';
}

/// [bytes] in binary units: bytes below a KiB, KiB with one decimal below a
/// MiB, MiB and GiB with two.
String formatBytes(int bytes) {
  const kib = 1024;
  const mib = 1024 * kib;
  const gib = 1024 * mib;
  if (bytes < kib) return '$bytes B';
  if (bytes < mib) return '${(bytes / kib).toStringAsFixed(1)} KiB';
  if (bytes < gib) return '${(bytes / mib).toStringAsFixed(2)} MiB';
  return '${(bytes / gib).toStringAsFixed(2)} GiB';
}

/// [bytes] over [ms] in MiB/s, or null when nothing moved or no time
/// passed to divide by.
String? formatRate(int bytes, int ms) {
  if (bytes <= 0 || ms <= 0) return null;
  final perSecond = bytes / (1024 * 1024) / (ms / 1000);
  return '${perSecond.toStringAsFixed(2)} MiB/s';
}

String _rated(int bytes, int ms) {
  final rate = formatRate(bytes, ms);
  return rate == null ? '' : ' (${formatBytes(bytes)} at $rate)';
}
