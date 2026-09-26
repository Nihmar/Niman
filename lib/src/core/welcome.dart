/// The first run (#266): the welcome deck, the Markdown question it asks,
/// and what a library's editors start as because of the answer.
///
/// The whole state is device-level and lives in `app_settings`: the deck
/// is once, the answer seeds a library the first time *this device* opens
/// it, and the tour's progress is about this machine. Nothing of it
/// travels in a library's `.niman/settings.json`, and nothing of it is
/// asked twice.
library;

import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';

/// How much Markdown the user brings to the app, as the welcome asks it.
///
/// The answer only decides what a library starts as — which editor opens
/// a note and which editors the library offers — never what it can do:
/// everything is one switch away in Settings → Editor.
enum MarkdownExperience {
  /// Never written it: the live editor alone, the source editor not
  /// offered until it is turned on.
  none('none'),

  /// Seen it, or writes a little: the live editor opens notes, both
  /// editors are offered.
  some('some'),

  /// Writes it all the time: the source editor, as the app has always
  /// opened.
  fluent('fluent');

  new(this.id);

  /// The text stored in `app_settings` (and in the settings file's device
  /// keys, when the answer seeds them).
  final String id;

  /// The answer with this [id], or null (never asked, or a row written by
  /// an older build).
  static MarkdownExperience? fromId(String? id) {
    for (final experience in MarkdownExperience.values) {
      if (experience.id == id) return experience;
    }
    return null;
  }
}

/// The editors a library starts with, given the welcome's [experience].
///
/// Null — the question was skipped, or the install upgraded from before
/// it existed — is today's default: the source editor, both offered.
({EditorKind kind, Set<EditorKind> enabled}) editorDefaultsFor(
  MarkdownExperience? experience,
) {
  return switch (experience) {
    MarkdownExperience.none => (
      kind: EditorKind.wysiwyg,
      enabled: const {EditorKind.wysiwyg},
    ),
    MarkdownExperience.some => (
      kind: EditorKind.wysiwyg,
      enabled: const {EditorKind.source, EditorKind.wysiwyg},
    ),
    MarkdownExperience.fluent || null => (
      kind: EditorKind.source,
      enabled: const {EditorKind.source, EditorKind.wysiwyg},
    ),
  };
}

/// Everything the first run keeps, in one read.
typedef WelcomeState = ({
  /// Whether the deck was finished or skipped.
  bool deckSeen,

  /// The Markdown answer, or null while it was never given.
  MarkdownExperience? experience,

  /// Whether the guided tour was finished or dismissed.
  bool tourSeen,

  /// Where the tour stopped, for *Take the tour*; 0 is its start.
  int tourStep,

  /// Whether the welcome asked for the tour once a library is open.
  bool tourOffer,
});

/// Where the first run's state lives.
///
/// Implemented by [DbWelcomeStore] (the app database) and
/// [MemoryWelcomeStore] (tests and tools), so the UI never talks to the
/// database and a widget test needs no store.
abstract interface class WelcomeStore {
  /// The state, read once.
  Future<WelcomeState> state();

  /// Marks the deck as seen (finished or skipped).
  Future<void> setDeckSeen({required bool seen});

  /// Keeps the Markdown answer (or clears it with null).
  Future<void> setExperience(MarkdownExperience? experience);

  /// Marks the guided tour as seen (finished or dismissed).
  Future<void> setTourSeen({required bool seen});

  /// Remembers where the tour stopped.
  Future<void> setTourStep(int step);

  /// Remembers the welcome's "show me around" choice.
  Future<void> setTourOffer({required bool offer});

  /// The device keys a library takes when this device opens it for the
  /// first time (#266), from the answer — or null when the question was
  /// never asked, in which case the library's own settings (or the
  /// defaults) rule.
  Future<Map<String, Object?>?> firstLibraryEditorKeys();
}

/// The app database's first-run state.
final class DbWelcomeStore implements WelcomeStore {
  /// Creates the store over the app settings [AppSettingsRepo].
  new(this._settings);

  final AppSettingsRepo _settings;

  @override
  Future<WelcomeState> state() async {
    final row = await _settings.firstRun();
    return (
      deckSeen: row.deckSeen,
      experience: MarkdownExperience.fromId(row.experience),
      tourSeen: row.tourSeen,
      tourStep: row.tourStep,
      tourOffer: row.tourOffer,
    );
  }

  @override
  Future<void> setDeckSeen({required bool seen}) =>
      _settings.setWelcomeSeen(seen: seen);

  @override
  Future<void> setExperience(MarkdownExperience? experience) =>
      _settings.setMarkdownExperience(experience?.id);

  @override
  Future<void> setTourSeen({required bool seen}) =>
      _settings.setTourSeen(seen: seen);

  @override
  Future<void> setTourStep(int step) => _settings.setTourStep(step);

  @override
  Future<void> setTourOffer({required bool offer}) =>
      _settings.setTourOffer(offer: offer);

  @override
  Future<Map<String, Object?>?> firstLibraryEditorKeys() async {
    final answer = (await state()).experience;
    if (answer == null) return null;
    final defaults = editorDefaultsFor(answer);
    return LibraryConfig.editorDeviceKeys(
      kind: defaults.kind,
      enabled: defaults.enabled,
    );
  }
}

/// The first-run state in memory: tests, and any tool that wants no
/// database.
final class MemoryWelcomeStore implements WelcomeStore {
  /// Whether the deck was seen; starts unseen, like a fresh install.
  bool deckSeen = false;

  /// The Markdown answer; null until asked.
  MarkdownExperience? experience;

  /// Whether the tour was seen.
  bool tourSeen = false;

  /// Where the tour stopped.
  int tourStep = 0;

  /// Whether the welcome asked for the tour.
  bool tourOffer = false;

  @override
  Future<WelcomeState> state() async => (
    deckSeen: deckSeen,
    experience: experience,
    tourSeen: tourSeen,
    tourStep: tourStep,
    tourOffer: tourOffer,
  );

  @override
  Future<void> setDeckSeen({required bool seen}) async => deckSeen = seen;

  @override
  Future<void> setExperience(MarkdownExperience? answer) async =>
      experience = answer;

  @override
  Future<void> setTourSeen({required bool seen}) async => tourSeen = seen;

  @override
  Future<void> setTourStep(int step) async => tourStep = step;

  @override
  Future<void> setTourOffer({required bool offer}) async => tourOffer = offer;

  @override
  Future<Map<String, Object?>?> firstLibraryEditorKeys() async {
    if (experience == null) return null;
    final defaults = editorDefaultsFor(experience);
    return LibraryConfig.editorDeviceKeys(
      kind: defaults.kind,
      enabled: defaults.enabled,
    );
  }
}
