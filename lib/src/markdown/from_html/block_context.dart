/// Where a block goes: inside how many quotes, indented how far.
final class BlockContext {
  /// A context of [quotes] quote marks and [indent] columns of indent.
  const new({this.quotes = 0, this.indent = 0});

  /// The quote marks every line carries.
  final int quotes;

  /// The columns every line is indented by, after the quote marks.
  final int indent;

  /// This context, one quote deeper.
  BlockContext quoted() => BlockContext(quotes: quotes + 1, indent: indent);

  /// This context, [by] columns further in.
  BlockContext indented(int by) =>
      BlockContext(quotes: quotes, indent: indent + by);

  /// [block] with this context's quote marks and indent on every line.
  String wrap(String block) {
    if (quotes == 0 && indent == 0) return block;
    final prefix = '${'> ' * quotes}${' ' * indent}';
    return block.split('\n').map((line) => '$prefix$line').join('\n');
  }
}
