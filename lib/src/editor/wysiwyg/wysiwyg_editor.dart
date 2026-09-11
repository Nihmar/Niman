import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/wysiwyg/markdown_document_codec.dart';
import 'package:niman/src/editor/wysiwyg/opaque_embed.dart';
import 'package:niman/src/editor/wysiwyg/quill_editor_commands.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_find_controller.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_find_panel.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/ui/strings.dart';

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

  @override
  State<WysiwygEditor> createState() => WysiwygEditorState();
}

/// The surface's state; the owner holds it by key to reach [controller].
final class WysiwygEditorState extends State<WysiwygEditor> {
  static const MarkdownDocumentCodec _codec = MarkdownDocumentCodec();
  static const AppLogger _log = AppLogger(name: 'wysiwyg');

  /// Above this size Quill builds a document the note does not pay for; the
  /// source editor is offered instead (T-WYS-07). Quill has no windowing,
  /// unlike the preview.
  static const int _maxWysiwygBytes = 200 * 1024;

  final FocusNode _focus = FocusNode();
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

  /// The document length at the last selection callback: telling a tap
  /// (same length) from typing (the caret rode in on a longer document).
  int _selectionDocLength = 0;

  /// The document's lines, for the spell review panel (T-WYS-08).
  List<String> get plainTextLines =>
      _controller.document.toPlainText().split(String.fromCharCode(10));

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
    );
    _changes = _controller.changes.listen(_onDocumentChanged);
    _controller.onSelectionChanged = _onSelectionChanged;
    _controller.addListener(_publishActive);
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
      ..dispose();
    _open(widget.data);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_changes?.cancel());
    _find.dispose();
    _controller
      ..removeListener(_publishActive)
      ..dispose();
    _focus.dispose();
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
    if (widget.data.length > _maxWysiwygBytes) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(AppStrings.wysiwygTooLarge, textAlign: TextAlign.center),
        ),
      );
    }
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
            builder: (context, _) => WysiwygFindPanel(controller: _find),
          ),
          Expanded(
            child: quill.QuillEditor(
              controller: _controller,
              focusNode: _focus,
              scrollController: _scroll,
              config: quill.QuillEditorConfig(
                autoFocus: widget.autoFocus,
                padding: const EdgeInsets.all(16),
                embedBuilders: const [OpaqueEmbedBuilder()],
                textSpanBuilder: _spellSpan,
                customStyles: _customStyles(Theme.of(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
