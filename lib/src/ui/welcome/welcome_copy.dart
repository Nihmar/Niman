/// The welcome deck's copy (#266).
///
/// Deliberately not part of `ui/strings/`: that contract is compile-time
/// complete — a locale that misses a label does not build — and the deck
/// and the tour are ~70 labels of onboarding prose, the first surface of
/// this size. Until the translation round decides how they are carried
/// (issue to be filed), they live here in English rather than shipping
/// thirty-seven locales of machine-translated onboarding.
///
/// Everything the deck says is a getter on [WelcomeCopy], so folding it
/// into `AppStrings` later is a mechanical swap at the call sites.
library;

/// The deck's words, in the language they were written in.
final class WelcomeCopy {
  /// Creates the copy.
  const new();

  // Controls.

  /// Leaves the deck.
  String get skip => 'Skip';

  /// The next page.
  String get next => 'Next';

  /// The page before.
  String get back => 'Back';

  /// Leaves the deck from its last page.
  String get start => 'Start writing';

  /// Closes the read-only deck (Settings → About).
  String get close => 'Close';

  /// Where the deck is, for the dots' semantics: `3 of 9`.
  String pageOf(int page, int of) => '$page of $of';

  // The pages.

  /// Page 1, title.
  String get notesTitle => 'Your notes are files';

  /// Page 1, body.
  String get notesBody =>
      'Niman keeps your notes as plain Markdown files in folders you '
      'choose. One note is one .md file, and everything the app shows you '
      'is built from them. No account, and no format of ours to get back '
      'in.';

  /// Page 2, title.
  String get modesTitle => 'Three ways to write the same note';

  /// Page 2, body.
  String get modesBody =>
      'Write the Markdown source, write the note as it reads (the live '
      'editor), or read it. It is one note whichever you use, and you can '
      'switch per note or for the whole library.';

  /// Page 3, title.
  String get linksTitle => 'Everything connects';

  /// Page 3, body.
  String get linksBody =>
      'Wikilinks like [[this one]] find their note as you type. Tags, '
      'frontmatter and templates keep the parts you write over and over '
      'out of the way.';

  /// Page 4, title.
  String get findTitle => 'Find it again';

  /// Page 4, body.
  String get findBody =>
      'Full-text search across the library, a command palette for '
      'everything the app can do, and the quick note a keystroke away.';

  /// Page 5, title.
  String get exportTitle => 'It goes with you';

  /// Page 5, body.
  String get exportBody =>
      'Export a note or a whole folder as Markdown, HTML, a PDF or an '
      'EPUB book. Bring in a Notion export, or open an Obsidian vault '
      'where it already is.';

  /// Page 6, title.
  String get tasksTitle => 'Tasks and reminders';

  /// Page 6, body.
  String get tasksBody =>
      'A todo.txt list you keep as a file — priorities, projects, due '
      'dates — and rem: alarms that warn you when something is due, on '
      'the phone and on the desktop.';

  /// Page 7, title.
  String get syncTitle => 'Across your machines';

  /// Page 7, body.
  String get syncBody =>
      'Point a library at a WebDAV folder — Nextcloud, ownCloud, a NAS — '
      'and edits sync both ways, merged line by line when two devices '
      'touched the same note.';

  /// The device page, title.
  String get deviceTitle => 'Niman on this device';

  /// The device page on Android.
  String get androidBody =>
      'Share text or a file into Niman from any app, keep a note on the '
      'home screen, and record a voice note instead of typing.';

  /// The device page on a desktop.
  String get desktopBody =>
      'Tabs and split panes, the system tray, drag and drop onto the '
      'window, and .md files that open Niman.';

  // The question.

  /// The question's title.
  String get questionTitle => 'Have you written Markdown before?';

  /// The question's note, under the answers.
  String get questionNote =>
      'This only sets how the app starts. You can turn any editor on or '
      'off in Settings → Editor at any time.';

  /// The first answer.
  String get answerNone => 'Never';

  /// What the first answer does.
  String get answerNoneHint =>
      'The live editor, and the Markdown source is not offered until you '
      'turn it on.';

  /// The second answer.
  String get answerSome => 'A little';

  /// What the second answer does.
  String get answerSomeHint =>
      'The live editor opens notes; the Markdown source is one switch '
      'away.';

  /// The third answer.
  String get answerFluent => 'All the time';

  /// What the third answer does.
  String get answerFluentHint => 'The Markdown source, as the app comes.';

  /// The tour offer on the last page.
  String get tourOffer => 'Show me around the app';

  /// What the tour offer means.
  String get tourOfferNote =>
      'The tour starts once your first library is open, and points at '
      'the real controls.';

  // Reached again.

  /// The Settings → About row, and the palette command, for the deck.
  String get deckCommand => 'What Niman can do';

  /// The palette command for the tour (the About row uses this too).
  String get tourCommand => 'Take the tour';

  /// The palette command that resumes a tour left halfway.
  String get tourContinueCommand => 'Continue the tour';

  // The tour.

  /// Leaves the tour, remembering where it stopped.
  String get tourDone => 'Done';

  /// Leaves the tour and never offers it again.
  String get tourNever => "Don't show again";

  /// The offer, once the first library is open.
  String get tourOfferTitle => 'Show you around?';

  /// What the offer says.
  String get tourOfferBody =>
      'A few steps through the app, pointing at the real controls. You can '
      'stop at any step and pick it up later from the command palette.';

  /// Accepting the offer.
  String get tourOfferYes => 'Show me';

  /// Declining it (the tour stays in Help and the palette).
  String get tourOfferNo => 'Not now';

  /// The step about the tree.
  String get tourTreeTitle => 'Your library';

  /// The tree step's body.
  String get tourTreeBody =>
      'This is the folder you chose, folder by folder. Anything you do to '
      'a file outside Niman shows up here the moment it lands.';

  /// The step about creating notes.
  String get tourCreateTitle => 'Make a note';

  /// The create step's body.
  String get tourCreateBody =>
      'Notes, list notes, voice notes, templates and folders all start '
      'here. The same menu appears on a phone as the round button.';

  /// The step about the note pane.
  String get tourNoteTitle => 'One note at a time';

  /// The note step's body.
  String get tourNoteBody =>
      'The note on screen; the ones you opened stay in tabs above it, and a '
      'second pane can open beside it on a wide window.';

  /// The step about the three modes.
  String get tourModesTitle => 'Three ways to write';

  /// The modes step's body.
  String get tourModesBody =>
      'Write the Markdown source, write it as it reads, or read it — this '
      'switch is per note, and the library setting decides what opens.';

  /// The step about the toolbar.
  String get tourToolbarTitle => 'The toolbar';

  /// The toolbar step's body.
  String get tourToolbarBody =>
      'Formatting on the line you are in, and the same actions on '
      'right-click. Every construct Niman reads is in the cheatsheet.';

  /// The step that opens the cheatsheet.
  String get tourCheatsheetTitle => 'Every construct, written beside it';

  /// The cheatsheet step's body.
  String get tourCheatsheetBody =>
      'This is the cheatsheet. Each example can be copied, and Insert puts '
      'it in the note you have open.';

  /// The button that opens the cheatsheet for its step.
  String get tourCheatsheetOpen => 'Open it';

  /// The step about the navigation.
  String get tourTabsTitle => 'Everything is a tab';

  /// The navigation step's body.
  String get tourTabsBody =>
      'Files, tasks, search, the quick note, settings. The command palette '
      'reaches every one of them, and every command, from the keyboard.';

  /// The step about the dock.
  String get tourDockTitle => 'Outline, tags, history';

  /// The dock step's body.
  String get tourDockBody =>
      'The outline of the note, its tags and its past versions, beside '
      'it. On a phone the note menu opens the same three.';

  /// The last step's title.
  String get tourEndTitle => 'That is the tour';

  /// The last step's body.
  String get tourEndBody =>
      'Take it again whenever you like from the palette (Help: Take the '
      'tour). The cheatsheet is in the note menu, and the rest of the '
      'app explains itself as you go.';
}
