import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/editor/context_menu_items.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/links/link_path.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/ui/strings.dart';

/// The source view's desktop context menu, and the entries it shares with
/// the touch toolbar: the clipboard's and the spelling's.
///
/// The view owns it and listens to it: it notifies when the menu opens or
/// closes, and the view rebuilds. Every entry acts through the view's own
/// actions, handed in as narrow callbacks.
final class SourceContextMenu extends ChangeNotifier {
  /// The menu over the view's [_buffer] and [_selection].
  new({
    required this._buffer,
    required this._selection,
    required this._grouped,
    required this._caretRect,
    required this._offsetAt,
    required this._linkAt,
    required this._hideTouch,
    required this._showTouch,
    required this._cut,
    required this._copy,
    required this._paste,
    required this._selectAll,
    required this._replace,
    required this._spellCheck,
    required this._spellRanges,
    required this._formats,
    required this._table,
    required this._structure,
    this._openLink,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// The caret.
  final SelectionModel Function() _selection;

  /// Whether the menu is the editor's grouped one, which keeps what cannot
  /// run in its place, greyed out (#260).
  final bool Function() _grouped;

  /// The caret's rectangle in global coordinates, or null while it is not
  /// laid out.
  final Rect? Function() _caretRect;

  /// The note offset a global point falls on, or null outside the text.
  final int? Function(Offset global) _offsetAt;

  /// The link at an offset — its kind, its text as written, and a Markdown
  /// link's resolved target — or null (#1099).
  final (TokenKind, String, String?)? Function(int offset) _linkAt;

  /// Opens a link token, Ctrl+click's own call; null on a surface that
  /// follows no link, where Open link is shown greyed out.
  final void Function(TokenKind kind, String raw, String? href)? _openLink;

  /// Takes the touch selection's handles and toolbar away.
  final VoidCallback _hideTouch;

  /// Shows the touch selection, with its toolbar or without.
  final void Function({required bool toolbar}) _showTouch;

  /// The clipboard's actions on the selection.
  final Future<void> Function() _cut;
  final Future<void> Function() _copy;
  final Future<void> Function() _paste;

  /// Selects the whole note.
  final VoidCallback _selectAll;

  /// Replaces a range of the note as one undoable edit.
  final void Function(int start, int end, String text) _replace;

  /// The spelling, or null for a surface given none.
  final EditorSpellCheck? Function() _spellCheck;

  /// The misspelled ranges of a line, given its text.
  final List<TextRange> Function(int line, String text) _spellRanges;

  /// The toolbar's formats, for a menu with no grouped part of its own.
  final List<FormatMenuEntry> Function() _formats;

  /// What can be done to the table the caret is in, or null outside one.
  final ContextMenuPart? Function() _table;

  /// The editor's grouped menu, when it has one.
  final ContextMenuPart? Function() _structure;

  /// The overlay the menu is drawn in.
  final OverlayPortalController overlay = OverlayPortalController();

  /// Where the menu opens, in global coordinates, while it is up.
  Offset? _at;

  /// The link under the pointer — or under the caret, for the menu key —
  /// while the menu is up, read once as it opens (#1099).
  (TokenKind, String, String?)? _link;

  /// Whether the view this serves is gone.
  bool _disposed = false;

  /// How many of the checker's suggestions the menu offers.
  static const int _suggestions = 4;

  /// Whether the menu is up.
  bool get isShown => _at != null;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Opens the menu at [global], or at the caret without one (the menu key,
  /// Shift+F10). The link under the pointer — or under the caret — is read
  /// now, so the menu can offer Open link and Copy link for it (#1099).
  void show([Offset? global]) {
    final at = global ?? _caretRect()?.bottomLeft;
    if (at == null) return;
    final buffer = _buffer();
    final offset = global == null
        ? _selection().extent.clamp(0, buffer.length)
        : _offsetAt(global);
    _link = offset == null ? null : _linkAt(offset);
    _hideTouch();
    _at = at;
    notifyListeners();
    overlay.show();
  }

  /// Closes the menu.
  void hide() {
    if (_at == null) return;
    if (!_disposed) {
      _at = null;
      notifyListeners();
    }
    overlay.hide();
  }

  /// The desktop menu at the click, over a barrier that closes it.
  ///
  /// The barrier is the menu's own: one click anywhere else takes it down and
  /// does nothing else, which is how a context menu behaves everywhere — and
  /// what the legacy editor's menu learnt the hard way (a menu left up
  /// through every click after it, 2026-09-10).
  Widget buildOverlay(BuildContext context) {
    final at = _at;
    if (at == null) return const SizedBox.shrink();
    final overlay = Overlay.of(context).context.findRenderObject();
    final local = overlay is RenderBox && overlay.hasSize
        ? overlay.globalToLocal(at)
        : at;
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            key: const Key('editor-menu-barrier'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => hide(),
            onSecondaryTapDown: (_) => hide(),
          ),
        ),
        // Full-screen constraints on purpose: the toolbar places itself from
        // the anchors inside the box it is given.
        Positioned.fill(
          child: EditorContextMenu(
            anchors: TextSelectionToolbarAnchors(primaryAnchor: local),
            clipboard: clipboardItems(hide),
            formats: _formats(),
            extras: spellingItems(hide),
            linkActions: _linkActions(context),
            table: _table(),
            structure: _structure(),
            onDismiss: hide,
          ),
        ),
      ],
    );
  }

  /// The link actions the menu offers for the link read as it opened
  /// (#1099): Open link and Copy link for a Markdown link whose target
  /// leaves the library — `LinkPaths.hasScheme`, the resolver's own rule,
  /// so `https://…`, `mailto:` and `tel:` qualify. Null for a wikilink, a
  /// note path, a local anchor, or a click that landed on no link at all;
  /// the menu then opens exactly as it did before.
  List<ContextMenuAction>? _linkActions(BuildContext context) {
    final link = _link;
    if (link == null) return null;
    final (kind, raw, href) = link;
    if (kind != TokenKind.link) return null;
    final target = (href ?? _inlineHrefOf(raw)).trim();
    if (target.isEmpty || !LinkPaths.hasScheme(target)) return null;
    final open = _openLink;
    return <ContextMenuAction>[
      ContextMenuAction(
        id: 'menu-open-link',
        label: AppStrings.menuOpenLink,
        icon: Icons.open_in_new,
        onPressed: open == null ? null : () => open(kind, raw, href),
      ),
      ContextMenuAction(
        id: 'menu-copy-link',
        label: AppStrings.menuCopyLink,
        icon: Icons.content_copy,
        onPressed: () => unawaited(_copyLink(context, target)),
      ),
    ];
  }

  /// The target of an inline `[text](href)` as written — what
  /// `_openLinkToken` reads out of the token — or an empty string when the
  /// token spells no `](href)`, as a reference link does not.
  static String _inlineHrefOf(String raw) {
    final close = raw.indexOf(']');
    if (close < 0 || raw.length < close + 3 || raw[close + 1] != '(') {
      return '';
    }
    return raw.substring(close + 2, raw.length - 1);
  }

  /// Puts [target] on the clipboard and says so — the same word the place
  /// link button gives (#282).
  Future<void> _copyLink(BuildContext context, String target) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: target));
    messenger?.showSnackBar(
      SnackBar(content: Text(AppStrings.placeLinkCopied)),
    );
  }

  /// Cut, copy, paste and select all, as they apply to the selection; each
  /// closes its menu through [dismiss] before it acts — the touch toolbar's
  /// with [touch].
  ///
  /// Cut and copy of a caret are not offered: there is nothing to take.
  List<ContextMenuButtonItem> clipboardItems(
    VoidCallback dismiss, {
    bool touch = false,
  }) {
    final buffer = _buffer();
    final selection = _selection().clampTo(buffer.length);
    final collapsed = selection.isCollapsed;
    // The grouped menu keeps what cannot run in its place, greyed out, so
    // nothing moves under the pointer (#260); the flat one leaves it out.
    final keep = _grouped();
    return <ContextMenuButtonItem>[
      if (!collapsed || keep)
        ContextMenuButtonItem(
          type: ContextMenuButtonType.cut,
          onPressed: collapsed
              ? null
              : () {
                  dismiss();
                  unawaited(_cut());
                },
        ),
      if (!collapsed || keep)
        ContextMenuButtonItem(
          type: ContextMenuButtonType.copy,
          onPressed: collapsed
              ? null
              : () {
                  unawaited(_copy());
                  // By touch the handles stay, so the selection can be
                  // pasted over or extended; the toolbar goes.
                  if (touch) {
                    _showTouch(toolbar: false);
                  } else {
                    dismiss();
                  }
                },
        ),
      ContextMenuButtonItem(
        type: ContextMenuButtonType.paste,
        onPressed: () {
          dismiss();
          unawaited(_paste());
        },
      ),
      if (selection.start > 0 || selection.end < buffer.length || keep)
        ContextMenuButtonItem(
          type: ContextMenuButtonType.selectAll,
          onPressed: selection.start == 0 && selection.end == buffer.length
              ? null
              : () {
                  _selectAll();
                  if (touch) {
                    _showTouch(toolbar: true);
                  } else {
                    dismiss();
                  }
                },
        ),
    ];
  }

  /// The spelling's entries for the word under the caret or the selection:
  /// what the checker suggests for it, then Add to dictionary.
  ///
  /// Only for a word the note underlines — the ranges come from the same
  /// call that draws the underline — and only within one line.
  List<ContextMenuButtonItem> spellingItems(VoidCallback dismiss) {
    final spell = _spellCheck();
    if (spell == null) return const <ContextMenuButtonItem>[];
    final buffer = _buffer();
    final selection = _selection().clampTo(buffer.length);
    final line = buffer.lineOf(selection.start);
    if (line != buffer.lineOf(selection.end)) {
      return const <ContextMenuButtonItem>[];
    }
    final lineStart = buffer.offsetOfLine(line);
    final text = buffer.lineAt(line);
    final start = selection.start - lineStart;
    final end = selection.end - lineStart;
    final items = <ContextMenuButtonItem>[];
    for (final range in _spellRanges(line, text)) {
      if (start < range.start || end > range.end) continue;
      final word = text.substring(range.start, range.end);
      for (final suggestion in spell.suggestionsFor(word).take(_suggestions)) {
        items.add(
          ContextMenuButtonItem(
            label: suggestion,
            onPressed: () {
              dismiss();
              _replace(
                lineStart + range.start,
                lineStart + range.end,
                suggestion,
              );
            },
          ),
        );
      }
      break;
    }
    final add = addToDictionaryItem(
      spell: spell,
      text: text,
      start: start,
      end: end,
      onDismiss: dismiss,
    );
    if (add != null) items.add(add);
    return items;
  }
}
