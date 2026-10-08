// #224: the drop is taken by the platform runner — GDK in `linux/runner`,
// an OLE drop target in `windows/runner` — so the runner half is where the fix
// lives, and nothing on this machine runs it: the Dart side is tested
// through the channel seam (`drop_in_test.dart`, `drop_channel_test.dart`),
// and what the runners say is pinned here instead.
//
// What is pinned is what the two halves have to agree on: the channel both
// talk over, GDK's URI target on Linux, OLE's dropped files on Windows,
// and the portal file-transfer target that KDE offers beside the URIs and
// that must not be asked for — asking for it is what left a drop on
// KDE/Wayland with nothing to open (#224). A link dragged from a browser
// is a page to capture (#531): both runners hand it over as `dropLinks`,
// and say as the drag comes in whether it is one.
//
// Run from the package root, like `flutter test` does.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The runner source at [parts] of the repo root, as one string.
String runnerSource(List<String> parts) =>
    File(p.joinAll(parts)).readAsStringSync();

/// What [source] does, with its comments taken out: what a runner says
/// about the drop is not what it does with it.
String codeOnly(String source) => source
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
    .replaceAll(RegExp(r'//[^\n]*'), '');

/// The channel name the Dart side listens on, or an empty string when the
/// source that names it is not there.
String dartChannelName() {
  final file = File(p.join('lib', 'src', 'core', 'drop_in.dart'));
  expect(
    file.existsSync(),
    isTrue,
    reason: 'the Dart end of the drop channel lives here',
  );
  if (!file.existsSync()) return '';
  final match = RegExp(r"MethodChannel\('([^']+)'\)")
      .firstMatch(file.readAsStringSync());
  expect(match, isNotNull, reason: 'the channel is created by name');
  return match?.group(1) ?? '';
}

void main() {
  group('the Linux runner', () {
    late String source;

    setUpAll(() {
      source = codeOnly(runnerSource(['linux', 'runner', 'my_application.cc']));
    });

    test('makes the window its own drop destination', () {
      expect(
        source,
        contains('gtk_drag_dest_set'),
        reason: 'GDK has to be told the window takes drops at all',
      );
      expect(
        source,
        contains('gtk_drag_dest_add_uri_targets'),
        reason: 'a file manager offers what it drags as a list of URIs',
      );
      expect(
        source,
        contains('gtk_selection_data_get_uris'),
        reason: 'the paths come out of that list, not out of a key',
      );
      expect(
        source,
        isNot(contains('application/vnd.portal.filetransfer')),
        reason:
            'the portal target carries a one-time key instead of paths, '
            'and taking it is what made a drop do nothing (#224)',
      );
    });

    test('finishes the drop once', () {
      expect(
        source,
        isNot(contains('gtk_drag_finish')),
        reason:
            'GTK_DEST_DEFAULT_ALL finishes the drop itself once the data has '
            'been taken; a second finish answers the source twice',
      );
    });

    test('reports over the channel Dart listens on', () {
      expect(source, contains('"${dartChannelName()}"'));
    });

    test("hands a browser's link over as a page to capture (#531)", () {
      expect(source, contains('"dropLinks"'));
      expect(source, contains('g_uri_parse_scheme'));
      expect(
        source,
        contains('"_NETSCAPE_URL"'),
        reason: 'a link drag is told from a file drag as it comes in',
      );
    });
  });

  group('the Windows runner', () {
    late String source;

    setUpAll(() {
      source = codeOnly(
        runnerSource(['windows', 'runner', 'flutter_window.cpp']),
      );
    });

    test('registers an OLE drop target for the window, and revokes it', () {
      expect(
        source,
        contains('RegisterDragDrop(GetHandle(), drop_target_)'),
        reason: 'WM_DROPFILES only ever saw files; a link needs OLE (#531)',
      );
      expect(source, contains('RevokeDragDrop(GetHandle())'));
      expect(
        source,
        isNot(contains('DragAcceptFiles')),
        reason: 'OLE takes the drop: the old route would never be called',
      );
      expect(
        codeOnly(runnerSource(['windows', 'runner', 'main.cpp'])),
        contains('OleInitialize(nullptr)'),
        reason: 'RegisterDragDrop fails on a thread OLE was not set up on',
      );
    });

    test('reads the paths of files, and the address of a link', () {
      final target = codeOnly(
        runnerSource(['windows', 'runner', 'drop_target.cpp']),
      );
      expect(
        target,
        contains('DragQueryFileW'),
        reason: 'the drop arrives as an HDROP the paths are read from',
      );
      expect(target, contains('UniformResourceLocatorW'));
      expect(target, contains('"dropLinks"'));
      expect(target, contains('"dragEntered"'));
      expect(target, contains('"dragExited"'));
      expect(
        target,
        contains('ReleaseStgMedium'),
        reason: "the medium OLE hands over is the target's to free",
      );
      expect(
        codeOnly(runnerSource(['windows', 'runner', 'CMakeLists.txt'])),
        contains('"drop_target.cpp"'),
      );
    });

    test('reports over the channel Dart listens on', () {
      expect(source, contains('"${dartChannelName()}"'));
    });
  });
}
