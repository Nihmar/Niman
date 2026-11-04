import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/library/folder_spelling.dart';

/// The library's journal settings, read with the journal's folder spelled
/// as the library spells it (#1246), and kept as given.
final class LibraryJournal {
  /// Creates the journal settings kept in [config].
  new({required this.config, required this.dao});

  /// The library settings, holding the journal's.
  final LibraryConfigRepo config;

  /// The library's index, asked how the library spells a folder.
  final NoteDao dao;

  /// The journal settings, their folder spelled as the library spells it.
  Future<JournalSettings> get journal async {
    final settings = (await config.config).journal;
    try {
      return await settings.resolveFolder(_folderSpelling);
    } on Object catch (error) {
      // The spelling is a convenience, not the setting: an index that cannot
      // be asked leaves the settings as written rather than failing a read,
      // and the write path still canonicalizes on its own (#1246).
      const AppLogger(name: 'journal')
          .warning('folder spelling unresolved ($error)');
      return settings;
    }
  }

  /// [folder] as the library spells it, segment by segment (#1246): nothing
  /// is made, and a folder the library does not hold keeps its spelling.
  Future<String> _folderSpelling(String folder) => resolveFolderSpelling<Note>(
    folder,
    exact: (path) async {
      final row = await dao.find(path);
      return row != null && row.isDir ? row : null;
    },
    child: (parent, segment) async {
      final held = await dao.folderChild(parent, segment);
      return held == null ? null : (name: held.name, token: held);
    },
  );

  /// Keeps [settings] as the journal's.
  Future<void> setJournal(JournalSettings settings) =>
      config.update((c) => c.copyWith(journal: settings));
}
