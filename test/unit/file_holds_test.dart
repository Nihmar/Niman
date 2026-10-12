// The order an operation on a file a view holds open keeps (#833): the
// views let go of it first, waited for, the operation runs, and the views
// take it back after — whether it succeeded or failed.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/file_holds.dart';
import 'package:path/path.dart' as p;

void main() {
  final root = p.join(p.current, 'library');
  final pdf = p.join(root, 'Attachments', 'paper.pdf');

  test('the operation waits for the release, and is followed by the '
      'resume', () async {
    final holds = FileHolds();
    final events = <String>[];
    final closing = Completer<void>();
    holds.hold(
      pdf,
      release: () {
        events.add('release');
        return closing.future;
      },
      resume: () => events.add('resume'),
    );

    final done = holds.around([pdf], () async => events.add('operation'));
    await pumpEventQueue();
    // Not closed yet: the operation has not run.
    expect(events, ['release']);
    closing.complete();
    await done;
    expect(events, ['release', 'operation', 'resume']);
  });

  test('a failed operation hands the file back too', () async {
    final holds = FileHolds();
    final events = <String>[];
    holds.hold(
      pdf,
      release: () async => events.add('release'),
      resume: () => events.add('resume'),
    );

    await expectLater(
      holds.around<void>([pdf], () async => throw StateError('refused')),
      throwsStateError,
    );
    expect(events, ['release', 'resume']);
  });

  test('a folder covers the files under it, and nothing else', () async {
    final holds = FileHolds();
    final released = <String>[];
    for (final path in [pdf, p.join(root, 'Other', 'b.pdf')]) {
      holds.hold(path, release: () async => released.add(path));
    }

    await holds.around([p.join(root, 'Attachments')], () async {});
    expect(released, [pdf]);
  });

  test('a path written with either separator is the same file', () async {
    final holds = FileHolds();
    var released = 0;
    holds.hold(pdf, release: () async => released++);

    // What `p.join(root, 'Attachments/paper.pdf')` gives on Windows.
    await holds.around([p.join(root, 'Attachments/paper.pdf')], () async {});
    expect(released, 1);
  });

  test('two operations at once release once and resume once', () async {
    final holds = FileHolds();
    final events = <String>[];
    holds.hold(
      pdf,
      release: () async => events.add('release'),
      resume: () => events.add('resume'),
    );
    final inner = Completer<void>();

    final folder = holds.around([p.dirname(pdf)], () => inner.future);
    await pumpEventQueue();
    final file = holds.around([pdf], () async => events.add('file'));
    await file;
    // The folder's operation still has the file let go of.
    expect(events, ['release', 'file']);
    inner.complete();
    await folder;
    expect(events, ['release', 'file', 'resume']);
  });

  test('a hold dropped meanwhile is not resumed', () async {
    final holds = FileHolds();
    var resumed = false;
    final hold = holds.hold(
      pdf,
      release: () async {},
      resume: () => resumed = true,
    );

    await holds.around([pdf], () async => hold.drop());
    expect(resumed, isFalse);
    expect(holds.holding(pdf), isEmpty);
  });
}
