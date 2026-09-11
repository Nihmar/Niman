/// The template folder (design.md: templates/repo.dart).
///
/// A template is a note like any other; what makes it a template is where
/// it lives. The folder is a library setting (`Templates` by default), so
/// a library that keeps its templates somewhere else — or calls them
/// something else — says so once and everything follows.
///
/// Templates are listed from the index, not from a disk walk: they are
/// already indexed, and the list is opened from a dialog that must not
/// wait on the filesystem.
library;

import 'package:niman/src/db/dao.dart';
import 'package:niman/src/library/session.dart';

/// One template: the note behind it and the name it is offered under.
final class TemplateEntry {
  /// Creates a template entry.
  const new({required this.path, required this.name});

  /// The template note's library-relative path.
  final String path;

  /// What to call it in the picker: its path below the template folder,
  /// without the `.md` — so a template in a subfolder reads
  /// `Work/Meeting` and is told apart from `Personal/Meeting`.
  final String name;
}

/// The template data source the UI talks to.
///
/// [TemplateRepo] is the production implementation over the index; widget
/// tests inject a fake.
abstract interface class TemplateSource {
  /// The configured template folder (library-relative).
  Future<String> get folder;

  /// Every template in it, by name.
  Future<List<TemplateEntry>> templates();
}

/// Lists the templates of the open library.
final class TemplateRepo implements TemplateSource {
  /// Creates the repo over the index and the library's settings.
  const new(this._dao, this._ops);

  final NoteDao _dao;

  final NoteOperations _ops;

  /// The configured template folder.
  @override
  Future<String> get folder => _ops.templateFolder;

  /// Every `.md` note under the template folder, subfolders included, by
  /// name.
  ///
  /// An absent folder is not an error: a library simply has no templates
  /// until it has one, and the picker says so.
  @override
  Future<List<TemplateEntry>> templates() async {
    final root = await folder;
    final rows = await _dao.subtreeRows(root);
    final entries = <TemplateEntry>[
      for (final row in rows)
        if (!row.isDir && _isNote(row.name))
          TemplateEntry(path: row.path, name: _nameUnder(root, row.path)),
    ];
    return entries
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static bool _isNote(String name) => name.toLowerCase().endsWith('.md');

  /// The template's path below [root], without the `.md`.
  static String _nameUnder(String root, String path) {
    var name = path;
    if (root.isNotEmpty && name.startsWith('$root/')) {
      name = name.substring(root.length + 1);
    }
    return name.toLowerCase().endsWith('.md')
        ? name.substring(0, name.length - 3)
        : name;
  }
}
