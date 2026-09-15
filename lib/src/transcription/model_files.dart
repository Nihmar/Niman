import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:path/path.dart' as p;

/// The model files on disk: which models are downloaded and how big they
/// are, and removing one.
///
/// Disk is the source of truth: a model is installed when its
/// `ggml-<name>.bin` exists. Downloads write to `.part` and rename only
/// once complete, so a finished name never belongs to a partial file.
final class ModelFiles {
  /// Model files in the directory [directory] resolves to.
  new(this.directory);

  /// Resolves the model directory.
  final Future<String> Function() directory;

  /// The suffix a download writes to until it completes.
  static const String partSuffix = '.part';

  /// The absolute path of [model]'s file.
  Future<String> pathOf(TranscriptionModel model) async =>
      p.join(await directory(), model.fileName);

  /// The size in bytes of every downloaded model, by model id.
  ///
  /// Also removes `.part` files no download is writing: a download killed
  /// with the app leaves one behind, and it can be hundreds of megabytes.
  /// [active] lists the ids whose download is running right now.
  Future<Map<String, int>> installed({Set<String> active = const {}}) async {
    final clock = Stopwatch()..start();
    final dir = await directory();
    final names = {for (final m in transcriptionModels) m.id: m.fileName};
    final scan = await Isolate.run(() => _scan(dir, names, active));
    final found = scan.sizes.isEmpty
        ? 'none'
        : [for (final e in scan.sizes.entries) '${e.key} ${e.value} b']
              .join(', ');
    final removed = scan.removedParts == 0
        ? ''
        : ', removed ${scan.removedParts} stale .part';
    _log.info(
      'models scanned in ${clock.elapsedMilliseconds} ms: $found$removed',
    );
    return scan.sizes;
  }

  /// Deletes [model]'s file (and any partial download of it); returns the
  /// bytes freed.
  Future<int> delete(TranscriptionModel model) async {
    final clock = Stopwatch()..start();
    final path = await pathOf(model);
    final freed = await Isolate.run(() => _delete(path));
    _log.info(
      'model ${model.id} deleted in ${clock.elapsedMilliseconds} ms, '
      'freed $freed b',
    );
    return freed;
  }
}

const _log = AppLogger(name: 'transcription');

typedef _Scan = ({Map<String, int> sizes, int removedParts});

_Scan _scan(String dir, Map<String, String> names, Set<String> active) {
  final sizes = <String, int>{};
  var removed = 0;
  if (!Directory(dir).existsSync()) return (sizes: sizes, removedParts: 0);
  for (final MapEntry(key: id, value: name) in names.entries) {
    final file = File(p.join(dir, name));
    if (file.existsSync()) sizes[id] = file.lengthSync();
    final part = File('${file.path}${ModelFiles.partSuffix}');
    if (!active.contains(id) && part.existsSync()) {
      try {
        part.deleteSync();
        removed++;
      } on FileSystemException {
        // Locked or already gone: the next scan tries again.
      }
    }
  }
  return (sizes: sizes, removedParts: removed);
}

int _delete(String path) {
  var freed = 0;
  for (final file in [File(path), File('$path${ModelFiles.partSuffix}')]) {
    if (!file.existsSync()) continue;
    freed += file.lengthSync();
    file.deleteSync();
  }
  return freed;
}
