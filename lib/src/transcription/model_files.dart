import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:path/path.dart' as p;

/// What [ModelFiles.scan] found: finished models and interrupted
/// downloads, sizes in bytes by model id.
typedef ModelScan = ({Map<String, int> installed, Map<String, int> partial});

/// The model files on disk: which models are downloaded or half
/// downloaded, and removing them.
///
/// Disk is the source of truth: a model is installed when its
/// `ggml-<name>.bin` exists. Downloads write to `.part` and rename only
/// once complete, so a finished name never belongs to a partial file, and
/// a `.part` left by a download that was cut off is where the next one
/// resumes.
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

  /// The finished and partial model files.
  Future<ModelScan> scan() async {
    final clock = Stopwatch()..start();
    final dir = await directory();
    final names = {for (final m in transcriptionModels) m.id: m.fileName};
    final scan = await Isolate.run(() => _scan(dir, names));
    String list(Map<String, int> sizes) => sizes.isEmpty
        ? 'none'
        : [for (final e in sizes.entries) '${e.key} ${e.value} b'].join(', ');
    _log.info(
      'models scanned in ${clock.elapsedMilliseconds} ms: '
      'installed ${list(scan.installed)}; partial ${list(scan.partial)}',
    );
    return scan;
  }

  /// Deletes [model]'s file and any partial download of it; returns the
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

  /// Deletes the partial download of the model at [target], off the UI
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

const _log = AppLogger(name: 'transcription');

ModelScan _scan(String dir, Map<String, String> names) {
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
    final part = File('${file.path}${ModelFiles.partSuffix}');
    if (part.existsSync()) partial[id] = part.lengthSync();
  }
  return (installed: installed, partial: partial);
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
