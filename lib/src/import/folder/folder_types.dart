/// What a folder import is asked and what it answers (#1295), shared by the
/// job that writes it (`folder_job.dart`) and the main isolate's side that
/// runs it (`folder_import.dart`).
library;

import 'package:niman/src/core/settings/library_settings.dart' show LinkType;

/// The most web pictures a folder's pages download between them: the
/// capture's limit is one page's, and a site of a thousand pages is not
/// given a thousand pages' worth. A page still takes at most the capture's
/// own sixty; the pictures past the limits keep their web address.
const int folderImportMaxDownloads = 500;

/// What a folder import is asked to do.
typedef FolderImportRequest = ({
  /// The folder, absolute.
  String source,

  /// What the new folder is called when that name is free.
  String name,

  /// The library, absolute.
  String libraryRoot,

  /// The hidden folder everything is written in first, absolute.
  String staging,

  /// The library's attachments folder's name.
  String attachments,

  /// How the library embeds a picture.
  LinkType linkType,

  /// The folder's Markdown files, relative to it.
  List<String> markdown,

  /// The folder's web pages, relative to it.
  List<String> pages,

  /// The day written as `imported:`; null for today.
  DateTime? importedOn,
});

/// What an import wrote: the new folder (library-relative), how many notes
/// it holds — the Markdown copied and the pages converted — how many of those
/// were pages, how many pictures were kept, and how many files were left out
/// because they could not be read or converted.
typedef FolderImported = ({
  String folder,
  int notes,
  int pages,
  int pictures,
  int skipped,
});
