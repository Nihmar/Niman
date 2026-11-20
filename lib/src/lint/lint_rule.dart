/// The Markdown rules the corrector applies (#72).
///
/// There is no checker UI: the rules are the tidy's own switches
/// (`formatMarkdown`), applied when a note is closed with "Tidy the
/// Markdown on close" on and by the "Tidy the Markdown" command. Each rule
/// is a
/// branch in that one pass rather than a pass of its own, so a note is
/// read and written once however many rules run.
library;

/// One rule, by the id its setting is stored under.
enum LintRule {
  /// The blank lines between a list's items go: lists are written tight.
  tightLists('tight-lists'),

  /// A task box is `[ ]` or `[x]`, with one space before its text.
  taskMarker('task-marker'),

  /// A list's marker is followed by exactly one space, and the item's own
  /// lines follow the text where the marker left it.
  listSpacing('list-spacing'),

  /// A fenced code block ends with a closing fence.
  closingFence('closing-fence'),

  /// A fence's language is the first word of its info string, not Pandoc's
  /// `{.lang}` class.
  fenceLanguage('fence-language'),

  /// A list item's text wrapped over several lines is written on one
  /// (#549).
  joinWrappedItems('join-wrapped-items'),

  /// A paragraph outside a list — a note's own, a quote's, a footnote's —
  /// wrapped over several lines is written on one. With
  /// [splitParagraphLines] on, the note's own and a footnote's lines are
  /// split instead, and only a quote's are joined.
  joinParagraphLines('join-paragraph-lines'),

  /// Each line of a paragraph outside a list and a quote — a note's own, a
  /// footnote's — is a paragraph of its own, a blank line before it: text
  /// pasted with its paragraphs one per line reads as it was written.
  splitParagraphLines('split-paragraph-lines'),

  /// A line that goes on with a paragraph after a hard break — a book
  /// whose every line ends in two spaces — is a paragraph of its own, its
  /// break dropped. Off unless a library turns it on: elsewhere a hard
  /// break is the line break its writer asked for, in a poem or an
  /// address.
  hardBreaksAsParagraphs(_hardBreaksAsParagraphs, onByDefault: false);

  new(this.id, {this.onByDefault = true});

  /// The id the rule is stored and enabled under.
  final String id;

  /// Whether the rule runs in a library that never chose: every rule but
  /// [hardBreaksAsParagraphs].
  final bool onByDefault;

  static const String _hardBreaksAsParagraphs = 'hard-breaks-as-paragraphs';

  /// Every rule, in the order the settings list them.
  static final Set<LintRule> all = Set<LintRule>.unmodifiable(LintRule.values);

  /// The rules a library that never chose runs.
  static final Set<LintRule> defaults = Set<LintRule>.unmodifiable({
    for (final rule in LintRule.values)
      if (rule.onByDefault) rule,
  });

  /// The ids of the rules that are off until a library turns them on: what
  /// a library that never chose has turned off.
  static const Set<String> offByDefaultIds = {_hardBreaksAsParagraphs};
}
