import 'package:flutter/material.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/ocr/ocr_lines_scope.dart';
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
    this.onRecognizeAgain,
    super.key,
  });

  /// The sidecar, library-relative.
  final String path;

  /// Its text.
  final String text;

  /// Opens the sidecar as a note.
  final VoidCallback onOpenAsNote;

  /// Reads a page again, for one whose lines lost their places (#596);
  /// null offers none.
  final void Function(int page)? onRecognizeAgain;

  @override
  State<OcrTextPane> createState() => _OcrTextPaneState();
}

final class _OcrTextPaneState extends State<OcrTextPane> {
  final ReadParser _parser = ReadParser();
  final MathCache _mathCache = MathCache();
  late SourceBuffer _buffer = SourceBuffer.fromText(widget.text);
  final GlobalKey<MarkdownReadViewState> _read = GlobalKey();
  int? _shownLine;

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
    final scope = OcrLinesScope.maybeOf(context);
    final selected = scope?.selected;
    // A line picked on the scan: brought into view here too, once.
    if (selected != null && selected.sourceLine != _shownLine) {
      _shownLine = selected.sourceLine;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _read.currentState?.jumpToLine(selected.sourceLine),
      );
    }
    final lost = scope?.lines.lostByPage ?? const <int, int>{};
    final again = widget.onRecognizeAgain;
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
        for (final MapEntry(key: page, value: count) in lost.entries)
          _LostPlaces(
            page: page,
            count: count,
            onRecognizeAgain: again == null ? null : () => again(page),
          ),
        Expanded(
          child: MarkdownReadView(
            key: _read,
            buffer: _buffer,
            parser: _parser,
            mathCache: _mathCache,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            selectionActions: const [],
            marks: [
              if (selected != null)
                (line: selected.sourceLine, chars: selected.chars),
            ],
          ),
        ),
      ],
    );
  }
}

/// A page whose lines a hand edit left without their places, and the way
/// to read it again.
final class _LostPlaces extends StatelessWidget {
  const new({required this.page, required this.count, this.onRecognizeAgain});

  final int page;
  final int count;
  final VoidCallback? onRecognizeAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: Key('ocr-lost-$page'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    size: 18,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.ocrLostPlaces(page, count),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              if (onRecognizeAgain case final again?)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    key: Key('ocr-recognize-again-$page'),
                    onPressed: again,
                    child: Text(AppStrings.ocrRecognizeAgain(page)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
