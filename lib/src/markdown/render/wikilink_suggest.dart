import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/wikilink_panel.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/keyboard_presence.dart';

/// The wikilink suggester of the source view (#475): the panel that opens
/// while a `[[link]]` is typed, what it lists, the keys it takes while it is
/// up, and the edit that completes the link.
///
/// The view owns it and tells it when the caret moved or the text changed
/// ([refresh]); it notifies when the panel opens, closes or changes, and the
/// view rebuilds. It reads the note through the narrow callbacks it is made
/// with and writes it through [_replace] alone.
final class WikilinkSuggestController extends ChangeNotifier {
  /// A suggester over the view's [_buffer] and [_selection], listing what
  /// [_suggester] answers.
  new({
    required this._buffer,
    required this._selection,
    required this._suggester,
    required this._lineRead,
    required this._inCodeAt,
    required this._headings,
    required this._replace,
    required this._ensureCaretVisible,
    required this._caretRect,
    required this._noteBox,
    required this._caretMoves,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// The caret.
  final SelectionModel Function() _selection;

  /// The library's answers, or null for a surface with no library.
  final WikilinkSuggester? Function() _suggester;

  /// Whether the colours of a line have been read: a line of a long note
  /// still being read has no tokens to say whether it is code.
  final bool Function(int line) _lineRead;

  /// Whether an offset into a line is in code or maths.
  final bool Function(int line, int local) _inCodeAt;

  /// The note's own headings, for a `[[#` link to the note being edited.
  final List<OutlineEntry>? Function() _headings;

  /// Replaces `[start, end)` with the text as one undoable edit, the caret
  /// where it is given.
  final void Function(int start, int end, String text, SelectionModel caret)
  _replace;

  /// Scrolls the caret's line into view.
  final VoidCallback _ensureCaretVisible;

  /// The caret's rectangle in global coordinates, or null while it is not
  /// laid out.
  final Rect? Function() _caretRect;

  /// The note's own box: the pane the panel stays inside.
  final RenderBox? Function() _noteBox;

  /// What moves the caret on screen — the scroll, the caret's measurement.
  final Listenable Function() _caretMoves;

  /// The overlay the panel is drawn in.
  final OverlayPortalController overlay = OverlayPortalController();

  /// The open panel, or null while no wikilink is being typed.
  _SuggestPanel? _panel;

  /// Counts the panel's queries, so a slower one a later query overtook is
  /// dropped rather than shown.
  int _seq = 0;

  /// A line break already taken as the panel's `Enter`: the desktop embedders
  /// send the break as text *after* the key, so the copy that follows is
  /// swallowed instead of inserting a newline behind the completed link.
  bool _swallowBreak = false;

  /// Whether the view this serves is gone: an answer landing after it is
  /// dropped.
  bool _disposed = false;

  /// How many rows the panel shows at once (the drawing's density).
  static const int _rows = 8;

  /// Whether the panel is up, for the shell's tour and the tests.
  bool get isShown => _panel != null;

  @override
  void dispose() {
    _disposed = true;
    _seq++;
    super.dispose();
  }

  /// The link the caret sits inside, or null when it sits inside none: a `[[`
  /// before it on its own line with no `]]` between the two.
  ///
  /// The bracket pair writes the closing `]]` the moment `[[` is typed, so the
  /// closer stands *after* the caret while the target is written: only a `]]`
  /// between the `[[` and the caret closes the link, and typing through the
  /// pair's own closer carries the caret past it and closes the panel (#475).
  _LinkQuery? _linkQuery() {
    final selection = _selection();
    if (!selection.isCollapsed) return null;
    final buffer = _buffer();
    final caret = selection.extent.clamp(0, buffer.length);
    final line = buffer.lineOf(caret);
    final lineStart = buffer.offsetOfLine(line);
    final text = buffer.lineAt(line);
    final at = caret - lineStart;
    final open = text.lastIndexOf('[[', at);
    if (open < 0 || open + 2 > at) return null;
    // A link is prose: in a fence, an indented block or display maths, or in
    // an inline code or maths span, there is none to complete. The panel would
    // list the library for text the note reads as code and write the note name
    // it completed there (#494). Asked of the `[[` read above as well as of
    // the caret: a link opened in a span is the span's, even once the caret
    // has left it, and a caret made in a span completes nothing outside it.
    //
    // A line of a long note whose colours are still being read has no tokens
    // to ask — [_lineRead] is false, "nobody has read it yet", which
    // [_inCodeAt] would answer as "no code here" — and its fence state is a
    // scan of the lines above it: not something to guess at here. No panel
    // opens until the reading lands; the next keystroke in the link opens it
    // (#494).
    if (!_lineRead(line)) return null;
    if (_inCodeAt(line, at) || _inCodeAt(line, open)) return null;
    final close = text.indexOf(']]', open + 2);
    if (close != -1 && close < at) return null;
    final content = text.substring(open + 2, at);
    // A `|` starts the link's display alias: the panel completes the target,
    // not the words shown.
    if (content.contains('|')) return null;
    final hash = content.indexOf('#');
    // A link closed after the caret — one already written, typed into — has
    // the rest of what is being completed there too: the target runs on to a
    // `#`, a `|` or the `]]`, a heading to a `|` or the `]]`. A `]]` past
    // another `[[` is that link's, and this one is still open.
    var end = at;
    var closeAt = -1;
    final reopen = text.indexOf('[[', at);
    if (close != -1 && (reopen == -1 || reopen > close)) {
      closeAt = lineStart + close;
      end = close;
      for (final stop in hash == -1 ? const ['#', '|'] : const ['|']) {
        final found = text.indexOf(stop, at);
        if (found != -1 && found < end) end = found;
      }
    }
    final query = _LinkQuery(
      start: lineStart + open + 2,
      caret: caret,
      end: lineStart + end,
      closeAt: closeAt,
      target: hash == -1 ? content : content.substring(0, hash),
      heading: hash == -1 ? '' : content.substring(hash + 1),
      hasHash: hash != -1,
      // An embed, `![[`, lists the attachments rather than the notes (#705).
      embed: open > 0 && text.codeUnitAt(open - 1) == 0x21,
    );
    // A book's place is written through its `=` (`page=`): what follows is
    // the number the form asked the writer for, and no row completes it. The
    // key after it is the note's again, so the number stands (#494).
    if (_modeOf(query) == WikilinkPanelKind.book &&
        query.heading.contains('=')) {
      return null;
    }
    return query;
  }

  /// Opens, filters or closes the panel for where the caret is now.
  ///
  /// Called from every caret move and edit; the text of the link is what
  /// decides whether the library is asked again, so a caret that moves inside
  /// an unchanged link does not.
  ///
  /// Only an edit — [typed] — opens the panel: it is for a link being typed,
  /// and a caret moved into a link already written (an arrow, a click) is
  /// just passing through, its keys still the note's. A move follows the
  /// panel already open for as long as it stays in that link.
  void refresh({bool typed = false}) {
    if (_disposed) return;
    final suggester = _suggester();
    if (suggester == null) {
      close();
      return;
    }
    final query = _linkQuery();
    if (query == null) {
      close();
      return;
    }
    final panel = _panel;
    if (!typed && (panel == null || panel.query.start != query.start)) {
      close();
      return;
    }
    if (panel != null && panel.query.sameText(query)) {
      // The same link, the caret somewhere else in it: keep the rows and
      // follow the caret. A fresh object for the same text still names the
      // load in flight, which the `sameText` guard below accepts.
      if (!identical(panel.query, query)) {
        panel.query = query;
        notifyListeners();
      }
      overlay.show();
      return;
    }
    _ask(query, suggester);
  }

  /// Asks [suggester] what the link [query] can hold, and shows the answer.
  void _ask(_LinkQuery query, WikilinkSuggester suggester) {
    final previous = _panel;
    _panel = _SuggestPanel(
      query: query,
      kind: _modeOf(query),
      // The rows of the link just left stay until the answer lands: the
      // panel does not flash its empty words between two keystrokes.
      entries: previous?.entries ?? const <SuggestEntry>[],
      named: query.target.isEmpty ? '' : query.target,
    )..answers = previous?.answers;
    notifyListeners();
    overlay.show();
    final seq = ++_seq;
    unawaited(_load(seq, query, suggester));
  }

  Future<void> _load(
    int seq,
    _LinkQuery query,
    WikilinkSuggester suggester,
  ) async {
    final kind = _modeOf(query);
    List<SuggestEntry> entries;
    var named = query.target;
    switch (kind) {
      case WikilinkPanelKind.notes:
        named = '';
        entries = await suggester.notes(query.target);
      case WikilinkPanelKind.embeds:
        named = '';
        entries = await suggester.embeds(query.target);
      case WikilinkPanelKind.headings:
        if (query.target.isEmpty) {
          // The empty target is the note being edited: its own scan answers,
          // so no read is paid for what is already on screen.
          named = '';
          entries = <SuggestEntry>[
            for (final heading in _headings() ?? const <OutlineEntry>[])
              HeadingSuggestion(heading.text),
          ];
        } else {
          entries = await suggester.headings(query.target);
        }
      case WikilinkPanelKind.book:
        entries = await suggester.bookPlaces(query.target);
    }
    if (_disposed || seq != _seq) return;
    final panel = _panel;
    // The panel still stands in the same link text — the caret may have moved
    // inside it since the read started, so this compares the text, not the
    // object.
    if (panel == null || !panel.query.sameText(query)) return;
    panel
      ..kind = kind
      ..named = named
      ..entries = _shown(entries, query)
      ..answers = query
      ..selected = 0;
    notifyListeners();
  }

  /// [entries] as the panel shows them: filtered for a heading query (prefix
  /// before contains), and cut to the rows it draws.
  static List<SuggestEntry> _shown(
    List<SuggestEntry> entries,
    _LinkQuery query,
  ) {
    var matches = entries;
    if (query.hasHash &&
        matches.isNotEmpty &&
        matches.first is HeadingSuggestion) {
      final q = query.heading.toLowerCase();
      if (q.isNotEmpty) {
        final before = <SuggestEntry>[];
        final within = <SuggestEntry>[];
        for (final entry in matches) {
          final text = (entry as HeadingSuggestion).heading.toLowerCase();
          if (text.startsWith(q)) {
            before.add(entry);
          } else if (text.contains(q)) {
            within.add(entry);
          }
        }
        matches = <SuggestEntry>[...before, ...within];
      }
    }
    return matches.take(_rows).toList(growable: false);
  }

  /// What the link [query] is listing: the notes, a note's headings, or a
  /// book's place forms.
  static WikilinkPanelKind _modeOf(_LinkQuery query) {
    if (!query.hasHash) {
      return query.embed ? WikilinkPanelKind.embeds : WikilinkPanelKind.notes;
    }
    final target = query.target.toLowerCase();
    return target.endsWith('.pdf') || target.endsWith('.epub')
        ? WikilinkPanelKind.book
        : WikilinkPanelKind.headings;
  }

  /// Closes the panel, dropping any answer still on its way.
  void close() {
    if (_panel == null) return;
    _seq++;
    _panel = null;
    notifyListeners();
    overlay.hide();
  }

  /// Drops the panel from a `didUpdateWidget`, which runs inside the build.
  ///
  /// The overlay portal refuses to be hidden there, so the panel is dropped
  /// off the state the build that follows reads — no key and no draw of it
  /// this frame, and nobody told — and the portal is hidden once the frame is
  /// over. A panel opened in the meantime, for the text that replaced it, is
  /// left standing.
  void dropInUpdate() {
    if (_panel == null) return;
    _seq++;
    _panel = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || _panel != null) return;
      overlay.hide();
    });
  }

  /// Moves the panel's selection by [by], kept inside the rows.
  void _move(int by) {
    final panel = _panel;
    if (panel == null || panel.entries.isEmpty) return;
    final next = (panel.selected + by).clamp(0, panel.entries.length - 1);
    if (next == panel.selected) return;
    panel.selected = next;
    notifyListeners();
  }

  /// Completes the link with the row that is selected — one edit, one undo
  /// step — and closes the panel. Nothing is written but the link.
  void _accept() {
    final panel = _panel;
    if (panel == null || !panel.isCurrent) return;
    final entry = panel.entries.elementAtOrNull(panel.selected);
    if (entry == null) return;
    final query = panel.query;
    close();
    switch (entry) {
      case NoteSuggestion():
        _complete(query, query.start, entry.target);
      case HeadingSuggestion():
        _complete(query, query.hashAt, entry.heading);
      case BookSuggestion():
        // A form, not a link: the number is typed after it, so the caret
        // stops at the `=` and the link is left open.
        _complete(query, query.hashAt, entry.form, form: true);
    }
  }

  /// Replaces what [query] completes — from [from] to its end — with [text]
  /// as one undoable edit. The caret lands past the link's `]]`: the one it
  /// already has, whatever follows the text before it, or one written after
  /// the text when it has none. A [form] leaves the caret after the text.
  void _complete(_LinkQuery query, int from, String text, {bool form = false}) {
    final to = query.end;
    final closed = query.closeAt >= 0;
    final insert = form || closed ? text : '$text]]';
    final shift = text.length - (to - from);
    final caret = form
        ? from + text.length
        : closed
        ? query.closeAt + shift + 2
        : from + insert.length;
    _replace(from, to, insert, SelectionModel.at(caret));
    _ensureCaretVisible();
  }

  /// Whether the line break that just arrived is the one a completed link's
  /// `Enter` sent after the key, and so is to be swallowed; asking takes it.
  bool takeSwallowedBreak() {
    if (!_swallowBreak) return false;
    _swallowBreak = false;
    return true;
  }

  /// Forgets the swallowed break after the frame the key was handled in, so a
  /// later `Enter` is never eaten.
  void _clearSwallowBreak() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _swallowBreak = false);
  }

  /// The keys the panel owns while it is open, and only then (#475): Escape
  /// closes, Up/Down move, Enter/Tab insert. A chord — [modified] — is left
  /// alone, and with no panel the keys fall through to the note's own table
  /// exactly as they did. Null for a key the panel does not take.
  KeyEventResult? handleKey(LogicalKeyboardKey key, {required bool modified}) {
    final panel = _panel;
    if (panel == null) return null;
    if (key == LogicalKeyboardKey.escape && !modified) {
      close();
      return KeyEventResult.handled;
    }
    // Only rows that answer the link as it stands take a key: while the
    // next answer is on its way the rows drawn are the last link's, and the
    // key does what it does with no rows.
    if (!panel.isCurrent || panel.entries.isEmpty || modified) return null;
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      _accept();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _accept();
      // The embedders send the line break as text after the key too.
      _swallowBreak = true;
      _clearSwallowBreak();
      return KeyEventResult.handled;
    }
    return null;
  }

  /// The panel where the caret is: under its rectangle, inside the pane.
  Widget buildOverlay(BuildContext context) {
    final panel = _panel;
    if (panel == null) return const SizedBox.shrink();
    return ListenableBuilder(
      // A keyboard plugged in while the panel is up brings its keys along.
      listenable: Listenable.merge([_caretMoves(), KeyboardPresence.shared]),
      builder: (context, _) => _panelAt(context, panel),
    );
  }

  Widget _panelAt(BuildContext context, _SuggestPanel panel) {
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize) {
      return const SizedBox.shrink();
    }
    final caret = _caretRect();
    if (caret == null) return const SizedBox.shrink();
    Rect toOverlay(Rect rect) => Rect.fromPoints(
      overlay.globalToLocal(rect.topLeft),
      overlay.globalToLocal(rect.bottomRight),
    );
    final box = _noteBox();
    final pane = box == null
        ? null
        : toOverlay(box.localToGlobal(Offset.zero) & box.size);
    // A row is tapped on a touch screen, and taller for it; the keys are
    // named only where a keyboard has been seen to press them.
    final touch = switch (Theme.of(context).platform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
    final rowHeight = touch
        ? wikilinkPanelTouchRowHeight
        : wikilinkPanelRowHeight;
    final keys = KeyboardPresence.shared.attached;
    return WikilinkPanelPositioned(
      caret: toOverlay(caret),
      pane: pane,
      height: wikilinkPanelHeight(
        panel.entries.length,
        panel.kind,
        hasBodyNote: panel.kind == WikilinkPanelKind.book,
        rowHeight: rowHeight,
        keys: keys,
      ),
      child: WikilinkPanel(
        kind: panel.kind,
        entries: panel.entries,
        selected: panel.selected,
        query: panel.query.matchText,
        named: panel.named,
        onPick: _pick,
        keys: keys,
        rowHeight: rowHeight,
      ),
    );
  }

  /// Completes the link with the row at [index], tapped or clicked: the
  /// same edit Enter makes on the selected one.
  void _pick(int index) {
    final panel = _panel;
    if (panel == null || index >= panel.entries.length) return;
    panel.selected = index;
    _accept();
  }
}

/// The link the caret sits inside, while the suggester panel is open.
///
/// [start] is the offset after the opening `[[`; [target] is the text before a
/// `#` and [heading] the text after it; [hashAt] is the offset after the `#`,
/// where a heading (or a book form) is written. [sameText] compares the two
/// halves alone, so a caret that moves inside an unchanged link does not make
/// the panel ask the library again.
final class _LinkQuery {
  const new({
    required this.start,
    required this.caret,
    required this.end,
    required this.closeAt,
    required this.target,
    required this.heading,
    required this.hasHash,
    this.embed = false,
  });

  final int start;
  final int caret;

  /// Where the part being completed ends: the caret in a link still open,
  /// the `#`, `|` or `]]` that ends it in a link closed after the caret.
  final int end;

  /// Where the link's closing `]]` stands, or -1 while it has none.
  final int closeAt;

  final String target;
  final String heading;
  final bool hasHash;

  /// Whether a `!` stands before the `[[`: an embed (#705).
  final bool embed;

  /// The offset just past the `#`, where a heading or a book form is written.
  int get hashAt => start + target.length + 1;

  /// What the panel matches and bolds: the heading after a `#`, the target
  /// before it.
  String get matchText => hasHash ? heading : target;

  /// Whether [other] names the same link text, however the caret moved.
  bool sameText(_LinkQuery other) =>
      target == other.target &&
      heading == other.heading &&
      hasHash == other.hasHash &&
      embed == other.embed;
}

/// The suggester panel's own state: what is listed, and which row is picked.
final class _SuggestPanel {
  new({
    required this.query,
    required this.kind,
    required this.entries,
    required this.named,
  });

  /// The link the panel stands in.
  _LinkQuery query;

  /// What the rows are.
  WikilinkPanelKind kind;

  /// The rows, best match first.
  List<SuggestEntry> entries;

  /// The link text [entries] answer, or null for no query at all. It trails
  /// [query] while the next answer is on its way: the rows of the link just
  /// left stay drawn, but they are not this link's to complete.
  _LinkQuery? answers;

  /// Whether [entries] answer the link as it stands, so a key may take one.
  bool get isCurrent => answers?.sameText(query) ?? false;

  /// The note (or book) named before `#`; empty for the note being edited.
  String named;

  /// Which row `Enter` would take.
  int selected = 0;
}
