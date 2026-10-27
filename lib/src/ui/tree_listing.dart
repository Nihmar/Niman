import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/ocr/ocr_tree_order.dart';
import 'package:niman/src/ui/tree_pages.dart';
import 'package:niman/src/ui/visible_tree.dart';

/// What the note tree draws at one index of its list (#1200).
final class TreeEntry {
  /// A row of a note or a folder, read from a loaded page.
  const new row({
    required Note this.note,
    required this.depth,
    required this.sidecar,
  }) : creating = false,
       page = null;

  /// The row being made, a virtual one under its folder's.
  const new creatingRow({required this.depth})
    : note = null,
      sidecar = false,
      creating = true,
      page = null;

  /// A row whose page is not loaded yet: drawn empty, and [page] is the one
  /// to ask for.
  const new unloaded({required TreePageKey this.page})
    : note = null,
      depth = 0,
      sidecar = false,
      creating = false;

  /// The row's note, or null for the row being made and an unloaded row.
  final Note? note;

  /// How far in the row is drawn.
  final int depth;

  /// Whether the row is a text recognition sidecar shown under its file
  /// (#595).
  final bool sidecar;

  /// Whether this is the row being made (#712).
  final bool creating;

  /// The page a row waits for, when it is unloaded.
  final TreePageKey? page;
}

/// The pages of one folder as the tree shows them, a text recognition
/// sidecar moved under its file within the page it is in.
typedef _Nested = ({List<Note> rows, List<(Note, bool)> entries});

/// The rows of the note tree, by index: the [VisibleTree] model, the
/// [TreePages] it reads its rows from, and the row being made as one more
/// row of the list (#1200).
///
/// The list the widget draws is the model's, plus a virtual row one under the
/// folder a note or folder is being made in. The walk of the keyboard, the
/// cursor and the marks do not see that row: they use the model's indices
/// ([modelLength], [modelIndexOfLoaded]), and [listIndexOf] gives the place
/// the list draws one at.
///
/// A text recognition sidecar is nested within its page, so the row at a
/// position of a page is the page's rows in nested order. Nesting moves rows
/// within a page only, so positions and counts are the model's.
///
/// A listing is made for the model of one read. While a newer read is out the
/// widget [freeze]s the one it shows, so that rows still drawn from it keep
/// their notes when the pages are forgotten under it.
final class TreeListing {
  /// The listing of [model], reading its rows from [pages] in [sort]'s order
  /// through [session].
  new({
    required this.session,
    required this.model,
    required this.pages,
    required this.sort,
  });

  /// Where the pages are read from.
  final LibrarySession session;

  /// How many rows there are, and where each folder's are.
  final VisibleTree model;

  /// The rows loaded.
  final TreePages pages;

  /// The order the model and the pages are in.
  final TreeSort sort;

  /// The model index of the folder row the row being made sits under.
  int? _createAfter;
  int _createDepth = 0;

  /// The pages as they were when the listing was frozen, or null.
  Map<TreePageKey, List<Note>>? _frozen;

  final Map<TreePageKey, _Nested> _nested = <TreePageKey, _Nested>{};

  /// How many rows the list draws: the model's, and the row being made.
  int get length => model.length + (_createAfter == null ? 0 : 1);

  /// How many rows the model has, the row being made not among them.
  int get modelLength => model.length;

  /// Whether the listing draws from the pages it held when it was frozen.
  bool get isFrozen => _frozen != null;

  /// Keeps the pages held now as the only rows this listing reads, until it
  /// is dropped: a read of the tree is out, and what it will forget is still
  /// on screen.
  void freeze() => _frozen ??= pages.held();

  /// Puts the row being made one under the row at model index [folderIndex],
  /// drawn [depth] in; null takes it away.
  void placeCreating(int? folderIndex, {int depth = 0}) {
    _createAfter = folderIndex;
    _createDepth = depth;
  }

  /// The list index the row at model index [modelIndex] is drawn at.
  int listIndexOf(int modelIndex) {
    final after = _createAfter;
    return after != null && modelIndex > after ? modelIndex + 1 : modelIndex;
  }

  /// The model index of the row drawn at [listIndex], or null for the row
  /// being made.
  int? modelIndexOf(int listIndex) {
    final after = _createAfter;
    if (after == null || listIndex <= after) return listIndex;
    return listIndex == after + 1 ? null : listIndex - 1;
  }

  /// The row drawn at [listIndex].
  TreeEntry entryAt(int listIndex) {
    final index = modelIndexOf(listIndex);
    if (index == null) return TreeEntry.creatingRow(depth: _createDepth);
    return modelEntryAt(index);
  }

  /// The row at model index [index]: unloaded when its page is not held.
  TreeEntry modelEntryAt(int index) {
    final slot = model.slotAt(index);
    final page = slot.position ~/ pages.pageSize;
    final nested = _nestedPage((slot.parent, page));
    final at = slot.position % pages.pageSize;
    if (nested == null || at >= nested.length) {
      return TreeEntry.unloaded(page: (slot.parent, page));
    }
    final (note, sidecar) = nested[at];
    return TreeEntry.row(
      note: note,
      depth: sidecar ? slot.depth + 1 : slot.depth,
      sidecar: sidecar,
    );
  }

  List<Note>? _rowsOf(TreePageKey key) {
    final frozen = _frozen;
    return frozen != null ? frozen[key] : pages.pageRows(key.$1, key.$2);
  }

  /// The rows of [key]'s page in the order they are drawn in, each with
  /// whether it is a sidecar; null when the page is not held.
  List<(Note, bool)>? _nestedPage(TreePageKey key) {
    final rows = _rowsOf(key);
    if (rows == null) {
      _nested.remove(key);
      return null;
    }
    final held = _nested[key];
    if (held != null && identical(held.rows, rows)) return held.entries;
    final entries = nestOcrSidecars(rows, (note) => note.name);
    _nested[key] = (rows: rows, entries: entries);
    return entries;
  }

  /// The rows of page [page] of the folder [parent] as they are drawn, each
  /// with whether it is a sidecar; null when the page is not held.
  List<(Note, bool)>? nestedRows(int parent, int page) =>
      _nestedPage((parent, page));

  /// Lets go of the nested orders of pages that are no longer held: they
  /// would keep the rows of a page the window left.
  void prune() {
    _nested.removeWhere((key, _) => _rowsOf(key) == null);
  }

  /// The model index of the loaded row at [path], or null when no page held
  /// has it. Reads nothing: the rows of the pages held are searched.
  int? modelIndexOfLoaded(String path) {
    final held = _frozen ?? pages.held();
    for (final MapEntry(:key, value: rows) in held.entries) {
      if (!rows.any((note) => note.path == path)) continue;
      final nested = _nestedPage(key);
      final at = nested?.indexWhere((entry) => entry.$1.path == path) ?? -1;
      if (at < 0) continue;
      final index = model.indexOf(key.$1, key.$2 * pages.pageSize + at);
      if (index != null) return index;
    }
    return null;
  }

  /// The model index of the row at [path], from the pages held or else from
  /// the index: null when the tree does not show it.
  Future<int?> modelIndexOfPath(String path) async {
    final held = modelIndexOfLoaded(path);
    if (held != null) return held;
    final note = await session.ops?.find(path);
    return note == null ? null : await modelIndexOfNote(note);
  }

  /// The model index of [note], found by its rank among its siblings: the
  /// folder it is in has to be shown, and its page is read if it is not
  /// held, since the place a sidecar is drawn at depends on the page's rows.
  Future<int?> modelIndexOfNote(Note note) async {
    final count = model.childCount(note.parent);
    if (count == null) return null;
    final rank = await session.rankOf(note, sort: sort);
    if (rank >= count) return null;
    final page = rank ~/ pages.pageSize;
    await pages.load(session, note.parent, page, sort);
    final nested = _nestedPage((note.parent, page));
    final at = nested?.indexWhere((entry) => entry.$1.path == note.path) ?? -1;
    if (at < 0) return null;
    return model.indexOf(note.parent, page * pages.pageSize + at);
  }

  /// Makes sure the page of the row at model index [index] is held.
  Future<void> ensureRow(int index) async {
    final slot = model.slotAt(index);
    await pages.load(
      session,
      slot.parent,
      slot.position ~/ pages.pageSize,
      sort,
    );
  }

  /// The note at [position] of the folder [parent] in the order the index
  /// has, without nesting: from the page held, else read.
  Future<Note?> plainNoteAt(int parent, int position) async {
    final page = pages.pageRows(parent, position ~/ pages.pageSize);
    final at = position % pages.pageSize;
    if (page != null && at < page.length) return page[at];
    final read = await session.childrenAt(
      parent,
      offset: position,
      limit: 1,
      sort: sort,
    );
    return read.isEmpty ? null : read.first;
  }
}
