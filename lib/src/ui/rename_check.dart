/// Why a new name cannot be used, asked before a rename in place runs
/// (#707): the dialog's rename quietly cleans a name and numbers a taken
/// one, while a field left open can say what is wrong and let it be fixed.
library;

import 'package:niman/src/core/files.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/strings.dart';

/// Why [name] cannot be the new name of the row at [path], or null when
/// it can: a character the file system refuses, or another file of the
/// folder already called that.
///
/// [name] is read as the rename reads it: a file keeps its extension,
/// typed or not.
Future<String?> renameProblem(
  NoteOperations ops,
  String path,
  String name, {
  required bool isDir,
}) async {
  final ext = isDir
      ? ''
      : path.toLowerCase().endsWith('.md')
      ? '.md'
      : _extensionOf(path);
  var base = name.trim();
  if (ext.isNotEmpty && base.toLowerCase().endsWith(ext.toLowerCase())) {
    base = base.substring(0, base.length - ext.length);
  }
  if (sanitizeName(base, fallback: '') != base) {
    return AppStrings.renameNameInvalid;
  }
  final target = resolvePath(parentOf(path), '$base$ext');
  if (target.toLowerCase() == path.toLowerCase()) return null;
  if (await ops.find(target) != null) {
    return AppStrings.renameNameTaken('$base$ext');
  }
  return null;
}

/// The extension of [path]'s file name, with its dot; empty when none.
String _extensionOf(String path) {
  final name = path.split('/').last;
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(dot) : '';
}
