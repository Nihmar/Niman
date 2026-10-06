/// A link reference definition's lines, as the read view's parser reads
/// them: `package:markdown`'s `LinkReferenceDefinitionSyntax`, whose
/// `LinkParser` reads one definition off the lines of a paragraph that
/// starts with `[` (`docs/dev/block-tree.md`).
library;

/// Whether a line starts a link reference definition, and how many lines
/// it takes.
abstract final class LinkDefinitionSyntax {
  /// Whether [text] may open a definition: `[` up to three spaces in. Only
  /// where no paragraph is open — a definition cannot interrupt one.
  static bool opens(String text) {
    var at = 0;
    while (at < 3 && at < text.length && text.codeUnitAt(at) == 0x20) {
      at++;
    }
    return at < text.length && text.codeUnitAt(at) == 0x5B;
  }

  /// How many lines the definition opening on [first] takes — the lines
  /// after it asked of [more] one at a time, null past the paragraph's end —
  /// or 0 when they hold none and are a paragraph.
  ///
  /// The package's `LinkParser.parseDefinition`, read the same way: a
  /// label, `:`, a destination (on the next line if need be), then a title
  /// after white space; the definition ends where its last part does, and
  /// a title that fails on a line of its own leaves the definition ending
  /// at its destination. Lines are asked for only when the reading runs
  /// out of them, so a paragraph that only starts like a definition —
  /// `[a link](…) and text` — costs its first line.
  static int linesOf(String first, String? Function() more) =>
      _Reader(first, more)._definition();
}

/// One reading of a definition, over lines asked for as it goes.
final class _Reader {
  new(this._source, this._more);

  String _source;
  final String? Function() _more;
  int _pos = 0;
  bool _exhausted = false;

  /// Whether the text is read to its end, every line there is asked for.
  bool get _isDone {
    while (_pos >= _source.length && !_exhausted) {
      final line = _more();
      if (line == null) {
        _exhausted = true;
      } else {
        _source = '$_source\n$line';
      }
    }
    return _pos >= _source.length;
  }

  int get _char => _source.codeUnitAt(_pos);

  static const int _tab = 0x09;
  static const int _lf = 0x0A;
  static const int _vt = 0x0B;
  static const int _ff = 0x0C;
  static const int _cr = 0x0D;
  static const int _space = 0x20;
  static const int _quote = 0x22;
  static const int _apostrophe = 0x27;
  static const int _lparen = 0x28;
  static const int _rparen = 0x29;
  static const int _colon = 0x3A;
  static const int _lt = 0x3C;
  static const int _gt = 0x3E;
  static const int _lbracket = 0x5B;
  static const int _backslash = 0x5C;
  static const int _rbracket = 0x5D;

  int _skipWhitespace({bool multiLine = false}) {
    var count = 0;
    while (!_isDone) {
      final char = _char;
      if (char != _space &&
          char != _tab &&
          char != _vt &&
          char != _cr &&
          char != _ff &&
          !(multiLine && char == _lf)) {
        return count;
      }
      count++;
      _pos++;
    }
    return count;
  }

  /// The lines the definition takes, or 0.
  int _definition() {
    if (!_label() || _isDone || _char != _colon) return 0;
    _pos++;
    if (!_destination()) return 0;
    var whitespace = _skipWhitespace();
    if (_isDone) return _consumed();
    final multiline = _char == _lf;
    whitespace += _skipWhitespace(multiLine: true);
    if (whitespace == 0 || _isDone) return _isDone ? _consumed() : 0;
    final titled = _title();
    if (!titled && !multiline) return 0;
    if (titled) {
      _skipWhitespace();
      if (!_isDone && _char != _lf && !multiline) return 0;
    }
    return _consumed();
  }

  /// The lines read up to where the definition ends: the line it ends on,
  /// unless something but white space follows there.
  int _consumed() {
    final before = _source.substring(0, _pos.clamp(0, _source.length));
    final lines = '\n'.allMatches(before).length + 1;
    final rest = _source.substring(_pos.clamp(0, _source.length));
    final end = rest.indexOf('\n');
    final tail = end < 0 ? rest : rest.substring(0, end);
    return tail.trim().isEmpty ? lines : lines - 1;
  }

  bool _label() {
    _skipWhitespace(multiLine: true);
    // Two characters at least: `[` and `]`.
    if (_isDone || _pos + 1 >= _source.length && _exhaustedAfter(1)) {
      return false;
    }
    if (_char != _lbracket) return false;
    _pos++;
    final start = _pos;
    var loops = 999;
    while (true) {
      if (loops-- < 0) return false;
      if (_isDone) return false;
      final char = _char;
      if (char == _backslash) {
        _pos++;
      } else if (char == _lbracket) {
        return false;
      } else if (char == _rbracket) {
        break;
      }
      _pos++;
      if (_isDone) return false;
    }
    if (_source.substring(start, _pos).trim().isEmpty) return false;
    _pos++;
    return true;
  }

  /// Whether fewer than [count] characters follow the current one, every
  /// line there is asked for.
  bool _exhaustedAfter(int count) {
    while (_pos + count >= _source.length && !_exhausted) {
      final line = _more();
      if (line == null) {
        _exhausted = true;
      } else {
        _source = '$_source\n$line';
      }
    }
    return _pos + count >= _source.length;
  }

  bool _destination() {
    _skipWhitespace(multiLine: true);
    if (_isDone) return false;
    return _char == _lt ? _bracketedDestination() : _bareDestination();
  }

  bool _bracketedDestination() {
    _pos++;
    while (true) {
      if (_isDone) return false;
      final char = _char;
      if (char == _backslash) {
        _pos++;
      } else if (char == _lf || char == _cr || char == _ff) {
        return false;
      } else if (char == _gt) {
        break;
      }
      _pos++;
      if (_isDone) return false;
    }
    _pos++;
    return true;
  }

  bool _bareDestination() {
    var parens = 0;
    while (true) {
      final char = _char;
      if (char == _backslash) {
        _pos++;
      } else if (char == _space || char == _lf || char == _cr || char == _ff) {
        break;
      } else if (char == _lparen) {
        parens++;
      } else if (char == _rparen) {
        parens--;
        if (parens == 0) {
          _pos++;
          break;
        }
      }
      _pos++;
      if (_isDone) break;
    }
    return true;
  }

  bool _title() {
    final open = _char;
    if (open != _apostrophe && open != _quote && open != _lparen) {
      return false;
    }
    final close = open == _lparen ? _rparen : open;
    _pos++;
    if (_isDone) return false;
    while (true) {
      final char = _char;
      if (char == _backslash) {
        _pos++;
      } else if (char == close) {
        break;
      }
      _pos++;
      if (_isDone) return false;
    }
    _pos++;
    return true;
  }
}
