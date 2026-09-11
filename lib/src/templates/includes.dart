/// `{{include:…}}` — one template pasted into another (T-TPL-06).
///
/// A library that keeps ten bug templates should keep one reproduction
/// checklist, not ten copies of it. `{{include:_repro}}` pastes another
/// template's text where it stands, and it happens *before* anything else
/// runs: the pasted text is then read like the rest of the file, so its
/// own placeholders are substituted and its own `{{ask:…}}` fields are
/// collected into the same form.
///
/// An include that cannot be pasted leaves its placeholder standing with
/// the reason beside it. That is the same bargain the rest of the engine
/// makes — a mistake ends up visible in the created note rather than
/// eating a line — and it is what keeps a template that includes itself
/// from being a stack overflow.
library;

import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/ui/strings.dart';

/// How deep includes may nest before the chain is called a mistake.
const int maxIncludeDepth = 5;

/// Resolves the path an `{{include:…}}` was written with.
///
/// Returns the template's text *and* the path it resolved to — the path
/// is what cycle detection compares, so two spellings of one template
/// cannot loop past each other.
typedef IncludeResolver = Future<({String path, String text})?> Function(
  String written,
);

/// [source] with every `{{include:…}}` replaced by what it names.
///
/// [sourcePath] is the template being expanded, when it is known; naming
/// it is what lets a template that includes itself be caught on the first
/// step rather than the fifth.
Future<String> expandTemplateIncludes(
  String source, {
  required IncludeResolver resolve,
  String? sourcePath,
  int maxDepth = maxIncludeDepth,
}) => _expand(source, resolve, {?sourcePath}, maxDepth);

Future<String> _expand(
  String source,
  IncludeResolver resolve,
  Set<String> open,
  int depthLeft,
) async {
  final out = StringBuffer();
  var cursor = 0;
  for (final match in templatePlaceholder.allMatches(source)) {
    if (parsePlaceholder(match.group(1)!).name != 'include') continue;
    out.write(source.substring(cursor, match.start));
    cursor = match.end;
    final whole = match.group(0)!;
    // The whole argument is the path: an include takes no filters, and
    // a path may hold spaces and slashes.
    final written = _writtenPath(match.group(1)!);
    if (written.isEmpty) {
      // `{{include:}}` names nothing; it stands, like any other typo.
      out.write(whole);
      continue;
    }
    if (depthLeft <= 0) {
      out.write('$whole ${AppStrings.includeTooDeep(written)}');
      continue;
    }
    final found = await resolve(written);
    if (found == null) {
      out.write('$whole ${AppStrings.includeMissing(written)}');
      continue;
    }
    if (open.contains(found.path)) {
      out.write('$whole ${AppStrings.includeCycle(written)}');
      continue;
    }
    out.write(
      await _expand(found.text, resolve, {...open, found.path}, depthLeft - 1),
    );
  }
  out.write(source.substring(cursor));
  return out.toString();
}

/// The path out of an `include:…` body, pipes and all: a file may be
/// called `A|B`, and an include has no filters to confuse it with.
String _writtenPath(String body) {
  final colon = body.indexOf(':');
  return colon < 0 ? '' : body.substring(colon + 1).trim();
}
