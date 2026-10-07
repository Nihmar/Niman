import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/download/downloadable.dart';
import 'package:niman/src/core/logging.dart';
import 'package:path/path.dart' as p;

/// What [DownloadFiles.scan] found: finished files and interrupted
/// downloads, sizes in bytes by item id.
typedef DownloadScan = ({Map<String, int> installed, Map<String, int> partial});

/// The downloaded files on disk: which items of [catalog] are downloaded
/// or half downloaded, and removing them.
///
/// Disk is the source of truth: an item is installed when its file
/// exists. Downloads write to `.part` and rename only once complete, so a
/// finished name never belongs to a partial file, and a `.part` left by a
/// download that was cut off is where the next one resumes.
final class DownloadFiles {
  /// The files of [catalog] in the directory [directory] resolves to;
  /// [log] tags the lines.
  new(
    this.directory,
    this.catalog, {
    this.log = const AppLogger(name: 'download'),
  });

  /// Resolves the download directory.
  final Future<String> Function() directory;

  /// Every item that may be on disk.
  final Iterable<Downloadable> catalog;

  /// Where the lines go.
  final AppLogger log;

  /// The suffix a download writes to until it completes.
  static const String partSuffix = '.part';

  /// The absolute path of [item]'s file.
  Future<String> pathOf(Downloadable item) async =>
      p.join(await directory(), item.fileName);

  /// The finished and partial files.
  Future<DownloadScan> scan() async {
    final clock = Stopwatch()..start();
    final dir = await directory();
    final names = {for (final m in catalog) m.id: m.fileName};
    final scan = await Isolate.run(() => _scan(dir, names));
    String list(Map<String, int> sizes) => sizes.isEmpty
        ? 'none'
        : [for (final e in sizes.entries) '${e.key} ${e.value} b'].join(', ');
    log.info(
      'files scanned in ${clock.elapsedMilliseconds} ms: '
      'installed ${list(scan.installed)}; partial ${list(scan.partial)}',
    );
    return scan;
  }

  /// Deletes [item]'s file and any partial download of it; returns the
  /// bytes freed.
  Future<int> delete(Downloadable item) async {
    final clock = Stopwatch()..start();
    final path = await pathOf(item);
    final freed = await Isolate.run(() => _delete(path));
    log.info(
      '${item.id} deleted in ${clock.elapsedMilliseconds} ms, '
      'freed $freed b',
    );
    return freed;
  }

  /// Deletes the partial download of the file at [target], off the UI
  /// isolate.
  static Future<void> deletePart(String target) => Isolate.run(() {
    // A download isolate that was just killed may still hold the handle
    // on Windows; the next download or delete removes what this cannot.
    try {
      final file = File('$target$partSuffix');
      if (file.existsSync()) file.deleteSync();
    } on FileSystemException {
      // Left for later.
    }
  });
}

DownloadScan _scan(String dir, Map<String, String> names) {
  final installed = <String, int>{};
  final partial = <String, int>{};
  if (!Directory(dir).existsSync()) {
    return (installed: installed, partial: partial);
  }
  for (final MapEntry(key: id, value: name) in names.entries) {
    final file = File(p.join(dir, name));
    if (file.existsSync()) {
      installed[id] = file.lengthSync();
      continue;
    }
    final part = File('${file.path}${DownloadFiles.partSuffix}');
    if (part.existsSync()) partial[id] = part.lengthSync();
  }
  return (installed: installed, partial: partial);
}

int _delete(String path) {
  var freed = 0;
  for (final file in [File(path), File('$path${DownloadFiles.partSuffix}')]) {
    if (!file.existsSync()) continue;
    freed += file.lengthSync();
    file.deleteSync();
  }
  return freed;
}
