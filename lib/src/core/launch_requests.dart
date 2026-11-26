/// What reaches the running app from outside it (#41, #75): the file the
/// app started with, the later launches the first instance was handed,
/// and what is dropped on the window.
///
/// Files are opened by whoever is on screen to open them: the library's
/// shell, or, with no library, the screen that opens one. Folders the
/// same. The quick actions a later launch carries go the way the launch
/// flags always went, through the shortcut service. A book (`.epub`) a
/// launch carries is not a file to open: it is offered for conversion into
/// notes (#1318), as a dropped one is.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/launch_args.dart';
import 'package:path/path.dart' as p;

/// Whether [path] names a book, which a launch offers for conversion
/// rather than opens.
bool isLaunchedBook(String path) => p.extension(path).toLowerCase() == '.epub';

/// The requests that reach the app.
final class LaunchRequests {
  /// Requests for an app that started with `file` (null for none) and is
  /// handed [later] launches afterwards.
  new({String? file, Stream<LaunchArgs> later = const Stream.empty()})
    : _file = file != null && isLaunchedBook(file) ? null : file,
      _book = file != null && isLaunchedBook(file) ? file : null,
      _later = later.asBroadcastStream() {
    _laterFiles = _later.listen((launch) {
      if (launch.openPath case final path?) openFile(path);
    });
  }

  String? _file;
  String? _book;
  final Stream<LaunchArgs> _later;
  late final StreamSubscription<LaunchArgs> _laterFiles;
  final StreamController<String> _files = StreamController.broadcast();
  final StreamController<String> _books = StreamController.broadcast();
  final StreamController<String> _folders = StreamController.broadcast();
  final StreamController<Uri> _pages = StreamController.broadcast();

  /// The file the app was started with, once; then null.
  String? consumeFile() {
    final file = _file;
    _file = null;
    return file;
  }

  /// The book the app was started with, once; then null. Asked for apart
  /// from [consumeFile]: a book is converted, not opened (#1318).
  String? consumeBook() {
    final book = _book;
    _book = null;
    return book;
  }

  /// Files to open: the ones later launches asked for, and the ones
  /// dropped on the window.
  Stream<String> get files => _files.stream;

  /// Books to offer for conversion into notes: the ones later launches
  /// asked for (#1318). A dropped book comes as a [folders] entry.
  Stream<String> get books => _books.stream;

  /// Folders dropped on the window (#75).
  Stream<String> get folders => _folders.stream;

  /// Web pages dropped on the window as links, to capture (#531).
  Stream<Uri> get pages => _pages.stream;

  /// Every later launch: the window should come to the front for each,
  /// whatever it asked. A drop needs no such thing — the window is
  /// where it landed.
  Stream<void> get arrivals => _later.map((_) {});

  /// Asks for the file at [path] (absolute) to be opened: a book, to be
  /// offered for conversion instead (#1318).
  void openFile(String path) =>
      (isLaunchedBook(path) ? _books : _files).add(path);

  /// Asks for the folder at [path] (absolute) to be opened.
  void openFolder(String path) => _folders.add(path);

  /// Asks for the page at [url] to be captured.
  void capturePage(Uri url) => _pages.add(url);

  /// Who takes the dropped files nothing opens or imports — a PDF, a
  /// picture, an archive — to attach them to the note on screen (#1250):
  /// the library's shell, while it is up. It answers whether a note took
  /// them.
  Future<bool> Function(List<String> paths)? attachHandler;

  /// Asks for the files at [paths] to be attached to the note on screen:
  /// false when there is none to take them.
  Future<bool> attachFiles(List<String> paths) async =>
      await attachHandler?.call(paths) ?? false;

  /// Who takes the web pages (`.html`) dropped on the window, to ask what to
  /// do with them (#1293): the library's shell, while it is up. It answers
  /// whether it took them.
  Future<bool> Function(List<String> paths)? pageHandler;

  /// Offers the web pages at [paths] to be converted, attached or both:
  /// false when nobody is there to ask (no library open), and they are
  /// left to what a drop of any other file does.
  Future<bool> offerPages(List<String> paths) async =>
      await pageHandler?.call(paths) ?? false;

  /// Stops taking requests.
  Future<void> dispose() async {
    await _laterFiles.cancel();
    await _files.close();
    await _books.close();
    await _folders.close();
    await _pages.close();
  }
}

/// The app's launch requests; none unless `main` hands some in.
final launchRequestsProvider = Provider<LaunchRequests>((ref) {
  final requests = LaunchRequests();
  ref.onDispose(() => unawaited(requests.dispose()));
  return requests;
});
