/// The grammars Niman adds to the highlighter's own (#1152): fences whose
/// language is Niman's, not a programming language's.
library;

import 'package:highlight/highlight.dart' show Mode, highlight;

bool _registered = false;

/// Teaches the highlighter the languages of Niman's own fences, once: the
/// read view, `live` and the export all colour through the one `highlight`,
/// so a fence is the same colours in all three.
void ensureAppGrammars() {
  if (_registered) return;
  _registered = true;
  highlight.registerLanguage('todo', _todoBlock);
}

/// A `todo` block: a known key is an attribute, any other first word of a line
/// is a key the block does not know, in the colour of a deletion, and what
/// follows a colon is a value, its dates and its `[[Note]]` set apart.
///
/// No lookahead for the colon: the highlighter tests a mode's `begin` on the
/// text it matched alone, where a lookahead never holds.
final Mode _todoBlock = Mode(
  case_insensitive: true,
  contains: <Mode>[
    Mode(
      className: 'attr',
      begin: r'^[ \t]*(?:link|project|context|tag|due|priority|done|sort)\b',
    ),
    Mode(className: 'deletion', begin: r'^[ \t]*[A-Za-z_][\w-]*'),
    Mode(
      className: 'string',
      begin: ':',
      end: r'$',
      excludeBegin: true,
      relevance: 0,
      contains: <Mode>[
        Mode(className: 'link', begin: r'\[\[', end: r'\]\]'),
        Mode(
          className: 'number',
          begin: r'\d{4}-\d{2}-\d{2}|<=\s*\+\d+d',
          relevance: 0,
        ),
      ],
    ),
  ],
);
