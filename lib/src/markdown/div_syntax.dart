/// Pandoc's fenced divs, as far as a note's columns read them (#729,
/// `docs/records/note-columns.md`): `:::: columns`, `::: {.column
/// width="40%"}`, and the bare `:::` that closes the innermost one.
library;

import 'package:niman/src/markdown/line_state.dart';

/// What a fence line opens: the kind its classes name, and the share a
/// column's `width` asks for.
typedef DivOpening = ({DivKind kind, double? width});

/// The fence lines of a fenced div.
abstract final class DivSyntax {
  /// The class that lays its divs side by side.
  static const String columnsClass = 'columns';

  /// The class of one of them.
  static const String columnClass = 'column';

  /// Whether [text] could be a fence line at all: a colon at its
  /// container's margin. A fence line stands there, with no indent, as
  /// Pandoc reads one — ` ::: column` is text to it. One comparison for a
  /// line that is not, which is every line of a note without divs.
  static bool _colonFirst(String text) =>
      text.isNotEmpty && text.codeUnitAt(0) == 0x3A;

  /// Whether [text] closes a div: three colons or more at its container's
  /// margin, and nothing else. It closes the innermost div whatever its
  /// length, as Pandoc reads it.
  static bool closes(String text) {
    if (!_colonFirst(text)) return false;
    final trimmed = text.trimRight();
    if (trimmed.length < 3) return false;
    for (var at = 0; at < trimmed.length; at++) {
      if (trimmed.codeUnitAt(at) != 0x3A) return false;
    }
    return true;
  }

  /// What [text] opens, when it is a div's opener — three colons or more
  /// at its container's margin, then a class word or `{…}` attributes, and
  /// optionally more colons — or null.
  ///
  /// [DivKind.columns] for the class `columns`, [DivKind.column] for
  /// `column`, [DivKind.other] for any other: whether an opener of that
  /// kind counts where it stands is the scan's to say.
  static DivOpening? opening(String text) {
    if (!_colonFirst(text)) return null;
    final match = _opener.firstMatch(text);
    if (match == null) return null;
    final braced = match.group(1);
    final classes = braced == null
        ? <String>[match.group(2)!]
        : _classesOf(braced);
    final kind = classes.contains(columnsClass)
        ? DivKind.columns
        : classes.contains(columnClass)
        ? DivKind.column
        : DivKind.other;
    return (
      kind: kind,
      width: braced == null ? null : _width(_attribute(braced, 'width')),
    );
  }

  /// The attributes of an opener, as written: what follows its colons,
  /// trimmed of its trailing ones. Null when [text] opens nothing.
  static String? attributesOf(String text) {
    if (!_colonFirst(text)) return null;
    final match = _opener.firstMatch(text);
    if (match == null) return null;
    return match.group(1) == null ? match.group(2) : '{${match.group(1)}}';
  }

  /// An opener: colons, a class word or a braced attribute list, and
  /// optional closing colons.
  static final RegExp _opener = RegExp(
    r'^:{3,}[ \t]*(?:\{([^{}]*)\}|([^\s{}:]+))[ \t]*:*[ \t]*$',
  );

  /// The classes in a braced attribute list: its `.name` words.
  static List<String> _classesOf(String braced) => [
    for (final match in _token.allMatches(braced))
      if (match.group(0)!.startsWith('.')) match.group(0)!.substring(1),
  ];

  /// The value of [key] in a braced attribute list, its quotes off, or
  /// null.
  static String? _attribute(String braced, String key) {
    for (final match in _token.allMatches(braced)) {
      final token = match.group(0)!;
      final equals = token.indexOf('=');
      if (equals <= 0 || token.substring(0, equals) != key) continue;
      var value = token.substring(equals + 1);
      if (value.length >= 2 &&
          (value.startsWith('"') && value.endsWith('"') ||
              value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      return value;
    }
    return null;
  }

  /// One attribute: a class, an id, or a key with a value, quoted or not.
  static final RegExp _token = RegExp(
    r'''[^\s=]+="[^"]*"|[^\s=]+='[^']*'|[^\s]+''',
  );

  /// A width as a share of the row: a percentage above 0, or null for
  /// anything else (`300px`, `40`), which shares like no width.
  static double? _width(String? value) {
    if (value == null || !value.endsWith('%')) return null;
    final share = double.tryParse(value.substring(0, value.length - 1).trim());
    if (share == null || share.isNaN || share <= 0) return null;
    return share;
  }

  /// Whether [text] is a fence line: an opener or a closer.
  static bool isFence(String text) => closes(text) || opening(text) != null;
}
