/// One expanded folder, as [VisibleTree] is told of it (#1200).
///
/// `id` is the folder's note id and `parentId` its parent's (0 for the
/// library's root). `rank` is the folder's position among its siblings, in
/// the tree's order: how many siblings sort before it, as `NoteDao.rankOf`
/// answers. `childCount` is how many children the folder has, as
/// `NoteDao.childCount` answers.
typedef ExpandedFolder = ({int id, int parentId, int rank, int childCount});

/// Where a row of the visible tree sits: the folder it is a child of, its
/// position among that folder's children, and its depth (the root's children
/// are at depth 0).
typedef TreeSlot = ({int parent, int position, int depth});

/// What a folder's expanded children say about the rows around them, by rank.
///
/// All three lists have the children's order: `ids` and `ranks` have one
/// entry per child, and `before` has one more — `before[j]` is the number of
/// rows the children `0 ..< j` open under themselves, so `before.last` is the
/// rows under all of them.
typedef _Opened = ({List<int> ids, List<int> ranks, List<int> before});

/// The rows the note tree shows, described without holding any of them
/// (#1200).
///
/// The list is the library's root children, and right after an expanded
/// folder's row come its own children, at one more depth, recursively. Its
/// length is then
///
/// ```text
/// visible(f) = childCount(f) + sum of visible(c) over f's expanded children
/// ```
///
/// taken at the root, and nothing needs a row to say it: the model is built
/// from the root's child count and, for each expanded folder, its place among
/// its siblings and its own child count. An index maps to a [TreeSlot] by
/// walking down from the root, stepping over the block of rows that an
/// expanded folder opens or entering it; [indexOf] walks the same way back.
/// The cost of either is the expanded folders on the path times a binary
/// search among each one's expanded children — a user opens a handful of
/// folders — and never the rows of a folder, however many it has.
///
/// The model is immutable. Folders the input gives that the root does not
/// reach through expanded folders — the expanded set is by path, and a
/// collapsed ancestor hides what it holds — are ignored, and so is a second
/// entry for an id already given. The counts and ranks are read from the
/// index at one revision; fed ones that disagree (a rank at or beyond its
/// parent's child count, two siblings of one rank) the answers are
/// unspecified, but they are still computed from the same arithmetic and
/// neither loop nor throw.
///
/// The row being made under a folder is not in the model yet: a later phase
/// adds it as a virtual row one position under its folder.
final class VisibleTree {
  /// The tree of a root with [rootCount] children, and [expanded] folders.
  ///
  /// [expanded] may hold folders that are not visible; see the class
  /// comment.
  new({required int rootCount, Iterable<ExpandedFolder> expanded = const []}) {
    final byParent = <int, List<ExpandedFolder>>{};
    final given = <int>{rootId};
    for (final folder in expanded) {
      // The root cannot be a child, and an id counts once, which also keeps a
      // malformed input from making a cycle the walk below could not leave.
      if (!given.add(folder.id)) continue;
      (byParent[folder.parentId] ??= []).add(folder);
    }
    _childCount[rootId] = rootCount;
    _depth[rootId] = 0;

    // Breadth first from the root: what the root does not reach is dropped
    // here, by never being visited.
    final order = <int>[rootId];
    for (var i = 0; i < order.length; i++) {
      final parent = order[i];
      final children = byParent[parent];
      if (children == null) continue;
      children.sort((a, b) => a.rank.compareTo(b.rank));
      for (final child in children) {
        _childCount[child.id] = child.childCount;
        _depth[child.id] = _depth[parent]! + 1;
        order.add(child.id);
      }
    }

    // Deepest first, so a folder's expanded children have their size when it
    // is summed.
    for (var i = order.length - 1; i >= 0; i--) {
      final id = order[i];
      final children = byParent[id];
      var rows = _childCount[id]!;
      if (children != null && children.isNotEmpty) {
        final ids = List<int>.filled(children.length, 0);
        final ranks = List<int>.filled(children.length, 0);
        final before = List<int>.filled(children.length + 1, 0);
        for (var j = 0; j < children.length; j++) {
          ids[j] = children[j].id;
          ranks[j] = children[j].rank;
          before[j + 1] = before[j] + _size[children[j].id]!;
        }
        _opened[id] = (ids: ids, ranks: ranks, before: before);
        rows += before.last;
      }
      _size[id] = rows;
    }

    // Shallowest first: where each folder's children begin is where its own
    // row is, plus one.
    _firstChild[rootId] = 0;
    for (final id in order) {
      final opened = _opened[id];
      if (opened == null) continue;
      for (var j = 0; j < opened.ids.length; j++) {
        _firstChild[opened.ids[j]] =
            _firstChild[id]! + opened.ranks[j] + opened.before[j] + 1;
      }
    }
  }

  /// The id of the library's root, the parent of the tree's first level.
  static const int rootId = 0;

  /// For each visible folder (the root included), how many children it has.
  final Map<int, int> _childCount = <int, int>{};

  /// For each visible folder, the depth of the rows that are its children.
  final Map<int, int> _depth = <int, int>{};

  /// For each visible folder, the rows it shows: its children and everything
  /// its expanded children open.
  final Map<int, int> _size = <int, int>{};

  /// For each visible folder, the index of the row at position 0 among its
  /// children: the folder's own row plus one, and 0 for the root.
  final Map<int, int> _firstChild = <int, int>{};

  /// For each visible folder with expanded children, those children by rank.
  final Map<int, _Opened> _opened = <int, _Opened>{};

  /// How many rows the list shows.
  int get length => _size[rootId]!;

  /// Whether [folderId] is the root or an expanded folder the root reaches
  /// through expanded folders: the folders whose children are in the list.
  bool isVisibleFolder(int folderId) => _childCount.containsKey(folderId);

  /// How many children the visible folder [folderId] has, as the model was
  /// given it, or null when [isVisibleFolder] says no.
  int? childCount(int folderId) => _childCount[folderId];

  /// The depth of the rows that are [folderId]'s children, or null when
  /// [isVisibleFolder] says no. The root's children are at depth 0.
  int? childDepth(int folderId) => _depth[folderId];

  /// The row at [index]: which folder it is a child of, and its position
  /// among that folder's children.
  ///
  /// Throws a [RangeError] unless `0 <= index < length`.
  TreeSlot slotAt(int index) {
    RangeError.checkValidIndex(index, this, 'index', length);
    var folder = rootId;
    var depth = 0;
    // Within [folder]: the rows before the one asked for.
    var offset = index;
    while (true) {
      final opened = _opened[folder];
      if (opened == null) {
        return (parent: folder, position: offset, depth: depth);
      }
      final ranks = opened.ranks;
      final before = opened.before;
      // The row of expanded child j is at ranks[j] + before[j] (the rows
      // before it are the earlier siblings and the blocks they opened), and
      // the starts only grow: the last child starting at or before [offset]
      // is the one it is in or after.
      var low = 0;
      var high = ranks.length;
      while (low < high) {
        final middle = (low + high) >> 1;
        if (ranks[middle] + before[middle] <= offset) {
          low = middle + 1;
        } else {
          high = middle;
        }
      }
      final j = low - 1;
      if (j < 0) return (parent: folder, position: offset, depth: depth);
      final start = ranks[j] + before[j];
      if (offset == start) {
        return (parent: folder, position: ranks[j], depth: depth);
      }
      if (offset <= start + (before[j + 1] - before[j])) {
        // Inside the block the folder opens: its children start one row after
        // its own.
        folder = opened.ids[j];
        offset -= start + 1;
        depth++;
        continue;
      }
      // Past the block: the position counts the rows it opened as rows that
      // are not siblings.
      return (parent: folder, position: offset - before[j + 1], depth: depth);
    }
  }

  /// The index of the row of the visible folder [folderId] itself, which its
  /// children follow; or null for the root, which has no row, and for a
  /// folder [isVisibleFolder] says no to.
  int? rowIndexOf(int folderId) {
    if (folderId == rootId) return null;
    final first = _firstChild[folderId];
    return first == null ? null : first - 1;
  }

  /// The position of the last row of the run of [parentId]'s children that
  /// starts at [position]: the rows that follow one another in the list with
  /// nothing opened between them. A run ends at an expanded child, whose own
  /// row is the last of it, or at the folder's last child.
  ///
  /// Null when [parentId] is not a visible folder (see [isVisibleFolder]) or
  /// [position] is not one of its children. What searches the list by name
  /// uses it to ask the index for a whole run at once.
  int? runEnd(int parentId, int position) {
    final count = _childCount[parentId];
    if (count == null || position < 0 || position >= count) return null;
    final opened = _opened[parentId];
    if (opened == null) return count - 1;
    // The first expanded child at or after the position.
    final ranks = opened.ranks;
    var low = 0;
    var high = ranks.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (ranks[middle] < position) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low < ranks.length ? ranks[low] : count - 1;
  }

  /// The index of the row at [position] among the children of [parentId],
  /// the inverse of [slotAt]; or null when [parentId] is not a visible folder
  /// (see [isVisibleFolder]) or [position] is not one of its children.
  int? indexOf(int parentId, int position) {
    final count = _childCount[parentId];
    if (count == null || position < 0 || position >= count) return null;
    final opened = _opened[parentId];
    var index = _firstChild[parentId]! + position;
    if (opened != null) {
      // The rows opened by the expanded children that come before the
      // position: those of rank below it.
      final ranks = opened.ranks;
      var low = 0;
      var high = ranks.length;
      while (low < high) {
        final middle = (low + high) >> 1;
        if (ranks[middle] < position) {
          low = middle + 1;
        } else {
          high = middle;
        }
      }
      index += opened.before[low];
    }
    return index;
  }
}
