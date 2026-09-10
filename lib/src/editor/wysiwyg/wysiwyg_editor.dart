import 'dart:async';

import 'package:copist/src/editor/wysiwyg/markdown_document_codec.dart';
import 'package:copist/src/editor/wysiwyg/opaque_embed.dart';
import 'package:copist/src/editor/wysiwyg/wysiwyg_find_controller.dart';
import 'package:copist/src/editor/wysiwyg/wysiwyg_find_panel.dart';
import 'package:copist/src/spellcheck/editor_spell_check.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

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

  @override
  State<WysiwygEditor> createState() => WysiwygEditorState();
}

/// The surface's state; the owner holds it by key to reach [controller].
final class WysiwygEditorState extends State<WysiwygEditor> {
  static const MarkdownDocumentCodec _codec = MarkdownDocumentCodec();

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

  /// The controller the toolbar commands act on (T-WYS-06).
  quill.QuillController get controller => _controller;

  /// The document's lines, for the spell review panel (T-WYS-08).
  List<String> get plainTextLines =>
      _controller.document.toPlainText().split(String.fromCharCode(10));

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
    _decoded = _codec.decode(source);
    _controller = quill.QuillController(
      document: _decoded.document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _changes = _controller.changes.listen((_) => _onDocumentChanged());
    _find = WysiwygFindController(_controller);
  }

  void _onDocumentChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _emit);
  }

  void _emit() {
    if (!mounted) return;
    widget.onChanged(_codec.encode(_controller.document, decoded: _decoded));
  }

  @override
  void didUpdateWidget(WysiwygEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data == widget.data) return;
    if (widget.data == _codec.encode(_controller.document, decoded: _decoded)) {
      return;
    }
    unawaited(_changes?.cancel());
    _find.dispose();
    _controller.dispose();
    _open(widget.data);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_changes?.cancel());
    _find.dispose();
    _controller.dispose();
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
