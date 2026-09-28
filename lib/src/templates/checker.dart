/// The syntax checker for the template placeholder language (T-TPL-09).
///
/// [checkTemplateSyntax] reads a template and reports what the engine
/// would not answer: braces that do not pair up, a placeholder or a
/// filter it does not know, a date format holding something that is not a
/// token, and a filter argument it cannot read. The vocabulary it checks
/// against — the placeholder names, the filter names and the date-format
/// tokens — is read from `engine.dart` rather than copied, so a name the
/// engine learns is a name the checker already knows.
///
/// It reports; it never rewrites. [TemplateSyntaxError.suggestion] is the
/// corrected text for the error's span, ready to replace
/// `source.substring(error.offset, error.end)`, and it is null whenever
/// the correction is not deterministic and safe:
///
/// * a written name that is within [templateSuggestionDistance] edits of
///   exactly one known one is corrected to it (`titlex` → `title`,
///   `upperr` → `upper`, `YYYYY` → `YYYY`);
/// * two known names equally close are an ambiguity, and nothing is
///   suggested;
/// * an argument a filter cannot read — a `pad:` width that is not a
///   number, a move whose count is not — has no value a checker could
///   guess, so the error stands alone;
/// * an unclosed `{{` is closed only when what follows it is a placeholder
///   body and the file ends there; in the middle of a note there is no end
///   the checker can point at, and it says nothing rather than guessing
///   one.
///
/// One placeholder with two mistakes gets two errors, each carrying the
/// fix for itself alone.
///
/// Out of scope, because another parser owns each: Markdown, the
/// frontmatter, and the `niman:` directives block (`directives.dart`).
///
/// The checker is a pure function of the text — no I/O, no context, one
/// pass over the source — so it can be asked on every keystroke from the
/// editor, debounced like the spell checker. Nothing calls it yet: when it
/// runs, and how a mistake is shown, is the UI half of the issue and is
/// not part of this one.
library;

import 'dart:math';

import 'package:meta/meta.dart';
import 'package:niman/src/templates/engine.dart';

/// How far a written name may be from a known one — insertions, deletions
/// and substitutions counted — for the checker to call it a typo of it.
///
/// Beyond this the correction would be a guess about what the author
/// meant, and the checker reports the unknown name alone.
const int templateSuggestionDistance = 2;

/// What kind of mistake a [TemplateSyntaxError] is.
enum TemplateSyntaxErrorKind {
  /// The braces: an opening with nothing closing it, a closing with
  /// nothing open, or a placeholder with no name in it.
  structural,

  /// A name the engine does not answer: a placeholder, a filter, or a
  /// date-format token.
  unknown,

  /// A name the engine knows, used with an argument it cannot read.
  argument,
}

/// One mistake in a template, and the fix for it when there is one.
@immutable
final class TemplateSyntaxError {
  /// Creates an error over `[offset], [offset] + [length)`.
  const new({
    required this.offset,
    required this.length,
    required this.kind,
    required this.message,
    this.suggestion,
  });

  /// Where the offending text starts in the checked source.
  final int offset;

  /// How long the offending text is: a whole `{{…}}`, or the braces of
  /// one that never closes.
  final int length;

  /// Which of the three families the mistake belongs to.
  final TemplateSyntaxErrorKind kind;

  /// What is wrong, in one sentence, for the person who wrote it.
  final String message;

  /// The corrected text for this error's span — see the library doc for
  /// when there is one and when there deliberately is not.
  final String? suggestion;

  /// One past the last character of the offending text.
  int get end => offset + length;

  @override
  String toString() =>
      'TemplateSyntaxError(${kind.name} at $offset+$length): $message'
      '${suggestion == null ? '' : ' → $suggestion'}';

  @override
  bool operator ==(Object other) =>
      other is TemplateSyntaxError &&
      other.offset == offset &&
      other.length == length &&
      other.kind == kind &&
      other.message == message &&
      other.suggestion == suggestion;

  @override
  int get hashCode => Object.hash(offset, length, kind, message, suggestion);
}

/// Every syntax mistake in [source], in the order they appear.
///
/// Nothing about the text is changed and nothing outside it is read: the
/// result is a report, and [TemplateSyntaxError.suggestion] is text for a
/// caller to apply if it wants to.
List<TemplateSyntaxError> checkTemplateSyntax(String source) {
  final errors = <TemplateSyntaxError>[];
  var cursor = 0;
  for (final match in templatePlaceholder.allMatches(source)) {
    _checkBraces(source, cursor, match.start, errors);
    _checkPlaceholder(match, errors);
    cursor = match.end;
  }
  _checkBraces(source, cursor, source.length, errors);
  return errors;
}

/// The `{{` and `}}` of `[from], [to)` — the text between two placeholders,
/// or either end of the file — where no placeholder can be.
void _checkBraces(
  String source,
  int from,
  int to,
  List<TemplateSyntaxError> errors,
) {
  var i = from;
  while (i < to) {
    if (source.startsWith('{{', i)) {
      // The run the braces open: up to the next placeholder or the end of
      // the file, without the whitespace that trails it.
      var end = to;
      while (end > i + 2 && _isSpace(source[end - 1])) {
        end--;
      }
      final run = source.substring(i + 2, end);
      errors.add(
        TemplateSyntaxError(
          offset: i,
          length: end - i,
          kind: TemplateSyntaxErrorKind.structural,
          message:
              'unclosed opening braces: nothing closes this '
              'placeholder',
          suggestion: _closed(source, end, run),
        ),
      );
      i = end;
      continue;
    }
    if (source.startsWith('}}', i)) {
      // The engine reads a closing pair with nothing open before it as
      // literal text, so there is nothing to close and nothing to suggest.
      errors.add(
        TemplateSyntaxError(
          offset: i,
          length: 2,
          kind: TemplateSyntaxErrorKind.structural,
          message: 'closing braces with no opening braces before them',
        ),
      );
      i += 2;
      continue;
    }
    i++;
  }
}

/// The corrected text for an unclosed `{{` whose body is [run] and whose
/// run ends at [end] in [source] — `{{run}}` — or null when closing it is
/// not safe.
///
/// Safe means the file ends where the braces do and what stands between
/// them is a placeholder body the engine would answer: `{{title` and
/// `{{time:HH'|'mm` are closed, while a `{{` with a sentence after it, or
/// with an unknown name in it, is reported alone. Only braces are added;
/// no text is moved.
String? _closed(String source, int end, String run) {
  if (end != source.length) return null;
  if (run.isEmpty) return null;
  if (run.contains('{') || run.contains('}')) return null;
  if (run.contains('\n') || run.contains('\r')) return null;
  // A body the checker itself has nothing to say about, braces put back:
  // recursion is one level deep, since this text closes.
  if (checkTemplateSyntax('{{$run}}').isNotEmpty) return null;
  return '{{$run}}';
}

/// The mistakes inside one `{{…}}`: its name, its argument, then its
/// filters in the order they were written.
void _checkPlaceholder(RegExpMatch match, List<TemplateSyntaxError> errors) {
  final whole = match.group(0)!;
  final parsed = parsePlaceholder(match.group(1)!);
  final name = parsed.name;
  final argument = parsed.argument;
  final filters = parsed.filters;

  TemplateSyntaxError at(
    TemplateSyntaxErrorKind kind,
    String message, {
    String? suggestion,
  }) => TemplateSyntaxError(
    offset: match.start,
    length: whole.length,
    kind: kind,
    message: message,
    suggestion: suggestion,
  );

  /// The placeholder as it would read with one piece of it replaced: the
  /// argument and the filters are the ones that were written, so the
  /// suggestion is the one fix the error is about.
  String rebuilt(String name, String? argument, List<String> filters) {
    final out = StringBuffer('{{')..write(name);
    if (argument != null) {
      out
        ..write(':')
        ..write(argument);
    }
    for (final filter in filters) {
      out
        ..write('|')
        ..write(filter);
    }
    return (out..write('}}')).toString();
  }

  if (name.isEmpty) {
    errors.add(
      at(
        TemplateSyntaxErrorKind.structural,
        'empty placeholder: there is no name between the braces',
      ),
    );
    return;
  }

  if (!templatePlaceholderNames.contains(name)) {
    // The name is already folded to lower case by [parsePlaceholder], and
    // so is the vocabulary, so the comparison is case-insensitive: a
    // `{{Titlex}}` gets the same suggestion a `{{titlex}}` does.
    final closest = _closest(name, templatePlaceholderNames);
    errors.add(
      at(
        TemplateSyntaxErrorKind.unknown,
        "unknown placeholder '$name'",
        suggestion: closest == null
            ? null
            : rebuilt(closest, argument, filters),
      ),
    );
  } else if (name == 'ask' || name == 'choice') {
    if (fieldLabel(argument).isEmpty) {
      errors.add(
        at(
          TemplateSyntaxErrorKind.argument,
          "'$name' has no label: it asks nothing, and the placeholder is "
          'left standing',
        ),
      );
    }
  } else if (argument != null && _isDate(name)) {
    for (final fault in _formatFaults(argument)) {
      errors.add(
        at(
          fault.kind,
          fault.message,
          suggestion: fault.format == null
              ? null
              : rebuilt(name, fault.format, filters),
        ),
      );
    }
  }

  for (var index = 0; index < filters.length; index++) {
    final filter = filters[index].trim();
    final colon = filter.indexOf(':');
    final filterName = (colon < 0 ? filter : filter.substring(0, colon))
        .trim()
        .toLowerCase();
    final filterArgument = colon < 0 ? null : filter.substring(colon + 1);
    if (filterName.isEmpty) continue;

    // `+7d`: a move of the date, read by [_moveDate] rather than by the
    // text filters. A count or a unit that is not one is a mistake with no
    // safe default — the author had a number in mind that is not written.
    if (filterName.startsWith('+') || filterName.startsWith('-')) {
      if (!templateDateShift.hasMatch(filter)) {
        errors.add(
          at(
            TemplateSyntaxErrorKind.argument,
            "'$filter' is not a date move: a move is a count and a unit, "
            "like '+7d' or '-1w'",
          ),
        );
      }
      continue;
    }

    // `startof:month`: the unit is the whole filter, so a unit the engine
    // does not snap to is one it will not apply.
    if (templateDateFilters.contains(filterName)) {
      final unit = (filterArgument ?? '').trim().toLowerCase();
      if (!templateDateUnits.contains(unit)) {
        errors.add(
          at(
            TemplateSyntaxErrorKind.argument,
            "'$filterName' snaps to ${templateDateUnits.join(', ')}, not "
            "'$unit'",
          ),
        );
      }
      continue;
    }

    if (templateTextFilters.contains(filterName)) {
      final width = int.tryParse((filterArgument ?? '').trim());
      if (filterName == 'pad' && (width == null || width < 0)) {
        // The issue asks for `pad:3` here; a width is a number only its
        // author knows, so the checker reports and suggests nothing.
        errors.add(
          at(
            TemplateSyntaxErrorKind.argument,
            "'pad' needs a number for its width, and "
            "'${filterArgument ?? ''}' is not one",
          ),
        );
      }
      continue;
    }

    final closest = _closest(filterName, {
      ...templateTextFilters,
      ...templateDateFilters,
    });
    errors.add(
      at(
        TemplateSyntaxErrorKind.unknown,
        "unknown filter '$filterName'",
        suggestion: closest == null
            ? null
            : rebuilt(name, argument, [
                for (var i = 0; i < filters.length; i++)
                  if (i == index)
                    closest + (filterArgument == null ? '' : ':$filterArgument')
                  else
                    filters[i],
              ]),
      ),
    );
  }
}

/// Whether the placeholder called [name] takes a date format.
bool _isDate(String name) => name == 'date' || name == 'time' || name == 'now';

/// One thing wrong with a date format: which family the mistake belongs
/// to, what to say about it, and the format with it corrected — null when
/// no correction is safe.
typedef _FormatFault = ({
  TemplateSyntaxErrorKind kind,
  String message,
  String? format,
});

/// Every fault in [format], read the way [formatDateTime] reads it.
///
/// A run of letters is a mistake only when the format does start a token
/// there: `YYYYY` is `YYYY` plus a stray letter, while `week` and the `T`
/// of an ISO stamp are text the engine prints as written, and a checker
/// that called those mistakes would be shouting at formats that are right.
/// Text between single quotes is skipped, and an unclosed quote ends the
/// walk: everything after it is literal.
List<_FormatFault> _formatFaults(String format) {
  final faults = <_FormatFault>[];
  var i = 0;
  while (i < format.length) {
    if (format[i] == "'") {
      final end = format.indexOf("'", i + 1);
      if (end < 0) {
        faults.add((
          kind: TemplateSyntaxErrorKind.argument,
          message:
              'unclosed quote in the date format: everything after it '
              'is read as ordinary text',
          format: null,
        ));
        return faults;
      }
      i = end + 1;
      continue;
    }
    if (!_isLetter(format[i])) {
      i++;
      continue;
    }
    var end = i;
    while (end < format.length && _isLetter(format[end])) {
      end++;
    }
    final fault = _tokenFault(format, i, end);
    if (fault != null) faults.add(fault);
    i = end;
  }
  return faults;
}

/// The fault in the run of letters at `[start], [end)` of [format], or null
/// when the run reads back as tokens alone, or as text the format does not
/// claim at all.
///
/// A run is a mistake only when a token began it and a known token is
/// close enough to be the one that was meant: `YYYYY` is `YYYY` with a
/// letter too many, while `DDTHH` is a `DD`, the `T` of an ISO stamp and
/// an `HH` as the engine reads them — a run whose closest token is three
/// edits away is text, not a typo, and is left alone.
_FormatFault? _tokenFault(String format, int start, int end) {
  var i = start;
  while (i < end) {
    final token = templateDateTokenAt(format, i);
    if (token == null) break;
    i += token.length;
  }
  // No token at all before the stray letters: the run is literal text.
  if (i == start || i >= end) return null;
  final run = format.substring(start, end);
  final close = templateDateTokens.where(
    (token) => _distance(run, token) <= templateSuggestionDistance,
  );
  if (close.isEmpty) return null;
  final closest = _closest(run, close);
  return (
    kind: TemplateSyntaxErrorKind.unknown,
    message: "unknown date token '$run'",
    format: closest == null ? null : format.replaceRange(start, end, closest),
  );
}

/// The one name in [known] closest to [written], or null when none is
/// within [templateSuggestionDistance] edits of it, or when two are
/// equally close — an ambiguity is not a correction.
///
/// Case-sensitive: `MM` and `mm` are two different date tokens. The
/// placeholder and filter names arrive folded to lower case, like the
/// vocabulary they are compared against.
String? _closest(String written, Iterable<String> known) {
  String? best;
  var closest = templateSuggestionDistance + 1;
  var ties = 0;
  for (final name in known) {
    final distance = _distance(written, name);
    if (distance > templateSuggestionDistance) continue;
    if (distance < closest) {
      best = name;
      closest = distance;
      ties = 1;
    } else if (distance == closest) {
      ties++;
    }
  }
  return best != null && ties == 1 ? best : null;
}

/// The Levenshtein distance between [a] and [b]: how many single-character
/// insertions, deletions and substitutions turn one into the other.
int _distance(String a, String b) {
  if (a == b) return 0;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      current[j] = min(
        min(current[j - 1] + 1, previous[j] + 1),
        previous[j - 1] + cost,
      );
    }
    previous = current;
  }
  return previous[b.length];
}

/// Whether [char] is one of the twenty-six letters a format token is made
/// of. Everything else — a separator, a digit, an accented letter — is
/// literal to the engine, and so it is to the checker.
bool _isLetter(String char) {
  final code = char.codeUnitAt(0);
  return (code >= 0x41 && code <= 0x5a) || (code >= 0x61 && code <= 0x7a);
}

/// Whether [char] is whitespace that may trail an unclosed `{{`.
bool _isSpace(String char) =>
    char == ' ' || char == '\t' || char == '\n' || char == '\r';
