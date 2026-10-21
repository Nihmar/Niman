/// The names inside the library's `.history/` folder that are not a note's:
/// all dot names, so no note's folder can take one. Walkers of `.history/`
/// skip the folders; the files are the store's own.
library;

/// The history folder's name inside the library root.
const String historyFolderName = '.history';

/// The objects folder's name inside `.history/`.
const String historyObjectsFolderName = '.objects';

/// The locks folder's name inside `.history/` (`history_lock.dart`).
const String historyLocksFolderName = '.locks';

/// The file in `.history/` that holds the store's generation: a token
/// every move of a log changes (`history_generation.dart`).
const String historyGenerationFileName = '.generation';

/// The file in `.history/` that says no history kept the old way is left
/// to move in (`history_legacy.dart`): delete it to have the upkeep look
/// again.
const String historyLegacyDoneFileName = '.legacy-done';
