/// The wikilink suggester panel (#475): the small list that drops under the
/// caret while a link is typed.
///
/// It is drawn to `docs/design/wikilink-suggester` — a name and its folder
/// dimmed, a matched run in bold, an alias on a pill when the note was found
/// through one, the keys in a footer. It draws nothing itself: the surface
/// gives it the rows and the selection, and writes the one link that was
/// chosen.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/ui/strings.dart';

/// What the panel is listing.
enum WikilinkPanelKind {
  /// The library's notes, after `[[`.
  notes,

  /// A note's headings, after `#`.
  headings,

  /// A book's place forms, after `#` on a PDF or an EPUB.
  book,
}

/// The width the panel is drawn at (the drawing's 300).
const double wikilinkPanelWidth = 300;

/// The height of one list row, under a mouse.
const double wikilinkPanelRowHeight = 26;

/// The height of one list row on a touch screen: a row is tapped there, and
/// 26 pixels is less than a fingertip.
const double wikilinkPanelTouchRowHeight = 40;

/// The panel's height at most, for the caller that flips it above the caret
/// when there is no room below.
double wikilinkPanelHeight(
  int rows,
  WikilinkPanelKind kind, {
  bool hasBodyNote = false,
  double rowHeight = wikilinkPanelRowHeight,
  bool keys = true,
}) {
  final body = rows == 0 ? 58.0 : rows * rowHeight;
  final caption = kind == WikilinkPanelKind.notes ? 0.0 : 25.0;
  final note = hasBodyNote ? 40.0 : 0.0;
  final footer = keys ? 27.0 : 0.0;
  return caption + body + note + footer;
}

/// The rows and the keys, drawn where the caret is.
final class WikilinkPanel extends StatelessWidget {
  /// Draws [entries] with [selected] highlighted, filtered to [query].
  ///
  /// [named] is the note (or book) named before `#`, shown in the caption;
  /// empty means the note being edited.
  const new({
    required this.kind,
    required this.entries,
    required this.selected,
    required this.query,
    this.named = '',
    this.onPick,
    this.keys = true,
    this.rowHeight = wikilinkPanelRowHeight,
    super.key,
  });

  /// What is being listed.
  final WikilinkPanelKind kind;

  /// The rows, best match first.
  final List<SuggestEntry> entries;

  /// Which row is highlighted.
  final int selected;

  /// What was typed into the link, for the bold run and the empty words.
  final String query;

  /// The note (or book) named before `#`; empty means the note being edited.
  final String named;

  /// Chooses the row at the given index, as Enter does on the selected one:
  /// a tap or a click on a row. Null leaves the rows to the keys.
  final ValueChanged<int>? onPick;

  /// Whether the footer names the keys: only where there is a keyboard to
  /// press them — a phone without one is not told about Tab and Esc.
  final bool keys;

  /// The height of one row: taller on a touch screen, where it is tapped.
  final double rowHeight;

  /// Whether the book form carries its explaining note.
  bool get _hasBodyNote => kind == WikilinkPanelKind.book && entries.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('wikilink-panel'),
      width: wikilinkPanelWidth,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (kind != WikilinkPanelKind.notes) _caption(context),
            if (entries.isEmpty)
              _empty(context)
            else
              for (var i = 0; i < entries.length; i++)
                _row(context, i, selected: i == selected),
            if (_hasBodyNote) _bodyNote(context),
            if (keys) _footer(context),
          ],
        ),
      ),
    );
  }

  /// `Headings in <b>Editing</b>` / `Places in <b>Dune.pdf</b>`.
  ///
  /// The sentence is the language's, so the name is found inside it rather
  /// than glued to an English lead: a language that puts the name first
  /// gets the drawing's bold name where it belongs.
  Widget _caption(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final named = this.named.isEmpty ? AppStrings.wikilinkThisNote : this.named;
    final sentence = kind == WikilinkPanelKind.book
        ? AppStrings.wikilinkPlacesIn(named)
        : AppStrings.wikilinkHeadingsIn(named);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: Text.rich(
        _emphasized(
          sentence,
          named,
          TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// The panel's own words when nothing matched.
  Widget _empty(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final headings = kind == WikilinkPanelKind.headings;
    final sentence = headings
        ? AppStrings.wikilinkNoMatchHeading(query)
        : AppStrings.wikilinkNoMatchNote(query);
    final sub = headings
        ? AppStrings.wikilinkNoHeading
        : AppStrings.wikilinkNoNote;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text.rich(
            _emphasized(
              sentence,
              query,
              TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
              TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            sub,
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int index, {required bool selected}) {
    final scheme = Theme.of(context).colorScheme;
    final entry = entries[index];
    final pick = onPick;
    final row = SizedBox(
      key: Key('wikilink-panel-row-$index'),
      height: rowHeight,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ColoredBox(
              color: selected
                  ? scheme.surfaceContainerHigh
                  : Colors.transparent,
            ),
          ),
          if (selected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 2,
              child: ColoredBox(color: scheme.primary),
            ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: switch (entry) {
                NoteSuggestion() => _noteRow(context, entry),
                HeadingSuggestion() => _headingRow(context, entry),
                BookSuggestion() => _bookRow(context, entry),
              },
            ),
          ),
        ],
      ),
    );
    if (pick == null) return row;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => pick(index),
        child: row,
      ),
    );
  }

  Widget _noteRow(BuildContext context, NoteSuggestion note) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Flexible(
          child: Text.rich(
            _nameSpan(
              note.name,
              note.alias == null ? query : '',
              TextStyle(fontSize: 12.5, color: scheme.onSurface),
              TextStyle(
                fontSize: 12.5,
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (note.alias != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outline),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                AppStrings.wikilinkAlias(note.alias!),
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        const Spacer(),
        if (note.folder.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              note.folder,
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Widget _headingRow(BuildContext context, HeadingSuggestion heading) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text.rich(
        _nameSpan(
          heading.heading,
          query,
          TextStyle(fontSize: 12.5, color: scheme.onSurface),
          TextStyle(
            fontSize: 12.5,
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _bookRow(BuildContext context, BookSuggestion place) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Text(
          place.form,
          style: TextStyle(fontSize: 12.5, color: scheme.onSurface),
        ),
        const Spacer(),
        Text(
          place.hint,
          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  /// The one row a book offers is a form, not a list: what a number is typed
  /// into.
  Widget _bodyNote(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = kind == WikilinkPanelKind.book
        ? AppStrings.wikilinkBookNote
        : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
      ),
    );
  }

  /// The keys, as the drawing's footer reads them.
  Widget _footer(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget key(String label) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, color: scheme.onSurface),
      ),
    );
    Widget label(String text) => Text(
      text,
      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
    );
    Widget dot() => Text(
      '·',
      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
    );
    final book = kind == WikilinkPanelKind.book;
    final empty = entries.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 5,
        children: <Widget>[
          if (!empty && !book) ...<Widget>[
            key('↑'),
            key('↓'),
            label(AppStrings.wikilinkFooterMove),
            dot(),
          ],
          key('⏎'),
          if (!book && !empty) label(AppStrings.wikilinkFooterOr),
          if (!book && !empty) key('Tab'),
          label(AppStrings.wikilinkFooterInsert),
          if (!empty) dot(),
          key('Esc'),
          label(AppStrings.wikilinkFooterClose),
        ],
      ),
    );
  }

  /// [sentence] with [value] drawn bold, wherever the language put it.
  ///
  /// The sentence is the language's own — it may open with the value, hold
  /// it in the middle or quote it — so the value is looked for in it
  /// instead of being concatenated here. A sentence that does not hold it
  /// (an empty value, say) is drawn as it stands.
  static InlineSpan _emphasized(
    String sentence,
    String value,
    TextStyle base,
    TextStyle bold,
  ) {
    final at = value.isEmpty ? -1 : sentence.indexOf(value);
    if (at < 0) return TextSpan(text: sentence, style: base);
    return TextSpan(
      style: base,
      children: <InlineSpan>[
        if (at > 0) TextSpan(text: sentence.substring(0, at)),
        TextSpan(text: value, style: bold),
        if (at + value.length < sentence.length)
          TextSpan(text: sentence.substring(at + value.length)),
      ],
    );
  }

  /// [name] with the run matching [q] in bold, the way the drawing marks it.
  static InlineSpan _nameSpan(
    String name,
    String q,
    TextStyle base,
    TextStyle bold,
  ) {
    if (q.isEmpty) return TextSpan(text: name, style: base);
    final at = name.toLowerCase().indexOf(q.toLowerCase());
    if (at < 0) return TextSpan(text: name, style: base);
    return TextSpan(
      style: base,
      children: <InlineSpan>[
        if (at > 0) TextSpan(text: name.substring(0, at)),
        TextSpan(text: name.substring(at, at + q.length), style: bold),
        if (at + q.length < name.length)
          TextSpan(text: name.substring(at + q.length)),
      ],
    );
  }
}

/// Places [child] under [caret], left-aligned to it, inside [pane] — and above
/// the caret when there is no room below.
///
/// Every rectangle is in the overlay's own coordinates; the surface hands
/// them over so the panel moves with the note without ever touching the text.
final class WikilinkPanelPositioned extends StatelessWidget {
  /// Positions the panel for a caret rectangle, inside the pane it belongs to.
  const new({
    required this.caret,
    required this.pane,
    required this.height,
    required this.child,
    super.key,
  });

  /// The caret's rectangle, in the overlay's coordinates.
  final Rect caret;

  /// The note pane's rectangle, in the overlay's coordinates; null keeps the
  /// panel where the caret is.
  final Rect? pane;

  /// The height the panel takes, for the flip.
  final double height;

  /// The panel itself.
  final Widget child;

  /// The gap between the caret and the panel.
  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final box = pane;
    final maxLeft = box == null
        ? double.infinity
        : box.right - wikilinkPanelWidth;
    final left = caret.left
        .clamp(
          box?.left ?? double.negativeInfinity,
          maxLeft < (box?.left ?? 0) ? (box?.left ?? 0) : maxLeft,
        )
        .toDouble();
    var top = caret.bottom + _gap;
    if (box != null &&
        top + height > box.bottom &&
        caret.top - _gap - height >= box.top) {
      top = caret.top - _gap - height;
    }
    return Positioned(
      left: left,
      top: top,
      child: SizedBox(width: wikilinkPanelWidth, child: child),
    );
  }
}
