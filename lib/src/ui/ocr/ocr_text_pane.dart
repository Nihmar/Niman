import 'package:flutter/material.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// A scan's recognized text, read (#595): the sidecar's name, the way to
/// it as a note, and the text — selectable, its position comments
/// invisible as everywhere.
final class OcrTextPane extends StatefulWidget {
  /// The pane over [text], the sidecar at [path] (library-relative).
  const new({
    required this.path,
    required this.text,
    required this.onOpenAsNote,
    super.key,
  });

  /// The sidecar, library-relative.
  final String path;

  /// Its text.
  final String text;

  /// Opens the sidecar as a note.
  final VoidCallback onOpenAsNote;

  @override
  State<OcrTextPane> createState() => _OcrTextPaneState();
}

final class _OcrTextPaneState extends State<OcrTextPane> {
  final ReadParser _parser = ReadParser();
  final MathCache _mathCache = MathCache();
  late SourceBuffer _buffer = SourceBuffer.fromText(widget.text);

  @override
  void didUpdateWidget(OcrTextPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _buffer = SourceBuffer.fromText(widget.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('ocr-text-pane'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
          child: Row(
            children: [
              Text(AppStrings.ocrTextTitle, style: theme.textTheme.titleSmall),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.posix.basename(widget.path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                key: const Key('ocr-open-as-note'),
                tooltip: AppStrings.ocrOpenAsNote,
                icon: const Icon(Icons.open_in_new),
                onPressed: widget.onOpenAsNote,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: MarkdownReadView(
            buffer: _buffer,
            parser: _parser,
            mathCache: _mathCache,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            selectionActions: const [],
          ),
        ),
      ],
    );
  }
}
