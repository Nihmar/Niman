/// The page's blocks as they come, with the line each one starts on.
final class MarkdownBlocks {
  final StringBuffer _out = StringBuffer();
  int _line = 0;
  final List<String> _pending = <String>[];

  /// Where each element with an id begins.
  final Map<String, int> anchors = <String, int>{};

  /// The Markdown so far.
  String get text => _out.toString();

  /// Adds [block], a blank line from the one before it; the line it starts
  /// on.
  int add(String block) {
    if (_out.isNotEmpty) {
      _out.write('\n\n');
      _line += 2;
    }
    final start = _line;
    for (final id in _pending) {
      anchors[id] = _line;
    }
    _pending.clear();
    _out.write(block);
    _line += '\n'.allMatches(block).length;
    return start;
  }

  /// Adds [block], which holds [inner]'s blocks from its line [lineOffset]
  /// on, one line to a line: the ids [inner] noted are this page's too.
  void addHolding(String block, MarkdownBlocks inner, {int lineOffset = 0}) {
    final start = add(block);
    inner.anchors.forEach((id, line) {
      anchors.putIfAbsent(id, () => start + lineOffset + line);
    });
  }

  /// Notes [id] as starting where the next block does.
  void anchor(String id) {
    if (!anchors.containsKey(id)) _pending.add(id);
  }
}
