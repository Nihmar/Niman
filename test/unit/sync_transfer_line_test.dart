import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/sync/sync_report.dart';
import 'package:niman/src/sync/sync_transfer_line.dart';

void main() {
  test('sizes are said in the unit a person reads', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(1023), '1023 B');
    expect(formatBytes(1536), '1.5 KiB');
    expect(formatBytes(1024 * 1024), '1.00 MiB');
    expect(formatBytes(5 * 1024 * 1024 + 512 * 1024), '5.50 MiB');
    expect(formatBytes(3 * 1024 * 1024 * 1024), '3.00 GiB');
  });

  test('a rate needs bytes and time', () {
    expect(formatRate(5 * 1024 * 1024, 1000), '5.00 MiB/s');
    expect(formatRate(1024 * 1024, 500), '2.00 MiB/s');
    expect(formatRate(0, 1000), isNull);
    expect(formatRate(1024, 0), isNull);
  });

  test('the line rates the phases that moved bytes', () {
    final report = SyncReport()
      ..bytesUp = 1024 * 1024
      ..bytesDown = 3 * 1024 * 1024
      ..bytesHashed = 2 * 1024 * 1024
      ..scanMs = 120
      ..hashMs = 1000
      ..applyMs = 2000;

    final line = transferLine(report);

    expect(
      line,
      'up 1.00 MiB, down 3.00 MiB, hashed 2.00 MiB; scan 120 ms, '
      'hash 1000 ms (2.00 MiB at 2.00 MiB/s), '
      'apply 2000 ms (4.00 MiB at 2.00 MiB/s)',
    );
    expect(line, isNot(contains('\n')));
  });

  test('a phase that moved nothing carries no rate', () {
    final report = SyncReport()
      ..scanMs = 5
      ..hashMs = 7
      ..applyMs = 9;

    expect(
      transferLine(report),
      'up 0 B, down 0 B, hashed 0 B; scan 5 ms, hash 7 ms, apply 9 ms',
    );
  });
}
