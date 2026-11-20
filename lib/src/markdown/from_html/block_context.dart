/// Where a block goes: indented how far.
///
/// A quote is not part of it: a quote's blocks are written on their own and
/// quoted as one, so that its blank lines carry the quote mark.
final class BlockContext {
  /// A context of [indent] columns of indent.
  const new({this.indent = 0});

  /// The columns every line is indented by.
  final int indent;

  /// This context, [by] columns further in.
  BlockContext indented(int by) => BlockContext(indent: indent + by);

  /// [block] with this context's indent on every line.
  String wrap(String block) {
    if (indent == 0) return block;
    final prefix = ' ' * indent;
    return block.split('\n').map((line) => '$prefix$line').join('\n');
  }
}
