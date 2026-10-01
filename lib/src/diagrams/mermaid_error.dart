/// The syntax error a Mermaid diagram can fail with (#530).
///
/// A diagram that does not parse leaves the block as source, with the
/// offending line underlined and this message under it ("Line 4: expected
/// \"-->\" after \"--\""). The exception carries the line and the message
/// separately so the read view can point at the line and the live view can
/// move the caret to it.
library;

/// A Mermaid source that does not parse.
final class MermaidParseException implements Exception {
  /// Creates the error, with a 1-based [line] and a human-readable
  /// [message].
  const new(this.line, this.message);

  /// The 1-based line the error is on, counting from the first line of the
  /// fence's content (the line after the opening fence is line 1).
  final int line;

  /// What was expected and what was found.
  final String message;

  @override
  String toString() => 'Line $line: $message';
}
