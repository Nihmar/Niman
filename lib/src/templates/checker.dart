/// The syntax checker for the template placeholder language (T-TPL-09).
///
/// [checkTemplateSyntax] reads a template and reports what the engine
/// would not answer: an opening brace pair nothing closes, a placeholder or
/// a filter it does not know, a date format holding something that is not a
/// token, a filter argument it cannot read, and a filter where the engine
/// does not apply it (a date move after a text filter, a filter on the
/// caret). The vocabulary it checks against — the placeholder names, the
/// filter names and the date-format tokens — is read from `engine.dart`
/// rather than copied, so a name the engine learns is a name the checker
/// already knows; and so are the rules: whether a filter is one is asked of
/// `templateTextFilter` and `templateDateMove`, the functions the engine
/// applies, and how far a pipeline moves a date of `templateLeadingMoves`.
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
  /// The braces: an opening with nothing closing it, or a placeholder with
  /// no name in it.
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
    required this.problem,
    this.parameters = const <String>[],
    this.suggestion,
  });

  /// Where the offending text starts in the checked source.
  final int offset;

  /// How long the offending text is: a whole `{{…}}`, or the braces of
  /// one that never closes.
  final int length;

  /// Which of the three families the mistake belongs to.
  final TemplateSyntaxErrorKind kind;

  /// What is wrong, as the checker names it — see [TemplateProblem].
  final TemplateProblem problem;

  /// The names [problem] carries, in the order its doc lists them.
  ///
  /// They are code: a placeholder or a filter as it was written, a date
  /// token, a date format. The sentence around them is the hint's to
  /// write, in the language the app speaks.
  final List<String> parameters;

  /// The corrected text for this error's span — see the library doc for
  /// when there is one and when there deliberately is not.
  final String? suggestion;

  /// One past the last character of the offending text.
  int get end => offset + length;

  @override
  String toString() =>
      'TemplateSyntaxError(${kind.name}/${problem.name} at $offset+$length)'
      '${parameters.isEmpty ? '' : ': ${parameters.join(', ')}'}'
      '${suggestion == null ? '' : ' → $suggestion'}';

  @override
  bool operator ==(Object other) =>
      other is TemplateSyntaxError &&
      other.offset == offset &&
      other.length == length &&
      other.kind == kind &&
      other.problem == problem &&
      _sameWords(other.parameters, parameters) &&
      other.suggestion == suggestion;

  @override
  int get hashCode => Object.hash(
    offset,
    length,
    kind,
    problem,
    Object.hashAll(parameters),
    suggestion,
  );

  static bool _sameWords(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// What is wrong, as a name rather than a sentence.
///
/// The checker reports the mistake and the pieces it names; the sentence
/// the person reads is written where the hint is built, in the language the
/// app speaks (T-TPL-09). The pieces are the template's own text, so they
/// stay as written.
enum TemplateProblem {
  /// Braces that open and never close. No pieces.
  unclosedBraces,

  /// A `{{…}}` with no name in it. No pieces.
  emptyPlaceholder,

  /// A placeholder the engine does not answer: the name written.
  unknownPlaceholder,

  /// An `{{ask}}` or `{{choice}}` with no label: the placeholder's name.
  askNoLabel,

  /// A `{{counter}}` with no name to count under: the placeholder's name.
  counterNoName,

  /// A `{{cursor}}` with filters, which the caret has nothing to apply:
  /// the placeholder's name.
  cursorFilters,

  /// A date format whose quote never closes. No pieces.
  unclosedQuote,

  /// A date-format token the engine does not know: the token.
  unknownDateToken,

  /// A `|` with no filter name after it. No pieces.
  emptyFilter,

  /// A date move where the engine reads text: the filter, then the
  /// placeholders that take a move.
  dateMove,

  /// A `+…`/`-…` filter that is not a count and a unit: the filter.
  notADateMove,

  /// A `startof:`/`endof:` the engine does not snap to: the filter, the
  /// units it does snap to, then the unit written.
  snapUnit,

  /// A `pad:` whose width is not a number: the filter, then the argument.
  padWidth,

  /// A filter the engine does not answer: the name written.
  unknownFilter,
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

/// The `{{` of `[from], [to)` — the text between two placeholders, or
/// either end of the file — where no placeholder can be.
///
/// A pair counts only when both of its braces stand inside the window. In
/// `{{{title}}}` the window before the placeholder is the one `{` at 0,
/// and the `{` after it is the placeholder's own: read against the whole
/// source that looks like a `{{` opening a run that ends before it starts.
///
/// Only an opening is reported. A `}}` with nothing open before it is what
/// the engine keeps as ordinary text — LaTeX (`$x^{2^{n}}$`) and inline
/// JSON (`{"a":{"b":1}}`) are full of them — so a checker that marked one
/// would flag templates the engine reads exactly as written.
void _checkBraces(
  String source,
  int from,
  int to,
  List<TemplateSyntaxError> errors,
) {
  bool pairAt(String pair, int i) => i + 2 <= to && source.startsWith(pair, i);

  var i = from;
  while (i < to) {
    if (pairAt('{{', i)) {
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
          problem: TemplateProblem.unclosedBraces,
          suggestion: _closed(source, end, run),
        ),
      );
      i = end;
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
    TemplateProblem problem, {
    List<String> parameters = const <String>[],
    String? suggestion,
  }) => TemplateSyntaxError(
    offset: match.start,
    length: whole.length,
    kind: kind,
    problem: problem,
    parameters: parameters,
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
      at(TemplateSyntaxErrorKind.structural, TemplateProblem.emptyPlaceholder),
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
        TemplateProblem.unknownPlaceholder,
        parameters: <String>[name],
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
          TemplateProblem.askNoLabel,
          parameters: <String>[name],
        ),
      );
    }
  } else if (name == 'counter') {
    if (templateCounterName(argument) == null) {
      errors.add(
        at(
          TemplateSyntaxErrorKind.argument,
          TemplateProblem.counterNoName,
          parameters: <String>[name],
        ),
      );
    }
  } else if (name == 'cursor') {
    if (filters.isNotEmpty) {
      // The caret writes nothing for a filter to work on, so dropping them
      // changes nothing but the placeholder standing.
      errors.add(
        at(
          TemplateSyntaxErrorKind.argument,
          TemplateProblem.cursorFilters,
          parameters: <String>[name],
          suggestion: rebuilt(name, argument, const []),
        ),
      );
    }
    return;
  } else if (argument != null && templateDateFormats.containsKey(name)) {
    for (final fault in _formatFaults(argument)) {
      errors.add(
        at(
          fault.kind,
          fault.problem,
          parameters: fault.parameters,
          suggestion: fault.format == null
              ? null
              : rebuilt(name, fault.format, filters),
        ),
      );
    }
  }

  // The pipeline as the engine reads it: a date placeholder applies its
  // leading moves to the moment, and from the first filter that is not
  // one — on any other placeholder, from the first filter — every filter
  // is a text filter, or the placeholder stands.
  final dated = templateDateFormats.containsKey(name);
  final moves = dated ? templateLeadingMoves(filters) : 0;
  for (var index = moves; index < filters.length; index++) {
    final raw = filters[index];
    if (templateTextFilter(raw) != null) continue;
    final filter = raw.trim();
    final (name: filterName, argument: filterArgument) = parseTemplateFilter(
      raw,
    );

    /// [filters] with this one replaced by [replacement], or dropped.
    String replaced(String? replacement) => rebuilt(name, argument, [
      for (var i = 0; i < filters.length; i++)
        if (i != index) filters[i] else ?replacement,
    ]);

    if (filterName.isEmpty) {
      errors.add(
        at(
          TemplateSyntaxErrorKind.structural,
          TemplateProblem.emptyFilter,
          // A blank one is only a stray pipe; `:x` is an argument whose
          // filter only its author knows.
          suggestion: filter.isEmpty ? replaced(null) : null,
        ),
      );
      continue;
    }

    // A move where the engine reads text: on a placeholder that is not a
    // date, or after a text filter has already made the date a string.
    // Where it was meant to go is the author's call, so nothing is moved.
    if (templateDateMove(raw) != null) {
      errors.add(
        at(
          TemplateSyntaxErrorKind.argument,
          TemplateProblem.dateMove,
          parameters: <String>[filter, templateDateFormats.keys.join(', ')],
        ),
      );
      continue;
    }

    // `+7d`: a move of the date, read by [templateDateMove] rather than by
    // the text filters. A count or a unit that is not one is a mistake with
    // no safe default — the author had a number in mind that is not
    // written.
    if (filterName.startsWith('+') || filterName.startsWith('-')) {
      errors.add(
        at(
          TemplateSyntaxErrorKind.argument,
          TemplateProblem.notADateMove,
          parameters: <String>[filter],
        ),
      );
      continue;
    }

    // `startof:month`: the unit is the whole filter, so a unit the engine
    // does not snap to is one it will not apply.
    if (templateDateFilters.contains(filterName)) {
      final unit = (filterArgument ?? '').trim().toLowerCase();
      errors.add(
        at(
          TemplateSyntaxErrorKind.argument,
          TemplateProblem.snapUnit,
          parameters: <String>[filterName, templateDateUnits.join(', '), unit],
        ),
      );
      continue;
    }

    if (templateTextFilters.contains(filterName)) {
      // Only `pad` refuses an argument. The issue asks for `pad:3` here; a
      // width is a number only its author knows, so the checker reports
      // and suggests nothing.
      errors.add(
        at(
          TemplateSyntaxErrorKind.argument,
          TemplateProblem.padWidth,
          parameters: <String>[filterName, filterArgument ?? ''],
        ),
      );
      continue;
    }

    // A snap is a name to suggest only where a move would be read.
    final closest = _closest(filterName, {
      ...templateTextFilters,
      if (dated && index == moves) ...templateDateFilters,
    });
    errors.add(
      at(
        TemplateSyntaxErrorKind.unknown,
        TemplateProblem.unknownFilter,
        parameters: <String>[filterName],
        suggestion: closest == null
            ? null
            : replaced(
                closest + (filterArgument == null ? '' : ':$filterArgument'),
              ),
      ),
    );
  }
}

/// One thing wrong with a date format: which family the mistake belongs
/// to, what it is, and the format with it corrected — null when no
/// correction is safe.
typedef _FormatFault = ({
  TemplateSyntaxErrorKind kind,
  TemplateProblem problem,
  List<String> parameters,
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
          problem: TemplateProblem.unclosedQuote,
          parameters: const <String>[],
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
    problem: TemplateProblem.unknownDateToken,
    parameters: <String>[run],
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
