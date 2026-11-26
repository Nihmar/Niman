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

  test('a book the app started with is not a file to open (#1318)', () {
    final requests = LaunchRequests(file: '/a/Dune.EPUB');
    expect(requests.consumeFile(), isNull);
    expect(requests.consumeBook(), '/a/Dune.EPUB');
    expect(requests.consumeBook(), isNull);
  });

  test('a later launch’s book goes to the conversion, its note to the '
      'files (#1318)', () async {
    final later = Stream.fromIterable(const [
      LaunchArgs(openPath: '/b/Dune.epub'),
      LaunchArgs(openPath: '/b/notes.md'),
    ]);
    final requests = LaunchRequests(later: later);
    final files = <String>[];
    final books = <String>[];
    requests.files.listen(files.add);
    requests.books.listen(books.add);
    await pumpEventQueue();
    expect(books, ['/b/Dune.epub']);
    expect(files, ['/b/notes.md']);
    await requests.dispose();
  });
}
