import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/dictionary/dictionary_index.dart';
import 'package:niman/src/dictionary/installed_pack.dart';
import 'package:niman/src/dictionary/installed_packs.dart';
import 'package:niman/src/dictionary/tar_unpacker.dart';
import 'package:path/path.dart' as p;

/// A pack in the dictionaries folder, with what it takes on disk and
/// whether its sidecar index is there (a pack without one has still to be
/// indexed, or its index would not build).
typedef InstalledDictionary = ({InstalledPack pack, int bytes, bool indexed});

/// The dictionaries folder's file work, all of it on an isolate of its
/// own: reading what is installed, unpacking a download into place, and
/// removing a pack.
///
/// A pack is only ever made or unmade by one rename, so a half-unpacked or
/// half-deleted pack is never a folder named like a pack: it is a hidden
/// sibling (`.niman-it.unpacking`, `.niman-it.removing`) that [scan] sweeps
/// up the next time the app starts.
final class DictionaryDisk {
  const new _();

  /// The files a pack archive may hold, after the pack's id.
  static const Set<String> memberExtensions = {
    'ifo',
    'idx',
    'syn',
    'dict.dz',
    'dict',
  };

  /// The folder [id]'s archive is unpacked into before it is renamed.
  static String unpackingFolder(String root, String id) =>
      p.join(root, '.$id.unpacking');

  /// The folder [id] is renamed to before it is deleted.
  static String removingFolder(String root, String id) =>
      p.join(root, '.$id.removing');

  /// The packs in [root] with their sizes; with [sweep] also deletes the
  /// hidden folders an interrupted install or removal left behind.
  static Future<List<InstalledDictionary>> scan(
    String root, {
    bool sweep = false,
  }) => Isolate.run(() => _scan(root, sweep));

  /// Unpacks `<root>/<id>.tar` into `<root>/<id>/` and deletes the
  /// archive, returning null; or returns why it could not, leaving the
  /// archive and no pack folder.
  ///
  /// The archive is unpacked into a hidden sibling, checked for the files a
  /// pack needs and only then renamed, so what the rename publishes is
  /// whole. A pack folder already there is replaced.
  static Future<String?> install(String root, String id) =>
      Isolate.run(() => _install(root, id));

  /// Removes the pack folder `<root>/<id>`, and any archive of it, returning
  /// null; or returns why it could not.
  ///
  /// The folder is renamed first: Windows refuses that while a file in it
  /// is open, and then nothing has changed and the pack is still a whole
  /// pack. Once renamed it is no longer one, whatever the delete that
  /// follows does.
  static Future<String?> remove(String root, String id) =>
      Isolate.run(() => _remove(root, id));
}

Future<List<InstalledDictionary>> _scan(String root, bool sweep) async {
  if (sweep) _sweep(root);
  final packs = await InstalledPacks.scan(root);
  return [
    for (final pack in packs)
      (
        pack: pack,
        bytes: _bytesIn(pack.directory),
        indexed: File(DictionaryIndex.pathOf(pack.directory, pack.id))
            .existsSync(),
      ),
  ];
}

void _sweep(String root) {
  final folder = Directory(root);
  if (!folder.existsSync()) return;
  for (final entity in folder.listSync()) {
    final name = p.basename(entity.path);
    final hidden =
        name.startsWith('.niman-') &&
        (name.endsWith('.unpacking') || name.endsWith('.removing'));
    if (entity is! Directory || !hidden) continue;
    try {
      entity.deleteSync(recursive: true);
    } on FileSystemException {
      // Locked by something: the next start tries again.
    }
  }
}

int _bytesIn(String directory) {
  var total = 0;
  try {
    for (final entity in Directory(directory).listSync(recursive: true)) {
      if (entity is File) total += entity.lengthSync();
    }
  } on FileSystemException {
    // A file removed while counting: what was counted is the answer.
  }
  return total;
}

String? _install(String root, String id) {
  final archive = File(p.join(root, '$id.tar'));
  final staging = Directory(DictionaryDisk.unpackingFolder(root, id));
  try {
    if (staging.existsSync()) staging.deleteSync(recursive: true);
    final names = TarUnpacker.unpackSync(
      archive,
      staging,
      accepts: (name) => _isMemberOf(id, name),
    );
    final missing = _missing(id, names);
    if (missing != null) throw FormatException('the archive has no $missing');
    final target = Directory(p.join(root, id));
    if (target.existsSync()) target.deleteSync(recursive: true);
    staging.renameSync(target.path);
  } on Object catch (error) {
    try {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
    } on FileSystemException {
      // Swept at the next start.
    }
    return error is FormatException ? error.message : '$error';
  }
  try {
    archive.deleteSync();
  } on FileSystemException {
    // The pack is in place; a stray archive is only space.
  }
  return null;
}

bool _isMemberOf(String id, String name) =>
    name.startsWith('$id.') &&
    DictionaryDisk.memberExtensions.contains(name.substring(id.length + 1));

/// The first file a pack cannot do without that [names] lacks, or null.
String? _missing(String id, List<String> names) {
  for (final extension in const ['ifo', 'idx']) {
    if (!names.contains('$id.$extension')) return '$id.$extension';
  }
  if (!names.contains('$id.dict.dz') && !names.contains('$id.dict')) {
    return '$id.dict.dz';
  }
  return null;
}

String? _remove(String root, String id) {
  final pack = Directory(p.join(root, id));
  final doomed = Directory(DictionaryDisk.removingFolder(root, id));
  try {
    if (doomed.existsSync()) doomed.deleteSync(recursive: true);
    if (pack.existsSync()) pack.renameSync(doomed.path);
    final archive = File(p.join(root, '$id.tar'));
    if (archive.existsSync()) archive.deleteSync();
  } on FileSystemException catch (error) {
    final reason = error.osError?.message.trim() ?? '';
    return reason.isEmpty ? error.message : reason;
  }
  // Renamed, the pack is gone: a file in it that will not delete now (a
  // scanner has it open) leaves a hidden folder the next start sweeps.
  try {
    if (doomed.existsSync()) doomed.deleteSync(recursive: true);
  } on FileSystemException {
    // Swept at the next start.
  }
  return null;
}
