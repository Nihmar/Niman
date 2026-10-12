/// The fenced divs open where the tree's build is (#729): which list the
/// next block goes into when a column is the innermost container, and the
/// nodes the fence lines open and close.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/line_state.dart';

/// One open div: what it is, how many items and whether a footnote
/// definition were around it, its node — where it stands in its parent,
/// which a closer replaces with the node closed — and the list the blocks
/// inside it go into: a column's children, or for a tracked unknown div,
/// which has no node, the list its opener went into. A `columns` div's
/// blocks go into its implicit columns.
typedef _Frame = ({
  DivKind kind,
  int items,
  bool footnote,
  List<BlockNode>? parent,
  int index,
  List<BlockNode>? inner,
});

/// The divs open where a build of the tree is, innermost last.
///
/// The scanner reads them flat: each fence line is a block, and the blocks
/// between say how deep in items they stand, not in which div. The stack
/// is the tree's side of that, as the list of open items is: a block goes
/// into the innermost div opened in as many items as it stands in, when
/// there is one, and into the innermost item otherwise.
final class DivStack {
  final List<_Frame> _frames = <_Frame>[];

  /// Ends the divs a block standing in [items] list items, in a footnote
  /// definition or not, is outside of: a div ends with the item and the
  /// footnote definition it opened in.
  void settle(int items, {required bool inFootnote}) {
    while (_frames.isNotEmpty) {
      final frame = _frames.last;
      if (frame.items <= items && (inFootnote || !frame.footnote)) return;
      _frames.removeLast();
    }
  }

  /// Ends every div opened in a footnote definition, which has ended.
  void leaveFootnote() => settle(1 << 30, inFootnote: false);

  /// The list a block of [kind] standing in [items] items goes into, or
  /// null when the innermost container there is no div.
  ///
  /// Inside a `columns` div outside any column, a block starts an implicit
  /// column, or goes on with the one open: blank lines alone make none, and
  /// go nowhere — the gap between two columns.
  List<BlockNode>? into(int items, BlockKind kind, {required bool inFootnote}) {
    final frame = _innermost(items, inFootnote);
    if (frame == null) return null;
    final inner = frame.inner;
    if (inner != null) return inner;
    final node = frame.parent?[frame.index];
    if (node is! ColumnsNode) return null;
    final columns = node.columns;
    final open = columns.isNotEmpty && columns.last.implicit
        ? columns.last
        : null;
    if (open != null) return open.children;
    if (kind == BlockKind.blank) return <BlockNode>[];
    return null;
  }

  /// The implicit column a block on [line] starts in the `columns` div
  /// innermost for [items], when [into] answered null there for a block
  /// that is not blank; null when no `columns` div is innermost.
  List<BlockNode>? startImplicit(
    int items,
    int line, {
    required bool inFootnote,
  }) {
    final frame = _innermost(items, inFootnote);
    final node = frame?.parent?[frame.index];
    if (node is! ColumnsNode) return null;
    final children = <BlockNode>[];
    node.columns.add(ColumnNode(line: line, children: children));
    return children;
  }

  /// The innermost div when it is the innermost container for a block
  /// standing in [items] items: opened in as many, inside a footnote
  /// definition or not as the block is.
  _Frame? _innermost(int items, bool inFootnote) {
    if (_frames.isEmpty) return null;
    final frame = _frames.last;
    if (frame.items != items || frame.footnote != inFootnote) return null;
    return frame;
  }

  /// Opens the div [role] says, its fence at [opener], in [into] — the
  /// list the fence line would go into — for a block standing in [items]
  /// items. A column opens in the `columns` div innermost there, ending
  /// the implicit column open in it.
  void open(
    DivRole role,
    SourceSpan opener,
    List<BlockNode> into,
    int items, {
    required bool inFootnote,
    double? width,
  }) {
    switch (role) {
      case DivRole.opensColumns:
        final columns = <ColumnNode>[];
        into.add(
          ColumnsNode(line: opener.line, opener: opener, columns: columns),
        );
        _push(DivKind.columns, items, inFootnote, into, into.length - 1, null);
      case DivRole.opensColumn:
        final frame = _innermost(items, inFootnote);
        final columns = frame?.parent?[frame.index];
        if (columns is! ColumnsNode) {
          // The scanner opens a column only directly in a `columns` div.
          _push(DivKind.other, items, inFootnote, null, -1, into);
          return;
        }
        final children = <BlockNode>[];
        columns.columns.add(
          ColumnNode(
            line: opener.line,
            children: children,
            width: width,
            opener: opener,
          ),
        );
        _push(
          DivKind.column,
          items,
          inFootnote,
          columns.columns,
          columns.columns.length - 1,
          children,
        );
      case DivRole.opensOther:
        _push(DivKind.other, items, inFootnote, null, -1, into);
      case DivRole.closesColumns || DivRole.closesColumn || DivRole.closesOther:
        throw ArgumentError.value(role, 'role', 'does not open');
    }
  }

  void _push(
    DivKind kind,
    int items,
    bool inFootnote,
    List<BlockNode>? parent,
    int index,
    List<BlockNode>? inner,
  ) => _frames.add((
    kind: kind,
    items: items,
    footnote: inFootnote,
    parent: parent,
    index: index,
    inner: inner,
  ));

  /// Closes the innermost div for a block standing in [items] items, its
  /// fence at [closer]; false when none is open there, which the scanner
  /// does not let a closer be.
  bool close(SourceSpan closer, int items, {required bool inFootnote}) {
    final frame = _innermost(items, inFootnote);
    if (frame == null) return false;
    _frames.removeLast();
    final parent = frame.parent;
    if (parent == null) return true;
    final node = parent[frame.index];
    parent[frame.index] = switch (node) {
      ColumnsNode() => node.closedBy(closer),
      ColumnNode() => node.closedBy(closer),
      _ => node,
    };
    return true;
  }
}
