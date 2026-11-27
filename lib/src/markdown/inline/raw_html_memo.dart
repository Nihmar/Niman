/// What a parse has learnt about the closers and the NULs of its text, so
/// that a text of unclosed `<?` or `<![CDATA[` openers stays linear: each
/// is looked for once going forward, not from every opener.
final class RawHtmlMemo {
  /// A memo for the parse of [text].
  new(this.text);

  /// The text parsed.
  final String text;

  int _nul = -2;
  int _pi = -2;
  int _cdata = -2;

  /// Where the first NUL at or after [from] is, or -1.
  int nulFrom(int from) => _nul = _next(_nul, '\x00', from);

  /// Where the first `?>` at or after [from] is, or -1.
  int piCloseFrom(int from) => _pi = _next(_pi, '?>', from);

  /// Where the first `]]>` at or after [from] is, or -1.
  int cdataCloseFrom(int from) => _cdata = _next(_cdata, ']]>', from);

  /// [pattern]'s first place at or after [from], given [last], the answer
  /// to an earlier, lower [from]: still the answer while it is not behind
  /// [from], and none stays none. Asked for rising positions, the text is
  /// read once.
  int _next(int last, String pattern, int from) {
    if (last == -1 || last >= from) return last;
    return text.indexOf(pattern, from);
  }
}
