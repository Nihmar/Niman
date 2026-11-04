import 'package:flutter/foundation.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/ui/expanded_folders.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_navigation_state.dart';

/// What the note about to open is asked to land on (#1256): a heading
/// (T-M3-07), a template's `{{cursor}}` offset (#53), the words a search
/// result matched (#1045). One value, read by the view that opens the note,
/// in place of three loose fields the next build had to find together.
@immutable
final class OpenRequest {
  /// A request for [anchor], [caret] and [find]; each may be absent.
  const new({this.anchor, this.caret, this.find});

  /// Nothing asked: the note opens where it was left.
  static const none = OpenRequest();

  /// A heading anchor to land on.
  final String? anchor;

  /// A template `{{cursor}}` offset to put the caret on. Fresh notes only:
  /// appended text joins a file whose length the creation flow does not
  /// know.
  final int? caret;

  /// The words a search result matched, for the note to show.
  final List<String>? find;
}

/// What a change to the selection did to the note on screen, for the
/// listeners that follow it (the note's kind, the phone's fade).
enum NoteShift {
  /// A note was opened: it takes the screen.
  opened,

  /// The note on screen was left for the tree.
  closed,

  /// Nothing the note on screen shows changed.
  none,
}

/// What the shell has selected and what it shows (#1256): the selected row,
/// whether the phone's tree or its note is up, whether the wide tree pane
/// is, the folders open in the tree, and what the note about to open is
/// asked.
///
/// The transitions between screens — opening a note, closing it, showing a
/// folder — are operations on it, which say what changed ([shift]); the
/// shell and its collaborators listen instead of each transition writing
/// every one of them by hand.
final class ShellSelection extends ChangeNotifier {
  /// A selection whose transitions move [nav] and open folders in
  /// [expanded].
  new({required this.nav, required this.expanded});

  /// Where the shell is: the tab a note was opened from, the tabs visited.
  final ShellNavigationState nav;

  /// The folders open in the tree.
  final ExpandedFolders expanded;

  /// The selected row (library-relative), a note or a folder.
  String? get path => _path;
  String? _path;

  /// Whether [path] is a folder.
  bool get isDir => _isDir;
  bool _isDir = false;

  /// Whether the phone shows its tabs rather than the note full screen.
  bool get treeVisible => _treeVisible;
  bool _treeVisible = true;

  /// Whether the wide layout's tree pane shows (the title bar's toggle;
  /// the rail always stays, T-PP-22).
  bool get sidebarVisible => _sidebarVisible;
  bool _sidebarVisible = true;

  /// What the note about to open is asked to land on.
  OpenRequest get request => _request;
  OpenRequest _request = OpenRequest.none;

  /// External-change reload requests for the open note: bumped when the
  /// already-open note is reopened, on resume, after a sync, so the mounted
  /// view re-reads the file when its buffer is clean.
  int get reloadToken => _reloadToken;
  int _reloadToken = 0;

  /// The links followed: a PDF or a book goes back to a link's place when
  /// it moves (#282). Not [reloadToken], which also moves on a resume or a
  /// sync, when a file must stay where it is read.
  int get linksFollowed => _linksFollowed;
  int _linksFollowed = 0;

  /// The note the Files pane last opened, and how many times it has asked
  /// for the caret in it (#727): the note view takes the caret when the
  /// number changes for its own path.
  String? get caretPath => _caretPath;
  String? _caretPath;

  /// See [caretPath].
  int get caretRequest => _caretRequest;
  int _caretRequest = 0;

  /// A note a template asked to open in preview (#51), until its tab is
  /// made ([takePreview]).
  String? _opensInPreview;

  /// What the change being notified did to the note on screen; [NoteShift.none]
  /// outside a notification.
  NoteShift get shift => _shift;
  NoteShift _shift = NoteShift.none;

  /// The selected note, when a note rather than a folder is selected.
  String? get note => _isDir ? null : _path;

  /// The note on the phone's screen, if one is.
  String? get noteOnScreen => _treeVisible ? null : note;

  /// Whether [path] is the selected note.
  bool selects(String path) => _path == path && !_isDir;

  /// The folder the tree is on: the selected folder, or the selected
  /// note's folder, or the root.
  String get folder => switch (_path) {
    null => '',
    final path => _isDir ? path : parentOf(path),
  };

  /// Opens the note at [path] wherever it was asked from (#709, #710): the
  /// tab on screen kept for the way back, Files visited when
  /// [bringFiles] — a wide window whose panes are out of sight.
  ///
  /// [preview] opens it in its preview (#51), [followsLink] counts a link
  /// followed (#282). Reopening the note already open asks its view to
  /// re-read the file, whose path did not change.
  void open(
    String path, {
    OpenRequest request = OpenRequest.none,
    bool preview = false,
    bool followsLink = false,
    bool bringFiles = false,
  }) {
    final same = selects(path);
    if (preview) _opensInPreview = path;
    _path = path;
    _isDir = false;
    _treeVisible = false;
    nav.noteFrom = nav.tab;
    if (bringFiles) nav.visit(ShellTab.files);
    _request = request;
    if (followsLink) _linksFollowed++;
    if (same) _reloadToken++;
    _notify(NoteShift.opened);
  }

  /// A row of the tree or the Files pane picked on the phone, or a note
  /// picked there on a wide window: a note takes the screen, a folder
  /// closes the note and opens in the tree. Nothing is asked of the note.
  void pick(String path, {required bool isDir}) {
    _path = path;
    _isDir = isDir;
    _treeVisible = isDir;
    nav.noteFrom = nav.tab;
    _request = OpenRequest.none;
    if (isDir) expanded.add(path);
    _notify(isDir ? NoteShift.closed : NoteShift.opened);
  }

  /// Opens the quick note at [path] in its tab, back returning to [from].
  /// [reload] when the note open already predates text appended to it.
  void openQuickNote(
    String path, {
    required ShellTab from,
    bool reload = false,
  }) {
    nav
      ..visit(ShellTab.quickNote)
      ..noteFrom = from;
    _path = path;
    _isDir = false;
    _treeVisible = false;
    if (reload) _reloadToken++;
    _notify(NoteShift.opened);
  }

  /// Leaves the phone's full-screen note for the tab it was opened from,
  /// its tree up (the note stays selected).
  void close() {
    nav.visit(nav.noteFrom);
    _treeVisible = true;
    _notify(NoteShift.closed);
  }

  /// Selects the folder at [path], or nothing for the root (''), leaving
  /// the note on screen alone: opened in the tree unless [expand] is false.
  void selectFolder(String path, {bool expand = true}) {
    _path = path.isEmpty ? null : path;
    _isDir = path.isNotEmpty;
    if (expand && path.isNotEmpty) expanded.add(path);
    _notify(NoteShift.none);
  }

  /// Shows the library folder [folder] ('' is the root) in the tree: the
  /// Files tab, the tree pane open, the folder and every folder above it
  /// expanded, and it selected.
  void revealFolder(String folder) {
    nav.tab = ShellTab.files;
    _sidebarVisible = true;
    if (folder.isNotEmpty) {
      expanded.addWithAncestors(folder);
      _path = folder;
      _isDir = true;
      _treeVisible = true;
    }
    _notify(NoteShift.none);
  }

  /// Shows the note at [path] as the tree's selected row (#712): the Files
  /// view in the sidebar, every folder above it open.
  void revealNote(String path) {
    revealFolder(parentOf(path));
    _path = path;
    _isDir = false;
    _treeVisible = true;
    _notify(NoteShift.none);
  }

  /// The wide window's showing tab is [shown] (#23): the tree follows it;
  /// with no tab showing, only a selected folder stays.
  void follow(String? shown) {
    if (shown != null) {
      if (_path == shown && !_isDir) return;
      _path = shown;
      _isDir = false;
    } else if (!_isDir) {
      if (_path == null) return;
      _path = null;
    } else {
      return;
    }
    _notify(NoteShift.none);
  }

  /// The tab bar's switch away from a note: the phone's tabs are up again.
  void showTree() {
    if (_treeVisible) return;
    _treeVisible = true;
    _notify(NoteShift.none);
  }

  /// Shows the wide tree pane.
  void showSidebar() {
    if (_sidebarVisible) return;
    _sidebarVisible = true;
    _notify(NoteShift.none);
  }

  /// Shows or hides the wide tree pane; the rail stays (T-PP-22).
  void toggleSidebar() {
    _sidebarVisible = !_sidebarVisible;
    _notify(NoteShift.none);
  }

  /// Opens or closes the tree's folder at [path].
  void toggleFolder(String path) {
    if (expanded.contains(path)) {
      expanded.remove(path);
    } else {
      expanded.add(path);
    }
    _notify(NoteShift.none);
  }

  /// Opens the tree's folder at [path] (a folder selected on a wide window
  /// leaves the tabs alone).
  void expand(String path) {
    expanded.add(path);
    _notify(NoteShift.none);
  }

  /// A rename or a move of [from] to [to]: the folders open under it stay
  /// open under the new name (#1069), and the selection follows only a
  /// rename that is about it — the row itself, or a folder it sits in.
  void moved(String from, String to) {
    expanded.moved(from, to);
    if (_path case final path? when path == from || path.startsWith('$from/')) {
      _path = to + path.substring(from.length);
    }
    _notify(NoteShift.none);
  }

  /// [path] was deleted. Its folders leave the tree; on a wide window the
  /// selection lets go only of a folder that went with it (the workspace
  /// moved the showing tab on already), on a phone it lets go.
  void deleted(String path, {required bool wide}) {
    expanded.deleted(path);
    if (!wide) {
      _path = null;
    } else if (_path case final selected?
        when _isDir && (selected == path || selected.startsWith('$path/'))) {
      _path = null;
    }
    _notify(NoteShift.none);
  }

  /// Lets go of the selection.
  void clear() {
    if (_path == null) return;
    _path = null;
    _notify(NoteShift.none);
  }

  /// Lets go of the selection when it is [path].
  void clearIf(String path) {
    if (_path == path) clear();
  }

  /// Asks the open note's view to re-read its file.
  void reload() {
    _reloadToken++;
    _notify(NoteShift.none);
  }

  /// Asks the selected note's view to re-read its file, when a note is
  /// selected and [paths], if given, holds it.
  void reloadOpen([Set<String>? paths]) {
    final open = note;
    if (open == null || (paths != null && !paths.contains(open))) return;
    reload();
  }

  /// Asks the note at [path] for the caret: the Files pane opened it.
  void requestCaret(String path) {
    _caretPath = path;
    _caretRequest++;
    _notify(NoteShift.none);
  }

  /// The note a template asked to open in preview, once: its tab is made
  /// by the build that asks. Read in a build, so it notifies nobody.
  String? takePreview() {
    final path = _opensInPreview;
    _opensInPreview = null;
    return path;
  }

  void _notify(NoteShift shift) {
    _shift = shift;
    try {
      notifyListeners();
    } finally {
      _shift = NoteShift.none;
    }
  }
}
