/// The looks a flowchart's statements give its nodes and subgraphs:
/// `style`, `classDef`, `class` and the `:::class` shorthand.
library;

import 'package:niman/src/diagrams/flow_node_style.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';

/// Gathers the look statements while a flowchart is parsed, and says what
/// each node and subgraph looks like once it is.
///
/// A statement may come before or after what it names — a class used
/// before its `classDef`, a `style` for a node written further down — so
/// nothing is resolved until the whole source has been read. As in
/// Mermaid, a `style` wins over a class, a class assigned later wins over
/// one assigned earlier, and the class `default` lies under every node.
final class FlowLooks {
  /// The look each `style` statement gave, by id.
  final Map<String, FlowNodeStyle> _styles = {};

  /// The look each `classDef` gave a class, by its name.
  final Map<String, FlowNodeStyle> _classes = {};

  /// The classes each id was given, in the order given.
  final Map<String, List<String>> _classesOf = {};

  /// Reads `style <id> <properties>`; [rest] is what follows `style`.
  void style(String rest, int number) {
    final (id, properties) = _split(rest, 'style', number);
    final look = FlowNodeStyle.parse(properties);
    _styles[id] = _styles[id]?.overlaid(look) ?? look;
  }

  /// Reads `classDef <name>[,<name>…] <properties>`; [rest] is what follows
  /// `classDef`.
  void classDef(String rest, int number) {
    final (names, properties) = _split(rest, 'classDef', number);
    final look = FlowNodeStyle.parse(properties);
    for (final name in _list(names)) {
      _classes[name] = _classes[name]?.overlaid(look) ?? look;
    }
  }

  /// Reads `class <id>[,<id>…] <name>[,<name>…]`; [rest] is what follows
  /// `class`.
  void assign(String rest, int number) {
    final (ids, names) = _split(rest, 'class', number);
    for (final id in _list(ids)) {
      for (final name in _list(names)) {
        add(id, name);
      }
    }
  }

  /// Gives [id] the class [name]: a `:::name` after a node.
  void add(String id, String name) {
    if (name.isEmpty) return;
    (_classesOf[id] ??= []).add(name);
  }

  /// What node [id] looks like, or null when nothing styles it.
  FlowNodeStyle? node(String id) => _resolve(id, _classes['default']);

  /// What the box of subgraph [id] looks like, or null when nothing styles
  /// it. The class `default` is the nodes'.
  FlowNodeStyle? subgraph(String id) => _resolve(id, null);

  FlowNodeStyle? _resolve(String id, FlowNodeStyle? base) {
    var look = base;
    for (final name in _classesOf[id] ?? const <String>[]) {
      final style = _classes[name];
      if (style != null) look = look?.overlaid(style) ?? style;
    }
    final own = _styles[id];
    if (own != null) look = look?.overlaid(own) ?? own;
    return look;
  }

  /// [rest] split at its first space into what the statement names and
  /// what it gives them; a statement missing either is an error.
  static (String, String) _split(String rest, String keyword, int number) {
    final text = rest.trim();
    final space = text.indexOf(RegExp(r'\s'));
    final tail = space < 0 ? '' : text.substring(space + 1).trim();
    if (tail.isEmpty) {
      throw MermaidParseException(
        number,
        text.isEmpty
            ? 'expected what "$keyword" applies to'
            : 'expected what "$keyword $text" gives',
      );
    }
    return (text.substring(0, space), tail);
  }

  /// The names of a comma-separated list, spaces round them trimmed.
  static Iterable<String> _list(String text) =>
      text.split(',').map((name) => name.trim()).where((n) => n.isNotEmpty);
}
