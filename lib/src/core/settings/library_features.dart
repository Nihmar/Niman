/// The features a library can switch off (#1109).
///
/// This enum is the only place a feature is named: the stored ids, the
/// dependencies between rows, and — in the screen's phase — the strings
/// hang off it. Sync is not here on purpose: it is already per library and
/// per device, and a switch in `settings.json` would travel with the very
/// sync it stops.
library;

/// One switch of the Features screen, by the id it is stored under.
enum LibraryFeature {
  /// Finding and writing: the search screen and its commands.
  search('search'),

  /// Finding and writing: the quick note.
  quickNote('quickNote'),

  /// Finding and writing: templates for new notes and journal entries.
  templates('templates'),

  /// Finding and writing: web capture.
  capture('capture'),

  /// Planning: `todo.txt` and its reminders.
  todo('todo'),

  /// Planning: the journal.
  journal('journal'),

  /// Planning: `calendar.txt` and its reminders.
  calendar('calendar'),

  /// Note kinds: list notes.
  kindList('kinds.list'),

  /// Note kinds: shopping lists, the other view of a list note.
  kindShopping('kinds.shopping', parent: kindList),

  /// Note kinds: audio notes.
  kindAudio('kinds.audio'),

  /// Note kinds: transcription of an audio note.
  transcription('transcription', parent: kindAudio),

  /// Note kinds: slides.
  kindSlides('kinds.slides'),

  /// Note kinds: flashcards and Study.
  kindFlashcards('kinds.flashcards'),

  /// Note kinds: Kanban boards.
  kindKanban('kinds.kanban'),

  /// Reading: the PDF and EPUB readers.
  readers('readers'),

  /// Reading: annotating and highlighting in a reader.
  annotations('annotations', parent: readers),

  /// Reading: text recognition. It does not need the readers: images are
  /// recognised without them.
  ocr('ocr'),

  /// Around the app: Home.
  home('home'),

  /// Around the app: the Android home-screen widgets.
  widgets('widgets');

  new(this.id, {this.parent});

  /// The id the feature is stored under in `settings.json`. Stable: a
  /// renamed enum value keeps it.
  final String id;

  /// The feature this one needs, or null. A child whose parent is off is
  /// off too, but keeps its own value: turning the parent back on brings
  /// the child back as it was.
  final LibraryFeature? parent;

  /// The feature stored under [id], or null for one this build does not
  /// know (a later build's, which `Features` keeps on a round trip).
  static LibraryFeature? fromId(String id) => _byId[id];

  static final Map<String, LibraryFeature> _byId = {
    for (final feature in LibraryFeature.values) feature.id: feature,
  };
}
