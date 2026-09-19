// Issue #41: the file the app started with is taken once; later launches
// each bring the window forward, and the files among them are opened.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/launch_args.dart';
import 'package:niman/src/core/launch_requests.dart';
import 'package:niman/src/core/shortcuts.dart';

void main() {
  test('the starting file is taken once', () {
    final requests = LaunchRequests(file: '/a.md');
    expect(requests.consumeFile(), '/a.md');
    expect(requests.consumeFile(), isNull);
  });

  test('every later launch arrives; only files are files', () async {
    final requests = LaunchRequests(
      later: Stream.fromIterable(const [
        LaunchArgs(openPath: '/b.md'),
        LaunchArgs(action: ShortcutAction.quickNote),
        LaunchArgs(),
      ]),
    );
    final files = requests.files.toList();
    final arrivals = requests.arrivals.length;
    expect(await files, ['/b.md']);
    expect(await arrivals, 3);
  });
}
