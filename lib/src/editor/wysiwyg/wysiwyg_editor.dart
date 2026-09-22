// The clipboard config is marked experimental upstream and is the only
// hook the package offers on the paste side; see `wysiwyg_clipboard.dart`
// for why the surface has to own that path at all.
// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/find_bar.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/typewriter_scroll.dart';
import 'package:niman/src/editor/wysiwyg/markdown_document_codec.dart';
import 'package:niman/src/editor/wysiwyg/opaque_embed.dart';
import 'package:niman/src/editor/wysiwyg/quill_editor_commands.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_clipboard.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_find_controller.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';

/// The WYSIWYG writing surface: a Quill editor over the note's Markdown.
///
/// It deliberately has no toolbar of its own: the app's EditorToolbar is the
/// editor chrome on both surfaces, in the same slot, and its Quill commands
/// are QuillEditorCommands.
final class WysiwygEditor extends StatefulWidget {
  /// Creates the surface over the note's Markdown.
  const new({
    required this.data,
    required this.onChanged,
    this.autoFocus = false,
    this.spellCheck,
    this.activeItems,
    this.focusNode,
    this.column = NoteColumn.off,
    this.formatMenu,
    this.typewriter = false,
    super.key,
  });

  /// The note's Markdown.
  final String data;

  /// Called with the serialized Markdown after a short typing pause.
  final ValueChanged<String> onChanged;

  /// Whether to focus the editor when it opens.
  final bool autoFocus;

  /// The editor's spelling state (T-WYS-08): underlines misspelled prose.
  /// Null (tests, or a platform without hunspell) draws none.
  final EditorSpellCheck? spellCheck;

  /// The formats on at the caret, for the formatting toolbar's pressed
  /// state (T-WYS-06). Null in tests that do not show a toolbar.
  final ValueNotifier<Set<ToolbarItem>>? activeItems;

  /// A focus node owned by the caller, for the owner's keyboard tracking
  /// (the phone's toolbar rides the editor's focus); null keeps the
  /// surface's own node.
  final FocusNode? focusNode;

  /// Where the text sits across the surface (issue #171); the source
  /// editor puts its text at the same x.
  final NoteColumn column;

  /// The toolbar's formatting actions for the context menu (#174), the
  /// same ones the source editor's menu offers.
  final FormatMenuBuilder? formatMenu;

  /// Typewriter mode (#70): the caret's row keeps to the middle of the
  /// surface, with room below the last line for it to get there.
  final bool typewriter;

  @override
  State<WysiwygEditor> createState() => WysiwygEditorState();
}

/// The surface's state; the owner holds it by key to reach [controller].
final class WysiwygEditorState extends State<WysiwygEditor> {
  static const MarkdownDocumentCodec _codec = MarkdownDocumentCodec();
  static const AppLogger _log = AppLogger(name: 'wysiwyg');

  final FocusNode _internalFocus = FocusNode();
  FocusNode get _focus => widget.focusNode ?? _internalFocus;
  final ScrollController _scroll = ScrollController();
  late quill.QuillController _controller;
  late DecodedNote _decoded;
  late WysiwygFindController _find;
  StreamSubscription<quill.DocChange>? _changes;
  Timer? _debounce;

  /// The last Markdown this surface emitted. The parent echoes it back as
  /// [WysiwygEditor.data] on its next rebuild, and that echo can be older
  /// than the live document while the writer keeps typing: re-decoding from
  /// it reset the buffer and put the caret back at the start (device
  /// report, 2026-09-11).
  String? _lastEmitted;

  /// The controller the toolbar commands act on (T-WYS-06).
  quill.QuillController get controller => _controller;

  /// How far the surface is scrolled; null before its first layout.
  double? get scrollOffset => _scroll.hasClients ? _scroll.offset : null;

  /// The surface's scroll, for putting a tab back where it was (#23).
  ScrollController get scrollController => _scroll;

  /// The document length at the last selection callback: telling a tap
  /// (same length) from typing (the caret rode in on a longer document).
  int _selectionDocLength = 0;

  /// Where the last right-click landed, in global coordinates (#161).
  ///
  /// Quill anchors its context menu from the *selection*
  /// (`raw_editor_state.dart:251`, `TextSelectionToolbarAnchors
  /// .fromSelection`), and for a selection spanning more than one line
  /// that helper widens the rect to the whole editing region and anchors
  /// at its horizontal centre. That is the phone convention — a toolbar
  /// centred over the selection — and on a 1280 px window it puts the
  /// menu half a screen from the click that asked for it (device report,
  /// 2026-09-18).
  ///
  /// Flutter's own editors anchor a right-click menu at the pointer and
  /// keep a `lastSecondaryTapDownPosition` for it. Quill records none, so
  /// the surface keeps its own. Null when no mouse opened the menu (a
  /// long press, a keyboard request), where the selection *is* the right
  /// anchor — which is also why a primary press clears it.
  Offset? _rightClickAt;

  /// Markdown in, Markdown out (#165).
  late final WysiwygClipboard _clipboard = WysiwygClipboard(
    controller: () => _controller,
  );

  /// The document's lines, for the spell review panel (T-WYS-08).
  List<String> get plainTextLines =>
      _controller.document.toPlainText().split(String.fromCharCode(10));

  /// Whether the surface holds the focus (the keyboard is up over it).
  bool get hasFocus => _focus.hasFocus;

  /// Returns focus to the surface, keeping the caret where it was.
  ///
  /// The formatting toolbar lives outside the editor: on the desktop a tap
  /// on it moves focus out of the Quill editor, so every toolbar command
  /// calls this after applying its format — the caret stays put, the format
  /// stays active, and typing continues without a second click.
  void requestEditorFocus() {
    if (_focus.canRequestFocus) _focus.requestFocus();
  }

  /// Opens the find bar (the status-row button and Ctrl/Cmd+F, T-WYS-08).
  void openFind({bool replace = false}) => _find.open(replace: replace);

  /// Replaces [start]..[end] of document line [line], the spell panel's fix
  /// (T-WYS-08).
  void replaceDocumentRange(int line, int start, int end, String replacement) {
    final lines = plainTextLines;
    if (line < 0 || line >= lines.length) return;
    var offset = 0;
    for (var i = 0; i < line; i++) {
      offset += lines[i].length + 1;
    }
    final index = offset + start;
    _controller.replaceText(
      index,
      end - start,
      replacement,
      TextSelection.collapsed(offset: index + replacement.length),
    );
  }

  @override
  void initState() {
    super.initState();
    _open(widget.data);
    _scroll.addListener(_updateBand);
    _focus.addListener(_updateBand);
  }

  void _open(String source) {
    // The decode is the one step that can fail on a hostile file. Falling
    // back to an empty note keeps the state valid: when it threw instead,
    // the half-built state cascaded 77 LateInitializationErrors behind one
    // bad file (debug log, 2026-09-10).
    DecodedNote decoded;
    try {
      decoded = _codec.decode(source);
    } on Object catch (error) {
      _log.error('decode failed, opening an empty note: $error');
      decoded = _codec.decode('');
    }
    _decoded = decoded;
    _controller = quill.QuillController(
      document: _decoded.document,
      selection: const TextSelection.collapsed(offset: 0),
      // Paste goes through the surface's own Markdown path (#165). The
      // hook runs before everything else Quill would try, and declines
      // when the clipboard carries HTML so the package's rich paste keeps
      // it — pasting a styled page from a browser is Quill's job.
      config: quill.QuillControllerConfig(
        clipboardConfig: quill.QuillClipboardConfig(
          onClipboardPaste: _clipboard.paste,
        ),
      ),
    );
    _changes = _controller.changes.listen(_onDocumentChanged);
    _controller.onSelectionChanged = _onSelectionChanged;
    _controller
      ..addListener(_publishActive)
      ..addListener(_followCaret);
    _selectionDocLength = _controller.document.length;
    _find = WysiwygFindController(_controller);
    // A new note's data is not the previous note's echo.
    _lastEmitted = null;
    final embedded = _decoded.snapshot
        .where((op) => op['insert'] is Map)
        .length;
    _log.debug(
      'open: ${source.length} chars, ${_decoded.snapshot.length} delta ops, '
      '$embedded preserved blocks',
    );
  }

  void _onDocumentChanged(quill.DocChange change) {
    final lineStyle = _controller.getSelectionStyle().attributes.keys.join(',');
    final kept = _controller.toggledStyle.attributes.keys.join(',');
    _log.debug(
      'change: caret ${_controller.selection.start}, line [$lineStyle], '
      'kept [$kept]',
    );
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _emit);
  }

  /// Quill keeps the line's block style when Enter is pressed, so a heading
  /// would turn every following line into a heading — the next typed word
  /// would come out bold, which is not what a Markdown note expects. Lists
  /// and quotes still continue; the header does not (T-WYS-08).
  ///
  /// The hook is the selection callback, not the changes stream: the stream
  /// is published while replaceText composes the document, before it sets
  /// the kept style, so a listener there would read the previous style.
  void _onSelectionChanged(TextSelection selection) {
    final toggled = _controller.toggledStyle;
    if (toggled.attributes.containsKey(quill.Attribute.header.key)) {
      _controller.toggledStyle = toggled.removeAll(<quill.Attribute<dynamic>>{
        quill.Attribute.header,
      });
      _log.debug('new line after a heading: the header is not continued');
    }
    _stripEndOfDocumentLeak(selection);
  }

  /// A collapsed caret past the last character takes no inline format from
  /// the run before it: every inline span the codec writes is paired
  /// (`**..**`, `*..*`, `~~..~~`, `<u>..</u>`), so past the last character
  /// the span is closed and inheriting its format only extends it by
  /// accident — the lit strikethrough the device report hit on a note
  /// ending in a closed `~~..~~` run. Recording removals in the kept style
  /// keeps the lamp and the next typed character in step: both plain.
  /// Mid-document Quill's preceding-style convention stays: it is what lets
  /// a tap inside a run keep typing inside it.
  ///
  /// Only a pure caret move strips: when the caret rode in on a document
  /// change (typing, paste) the format is being continued on purpose —
  /// stripping it dropped the just-tapped toggle after one character
  /// (device report). The length is read on every callback, not just in
  /// the end zone, so a mid-document edit cannot mask a later tap at
  /// the end.
  void _stripEndOfDocumentLeak(TextSelection selection) {
    final controller = _controller;
    final length = controller.document.length;
    final docChanged = length != _selectionDocLength;
    _selectionDocLength = length;
    if (!selection.isCollapsed) return;
    if (selection.end < length - 1) return;
    if (docChanged) return;
    var kept = controller.toggledStyle;
    var changed = false;
    for (final attr in controller.getSelectionStyle().attributes.values) {
      if (attr.scope != quill.AttributeScope.inline) continue;
      if (attr.value == null) continue;
      // `put`, not `merge`: merge drops null-valued attributes, while the
      // removal must stay in the kept style — it is what the toolbar reads
      // and what the next typed character obeys (the toggle-off path).
      kept = kept.put(quill.Attribute.clone(attr, null));
      changed = true;
    }
    if (changed) {
      controller.toggledStyle = kept;
      _log.debug('caret at end of note: the closed run is not continued');
    }
  }

  /// Publishes the formats that are on at the caret to the toolbar.
  void _publishActive() {
    final notifier = widget.activeItems;
    if (notifier == null) return;
    final active = <ToolbarItem>{
      for (final item in ToolbarItem.values)
        if (QuillEditorCommands.isActive(_controller, item)) item,
    };
    if (setEquals(active, notifier.value)) return;
    notifier.value = active;
  }

  void _emit() {
    if (!mounted) return;
    final markdown = _codec.encode(_controller.document, decoded: _decoded);
    _lastEmitted = markdown;
    _log.debug('emit: ${markdown.length} chars');
    widget.onChanged(markdown);
  }

  @override
  void didUpdateWidget(WysiwygEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switched on while writing: the caret goes to the middle at once.
    if (widget.typewriter && !oldWidget.typewriter) _followCaret();
    if (oldWidget.data == widget.data) return;
    // Our own emit coming back, possibly stale while the writer types on:
    // never re-decode from it.
    if (widget.data == _lastEmitted) return;
    if (widget.data == _codec.encode(_controller.document, decoded: _decoded)) {
      return;
    }
    unawaited(_changes?.cancel());
    _find.dispose();
    _controller
      ..removeListener(_publishActive)
      ..removeListener(_followCaret)
      ..dispose();
    _open(widget.data);
  }

  @override
  void dispose() {
    _scroll.removeListener(_updateBand);
    _focus.removeListener(_updateBand);
    _band.dispose();
    _typewriter.dispose();
    _debounce?.cancel();
    unawaited(_changes?.cancel());
    _find.dispose();
    _controller
      ..removeListener(_publishActive)
      ..removeListener(_followCaret)
      ..dispose();
    // The caller's node is theirs to dispose; only the internal one dies
    // with the surface.
    _internalFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Quill's text-span hook: the misspelled words get the wavy underline,
  /// everything else is the package's default span (T-WYS-08).
  InlineSpan _spellSpan(
    BuildContext context,
    quill.Node node,
    int nodeOffset,
    String text,
    TextStyle? style,
    GestureRecognizer? recognizer,
  ) {
    final fallback = quill.defaultSpanBuilder(
      context,
      node,
      nodeOffset,
      text,
      style,
      recognizer,
    );
    final spell = widget.spellCheck;
    if (spell == null || text.isEmpty || _isCode(node)) return fallback;
    final ranges = spell.rangesFor(
      text.hashCode & 0x7fffffff,
      text,
      skip: const <TextRange>[],
    );
    if (ranges.isEmpty) return fallback;
    final children = <TextSpan>[];
    var cursor = 0;
    for (final range in ranges) {
      if (range.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, range.start)));
      }
      children.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: TextStyle(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.wavy,
            decorationColor: Theme.of(context).colorScheme.error,
          ),
        ),
      );
      cursor = range.end;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }
    return TextSpan(style: style, recognizer: recognizer, children: children);
  }

  /// Code is not prose: neither inline code nor a code block is checked.
  static bool _isCode(quill.Node node) {
    if (node.style.attributes.containsKey(quill.Attribute.inlineCode.key)) {
      return true;
    }
    final parent = node.parent;
    return parent != null &&
        parent.style.attributes.containsKey(quill.Attribute.codeBlock.key);
  }

  /// The Quill editor's context menu (issue #60): the package's default
  /// cut/copy/paste items, plus Add-to-dictionary when the checker flags
  /// the word under the caret/selection. A right click only positions the
  /// menu: the entry acts on the word where the caret/selection already
  /// is, and the menu closes once the word is added (the copy/cut
  /// path's rule).
  Widget _contextMenu(BuildContext context, quill.QuillRawEditorState state) {
    final value = state.textEditingValue;
    final selection = value.selection;
    // Copy and Cut are rebuilt: the package's own items call
    // `state.copySelection()` straight, without going through the
    // `CopySelectionTextIntent` action the keyboard uses, so an override
    // there would leave the menu on the old behaviour (#165). Paste needs
    // no rebuilding — it reaches `clipboardPaste`, and the surface's hook
    // is on that.
    final items = <ContextMenuButtonItem>[
      for (final item in state.contextMenuButtonItems)
        switch (item.type) {
          ContextMenuButtonType.copy => item.copyWith(
            onPressed: () => _clipboardMenuAction(state, cut: false),
          ),
          ContextMenuButtonType.cut => item.copyWith(
            onPressed: () => _clipboardMenuAction(state, cut: true),
          ),
          _ => item,
        },
    ];
    final extras = <ContextMenuButtonItem>[];
    final spell = widget.spellCheck;
    if (spell != null) {
      final item = addToDictionaryItem(
        spell: spell,
        text: value.text,
        start: selection.start,
        end: selection.end,
        onDismiss: state.hideToolbar,
      );
      if (item != null) extras.add(item);
    }
    final clicked = _rightClickAt;
    return TextFieldTapRegion(
      child: EditorContextMenu(
        anchors: clicked == null
            ? state.contextMenuAnchors
            : TextSelectionToolbarAnchors(primaryAnchor: clicked),
        clipboard: items,
        formats: widget.formatMenu?.call() ?? const [],
        extras: extras,
        onDismiss: state.hideToolbar,
      ),
    );
  }

  /// Copy or Cut from the menu, then close it — the menu's own rule.
  void _clipboardMenuAction(
    quill.QuillRawEditorState state, {
    required bool cut,
  }) {
    unawaited(_clipboard.copy(cut: cut));
    state.hideToolbar();
  }

  /// Remembers a right-click for [_contextMenu], and forgets it on any
  /// other press so a later long press or keyboard request anchors on the
  /// selection instead of on a stale pointer.
  void _onPointerDown(PointerDownEvent event) {
    _rightClickAt = event.buttons & kSecondaryButton != 0
        ? event.position
        : null;
  }

  /// Quill's default code-block style is a near-white box with dark blue
  /// text: in the app's dark theme it read as a white rectangle (device
  /// report, 2026-09-11). The app's own surface and text replace it; every
  /// other style stays Quill's.
  static quill.DefaultStyles _customStyles(ThemeData theme) =>
      quill.DefaultStyles(
        code: quill.DefaultTextBlockStyle(
          TextStyle(
            color: theme.colorScheme.onSurface,
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.15,
          ),
          const quill.HorizontalSpacing(14, 0),
          const quill.VerticalSpacing(6, 6),
          quill.VerticalSpacing.zero,
          BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            _find.open(),
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
            _find.open(),
        const SingleActivator(LogicalKeyboardKey.keyH, control: true): () =>
            _find.open(replace: true),
        const SingleActivator(LogicalKeyboardKey.escape): _find.close,
      },
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _find,
            builder: (context, _) =>
                FindBar(controller: _find, column: widget.column),
          ),
          Expanded(
            // Copy and cut from the keyboard (#165). Quill builds its own
            // clipboard actions with `Action.overridable`, which looks for
            // an ancestor first — this is that ancestor. Paste is not here
            // because the package offers a better seam for it below, one
            // that keeps its focus and selection handling.
            child: Actions(
              actions: <Type, Action<Intent>>{
                CopySelectionTextIntent:
                    CallbackAction<CopySelectionTextIntent>(
                      onInvoke: (intent) {
                        unawaited(
                          _clipboard.copy(cut: intent.collapseSelection),
                        );
                        return null;
                      },
                    ),
              },
              // The listener only watches; the editor below it sees every
              // event unchanged.
              child: Listener(
                onPointerDown: _onPointerDown,
                child: LayoutBuilder(
                  key: _viewportKey,
                  builder: (context, constraints) => Stack(
                    fit: StackFit.passthrough,
                    children: [
                      if (widget.typewriter) _litRow(),
                      _quillEditor(constraints.maxWidth, constraints.maxHeight),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Typewriter mode's follow of the caret (#70).
  late final TypewriterFollow _typewriter = TypewriterFollow(_centerCaret);

  /// Quill's editable, for where its caret is drawn.
  final GlobalKey<quill.EditorState> _editorKey = GlobalKey();

  /// The surface's viewport: what the caret is centred in.
  final GlobalKey _viewportKey = GlobalKey();

  /// The caret moved, or the text under it did: typewriter mode brings its
  /// row to the middle — while someone is writing here, so a note opening
  /// or its place being put back stays where it was put.
  void _followCaret() {
    if (!widget.typewriter) return;
    // The lit row follows the caret wherever it goes.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateBand());
    if (!_focus.hasFocus && !_find.visible) return;
    _typewriter.caretMoved();
  }

  /// The caret's rect in the viewport's coordinates, or null before the
  /// surface is laid out.
  Rect? _caretInViewport() {
    final editor = _editorKey.currentState?.renderEditor;
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (editor == null || !editor.attached || viewport is! RenderBox) {
      return null;
    }
    final caret = editor.getLocalRectForCaret(
      TextPosition(offset: _controller.selection.extentOffset),
    );
    final top =
        editor.localToGlobal(caret.topLeft).dy -
        viewport.localToGlobal(Offset.zero).dy;
    return Rect.fromLTWH(0, top, viewport.size.width, caret.height);
  }

  bool _centerCaret() {
    final caret = _caretInViewport();
    if (caret == null) return false;
    centerCaret(_scroll, caret.center.dy);
    return true;
  }

  /// The row the caret is on, lit in typewriter mode while the surface
  /// has the focus (0.0.8 test round); null lights nothing. Quill has no
  /// current-line colour of its own, so the band is painted behind it.
  final ValueNotifier<Rect?> _band = ValueNotifier(null);

  void _updateBand() {
    if (!mounted) return;
    _band.value = widget.typewriter && _focus.hasFocus
        ? _caretInViewport()
        : null;
  }

  /// The band behind the caret's row (typewriter mode).
  Widget _litRow() => Positioned.fill(
    child: IgnorePointer(
      child: ValueListenableBuilder<Rect?>(
        valueListenable: _band,
        builder: (context, row, _) => row == null
            ? const SizedBox.shrink()
            : Stack(
                children: [
                  Positioned(
                    key: const Key('wysiwyg-lit-row'),
                    left: 0,
                    right: 0,
                    top: row.top - 2,
                    height: row.height + 4,
                    child: ColoredBox(color: typewriterLineColor(context)),
                  ),
                ],
              ),
      ),
    ),
  );

  /// Esc (#69). Quill's own (hiding its selection toolbar) is on whenever
  /// there is a caret, so the key never left the editor. Here it cancels a
  /// selection first, like the source editor's; with none it is the
  /// app's Esc — a [DismissIntent], which leaves Zen mode — when something
  /// above takes it, and Quill's otherwise.
  KeyEventResult? _onKey(KeyEvent event, quill.Node? node) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return null;
    }
    final selection = _controller.selection;
    if (!selection.isCollapsed) {
      _controller.updateSelection(
        TextSelection.collapsed(offset: selection.extentOffset),
        quill.ChangeSource.local,
      );
      return KeyEventResult.handled;
    }
    final dismiss = Actions.maybeFind<DismissIntent>(context);
    if (dismiss == null) return null;
    final (enabled, _) = Actions.of(context)
        .invokeActionIfEnabled(dismiss, const DismissIntent(), context);
    return enabled ? KeyEventResult.handled : null;
  }

  /// The Quill surface in a pane [width] wide and [height] tall: the
  /// column's side space is Quill's padding, inside its scroll view, so
  /// the scrollbar keeps to the pane's edge and the wheel scrolls from the
  /// margins too. Typewriter mode adds its room below the last line there.
  Widget _quillEditor(double width, double height) {
    final side = widget.column.sideSpaceIn(width);
    const inset = NoteColumn.textInset;
    final slack = widget.typewriter ? typewriterSlack(height) : 0.0;
    return quill.QuillEditor(
      controller: _controller,
      focusNode: _focus,
      scrollController: _scroll,
      config: quill.QuillEditorConfig(
        editorKey: _editorKey,
        autoFocus: widget.autoFocus,
        padding: EdgeInsets.fromLTRB(
          side + inset,
          inset,
          side + inset,
          inset + slack,
        ),
        embedBuilders: const [OpaqueEmbedBuilder()],
        textSpanBuilder: _spellSpan,
        contextMenuBuilder: _contextMenu,
        customStyles: _customStyles(Theme.of(context)),
        onKeyPressed: _onKey,
      ),
    );
  }
}
