import 'dart:async';

import 'package:copist/src/editor/wysiwyg/markdown_document_codec.dart';
import 'package:copist/src/editor/wysiwyg/opaque_embed.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// The WYSIWYG writing surface: a Quill editor over the note's Markdown.
///
/// It deliberately has no toolbar of its own: the app's EditorToolbar is the
/// editor chrome on both surfaces, in the same slot, and its Quill commands
/// are `QuillEditorCommands`.
final class WysiwygEditor extends StatefulWidget {
  /// Creates the surface over the note's Markdown.
  const new({
    required this.data,
    required this.onChanged,
    this.autoFocus = false,
    super.key,
  });

  /// The note's Markdown.
  final String data;

  /// Called with the serialized Markdown after a short typing pause.
  final ValueChanged<String> onChanged;

  /// Whether to focus the editor when it opens.
  final bool autoFocus;

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
  StreamSubscription<quill.DocChange>? _changes;
  Timer? _debounce;

  /// The controller the toolbar commands act on (T-WYS-06).
  quill.QuillController get controller => _controller;

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
    _controller.dispose();
    _open(widget.data);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_changes?.cancel());
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
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
    return quill.QuillEditor(
      controller: _controller,
      focusNode: _focus,
      scrollController: _scroll,
      config: quill.QuillEditorConfig(
        autoFocus: widget.autoFocus,
        padding: const EdgeInsets.all(16),
        embedBuilders: const [OpaqueEmbedBuilder()],
      ),
    );
  }
}
