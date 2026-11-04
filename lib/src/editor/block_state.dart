import 'package:meta/meta.dart';
import 'package:niman/src/editor/code_fence.dart';

/// The carried block state.
@immutable
final class BlockState {
  /// Creates a block state: inside [fence], display maths, the frontmatter,
  /// or none of them.
  const new({this.fence, this.inMath = false, this.inFrontmatter = false});

  /// The fenced code block the line is inside, or null.
  final CodeFence? fence;

  /// Whether the line is inside a display-math block.
  final bool inMath;

  /// Whether the line is inside the leading frontmatter block.
  final bool inFrontmatter;

  /// The state at the top of a note: outside every block.
  static const BlockState initial = BlockState();

  @override
  bool operator ==(Object other) {
    if (other is! BlockState) return false;
    final f = fence;
    final o = other.fence;
    return (f == null
            ? o == null
            : o != null && o.char == f.char && o.len == f.len) &&
        inMath == other.inMath &&
        inFrontmatter == other.inFrontmatter;
  }

  @override
  int get hashCode {
    final f = fence;
    return Object.hash(
      f == null ? -1 : f.char,
      f == null ? -2 : f.len,
      inMath,
      inFrontmatter,
    );
  }
}
