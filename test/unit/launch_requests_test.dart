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
    final later = Stream.fromIterable(const [
      LaunchArgs(openPath: '/b.md'),
      LaunchArgs(action: ShortcutAction.quickNote),
      LaunchArgs(),
    ]);
    final requests = LaunchRequests(later: later);
    final files = <String>[];
    var arrivals = 0;
    requests.files.listen(files.add);
    requests.arrivals.listen((_) => arrivals++);
    await pumpEventQueue();
    expect(files, ['/b.md']);
    expect(arrivals, 3);
  });

  test('a drop asks through the same requests (#75)', () async {
    final requests = LaunchRequests();
    final files = <String>[];
    final folders = <String>[];
    requests.files.listen(files.add);
    requests.folders.listen(folders.add);
    requests
      ..openFile('/c.md')
      ..openFolder('/d');
    await pumpEventQueue();
    expect(files, ['/c.md']);
    expect(folders, ['/d']);
    await requests.dispose();
  });
}
