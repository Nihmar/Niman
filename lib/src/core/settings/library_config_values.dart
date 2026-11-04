/// The plain values of a library's settings (`.niman/settings.json`):
/// each number's default and accepted range, the reader that brings a
/// hand-edited value back into it, and the folder-path sanitizers.
library;

import 'package:niman/src/core/settings/library_settings.dart'
    show
        SourceFont,
        defaultAnnotationsFolder,
        defaultAttachmentsFolder,
        defaultCaptureFolder,
        defaultListFolder,
        defaultTemplateFolder;

/// The number of kept `.history/` versions of a fresh library.
const int defaultHistoryVersions = 10;

/// The smallest accepted `historyVersions` (0 = keep no history).
const int minHistoryVersions = 0;

/// The largest accepted `historyVersions`.
const int maxHistoryVersions = 100;

/// Reads a `historyVersions` value out of the settings file (T-ML-02).
///
/// The file is user-editable by design, so the number in it is an input,
/// not a fact: a hand-typed `-5` or `100000` would otherwise reach the
/// history code as-is. Anything outside [minHistoryVersions] ..
/// [maxHistoryVersions] reads back as [defaultHistoryVersions], the same
/// answer a missing key gives — a nonsense value is no more informative
/// than no value.
int normalizeHistoryVersions(Object? raw) {
  if (raw is! num) return defaultHistoryVersions;
  final count = raw.toInt();
  if (count < minHistoryVersions || count > maxHistoryVersions) {
    return defaultHistoryVersions;
  }
  return count;
}

/// The `trashAutoEmptyDays` that empties nothing: what a fresh library
/// gets, and what an unreadable value falls back to (issue #79).
const int trashAutoEmptyOff = 0;

/// The shortest an item can be asked to wait in `.trash/` before the
/// automatic empty takes it.
const int minTrashAutoEmptyDays = 1;

/// The longest wait the setting accepts (ten years — past it, someone is
/// not asking for an automatic empty at all).
const int maxTrashAutoEmptyDays = 3650;

/// The waits the settings screen offers, in days; a hand-edited file may
/// hold any whole number in [minTrashAutoEmptyDays] ..
/// [maxTrashAutoEmptyDays].
const List<int> trashAutoEmptyChoices = [
  trashAutoEmptyOff,
  7,
  30,
  90,
  180,
  365,
];

/// Reads a `trashAutoEmptyDays` value out of the settings file (issue
/// #79).
///
/// Defaulted to [trashAutoEmptyOff] rather than clamped, unlike every
/// other number here: this one is permission to delete notes for good,
/// and a value nobody can make sense of is not permission. A file whose
/// key says `-1`, `"30"` or `30.5` empties nothing at all.
int normalizeTrashAutoEmptyDays(Object? raw) {
  if (raw is! int) return trashAutoEmptyOff;
  if (raw < minTrashAutoEmptyDays || raw > maxTrashAutoEmptyDays) {
    return trashAutoEmptyOff;
  }
  return raw;
}

/// The least minutes between two history versions taken while editing,
/// in a fresh library.
const int defaultHistoryIntervalMinutes = 5;

/// The history intervals the settings screen offers, in minutes; a
/// hand-edited file may hold any whole number in between.
const List<int> historyIntervalChoices = [1, 2, 5, 10, 15, 30, 60];

/// Reads a `historyIntervalMinutes` value out of the settings file.
///
/// Defaulted rather than clamped, like `historyVersions`: 0 would mean a
/// version on every autosave, and anything outside 1 .. 60 is no more
/// informative than a missing key.
int normalizeHistoryIntervalMinutes(Object? raw) {
  if (raw is! num) return defaultHistoryIntervalMinutes;
  final minutes = raw.toInt();
  if (minutes < historyIntervalChoices.first ||
      minutes > historyIntervalChoices.last) {
    return defaultHistoryIntervalMinutes;
  }
  return minutes;
}

/// The editor's indent width in a fresh library.
const int defaultIndentWidth = 2;

/// The smallest accepted `indentWidth`.
const int minIndentWidth = 2;

/// The largest accepted `indentWidth`.
const int maxIndentWidth = 8;

/// Reads an `indentWidth` out of the settings file, into range.
///
/// Unlike `historyVersions` this one is clamped rather than defaulted: 1
/// and 40 are both plausible things to type, and the nearest legal width
/// is closer to what was meant than a jump back to 2.
int normalizeIndentWidth(Object? raw) {
  if (raw is! num) return defaultIndentWidth;
  final width = raw.toInt();
  if (width < minIndentWidth) return minIndentWidth;
  if (width > maxIndentWidth) return maxIndentWidth;
  return width;
}

/// The new flashcards a deck shows per day in a fresh library (#533).
const int defaultNewCardsPerDay = 20;

/// The most new cards per deck per day accepted; 0 is none.
const int maxNewCardsPerDay = 1000;

/// Reads a `newCardsPerDay` out of the settings file, into range: clamped
/// like `indentWidth`, since a hand-typed number stays near what was
/// meant (0 turns new cards off); anything that is not a number reads as
/// the default.
int normalizeNewCardsPerDay(Object? raw) {
  if (raw is! num || !raw.isFinite) return defaultNewCardsPerDay;
  final count = raw.toInt();
  if (count < 0) return 0;
  if (count > maxNewCardsPerDay) return maxNewCardsPerDay;
  return count;
}

/// The text size of a fresh library: the sizes the app shipped with.
const double defaultTextScale = 1;

/// The smallest accepted text scale.
const double minTextScale = 0.8;

/// The largest accepted text scale.
const double maxTextScale = 1.8;

/// The source editor's font in a fresh library: the monospace face the
/// editor has always been set in (issue #259).
const SourceFont defaultSourceFont = SourceFont.monospace;

/// The source editor's font size at [defaultTextScale], in logical
/// pixels.
///
/// It was the old source editor's default, kept so a note reads at the
/// size it always had; the note scale multiplies it.
const double baseNoteFontSize = 13;

/// Reads a `sourceFont` out of the settings file.
///
/// Defaulted rather than clamped, like the enums it sits with: a name this
/// build does not know — a newer build's, or a hand-typed one — is no more
/// informative than a missing key, and the editor stays as it shipped.
SourceFont normalizeSourceFont(Object? raw) => SourceFont.fromName(raw);

/// Reads a text scale out of the settings file, into range.
///
/// Clamped rather than defaulted, for the reason [normalizeIndentWidth]
/// is: someone who typed 3 wants the text as large as it goes, not back
/// at the size they were trying to leave.
double normalizeTextScale(Object? raw) {
  if (raw is! num) return defaultTextScale;
  final scale = raw.toDouble();
  if (!scale.isFinite) return defaultTextScale;
  if (scale < minTextScale) return minTextScale;
  if (scale > maxTextScale) return maxTextScale;
  return scale;
}

/// The tree pane's width in a fresh library (logical pixels).
const double defaultTreeWidth = 340;

/// The narrowest the tree pane drags to.
const double minTreeWidth = 200;

/// The widest the tree pane drags to.
const double maxTreeWidth = 600;

/// Reads a `treeWidth` out of the settings file, clamped into range —
/// the same bargain as `indentWidth`: a hand-typed number stays near
/// what was meant, anything else reads back as the default.
double normalizeTreeWidth(Object? raw) {
  if (raw is! num) return defaultTreeWidth;
  final width = raw.toDouble();
  if (width < minTreeWidth) return minTreeWidth;
  if (width > maxTreeWidth) return maxTreeWidth;
  return width;
}

/// The right dock's width in a fresh library (logical pixels, #297).
const double defaultDockWidth = 280;

/// The narrowest the right dock drags to.
const double minDockWidth = 200;

/// The widest the right dock drags to.
const double maxDockWidth = 600;

/// Reads a `dockWidth` out of the settings, clamped into range — the same
/// bargain as `treeWidth`.
double normalizeDockWidth(Object? raw) {
  if (raw is! num) return defaultDockWidth;
  final width = raw.toDouble();
  if (width < minDockWidth) return minDockWidth;
  if (width > maxDockWidth) return maxDockWidth;
  return width;
}

/// The note column's width in a fresh library, in logical pixels (#171):
/// about 80 characters of prose at the shipped text size, the measure
/// the preview already read at.
///
/// It is also the 100% the settings show: the file stores pixels, the
/// screen shows a share of this, so nobody has to guess what 700 px reads
/// like.
const double defaultNoteColumnWidth = 700;

/// The narrowest accepted note column: 70% of the default.
const double minNoteColumnWidth = 490;

/// The widest accepted note column: 200% of the default.
const double maxNoteColumnWidth = 1400;

/// Reads a `noteColumnWidth` out of the settings file, clamped into range
/// — the bargain [normalizeIndentWidth] makes: a hand-typed number stays
/// near what was meant, anything else reads back as the default.
double normalizeNoteColumnWidth(Object? raw) {
  if (raw is! num) return defaultNoteColumnWidth;
  final width = raw.toDouble();
  if (!width.isFinite) return defaultNoteColumnWidth;
  if (width < minNoteColumnWidth) return minNoteColumnWidth;
  if (width > maxNoteColumnWidth) return maxNoteColumnWidth;
  return width;
}

/// The todo sections collapsed in a library nobody has opened on this
/// device yet (#1003): only Done, whose id is `todoDoneSectionId` in
/// `todo/todo_sections.dart`.
/// This is the one place that spells the default: `TodoListView` starts from
/// it, and a test pins it to the id.
const Set<String> defaultTodoCollapsedSections = {'done'};

/// Sanitizes a library-relative folder path: trims, drops leading and
/// trailing slashes and empty/`.`/`..` segments; an empty result is
/// [fallback].
String cleanFolderPath(String folder, String fallback) {
  final parts = folder
      .trim()
      .split('/')
      .where((s) => s.isNotEmpty && s != '.' && s != '..')
      .toList();
  return parts.isEmpty ? fallback : parts.join('/');
}

/// Sanitizes a list-folder path; an empty result is [defaultListFolder].
String cleanListFolder(String folder) =>
    cleanFolderPath(folder, defaultListFolder);

/// Sanitizes a template-folder path; an empty result is
/// [defaultTemplateFolder].
String cleanTemplateFolder(String folder) =>
    cleanFolderPath(folder, defaultTemplateFolder);

/// Sanitizes an attachments-folder path; an empty result is
/// [defaultAttachmentsFolder].
String cleanAttachmentsFolder(String folder) =>
    cleanFolderPath(folder, defaultAttachmentsFolder);

/// Sanitizes an annotations-folder path; an empty result is
/// [defaultAnnotationsFolder].
String cleanAnnotationsFolder(String folder) =>
    cleanFolderPath(folder, defaultAnnotationsFolder);

/// Sanitizes a capture-folder path; an empty result is
/// [defaultCaptureFolder].
String cleanCaptureFolder(String folder) =>
    cleanFolderPath(folder, defaultCaptureFolder);
