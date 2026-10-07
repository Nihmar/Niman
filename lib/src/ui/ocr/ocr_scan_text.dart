import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ocr/ocr_job.dart';
import 'package:niman/src/ocr/ocr_sidecar_finder.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/ocr/ocr_text_pane.dart';
import 'package:niman/src/ui/ocr/ocr_text_toggle.dart';
import 'package:niman/src/ui/strings.dart';

/// A scan and its recognized text (#595): on a wide pane the Text pane
/// beside the scan, shown and hidden from the file's bar; on a narrow one
/// a Scan | Text switch at the top, the scan kept alive while the text is
/// read. A file with no text yet is just its scan, until a recognition
/// writes one.
final class OcrScanText extends StatefulWidget {
  /// The [scan] of the file at [path] (absolute), with its text.
  const new({
    required this.actions,
    required this.path,
    required this.scan,
    super.key,
  });

  /// The shell's recognition actions.
  final OcrFileActions actions;

  /// The file, absolute.
  final String path;

  /// The file's own view.
  final Widget scan;

  /// How wide the pane has to be for the text to sit beside the scan.
  static const double besideWidth = 720;

  @override
  State<OcrScanText> createState() => _OcrScanTextState();
}

final class _OcrScanTextState extends State<OcrScanText> {
  ({String path, String text})? _sidecar;
  bool _shown = true;
  bool _textSide = false;
  int? _loadedFor;

  String get _relative => widget.actions.relative(widget.path);

  @override
  void initState() {
    super.initState();
    widget.actions.queue.addListener(_onQueue);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(OcrScanText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actions.queue != widget.actions.queue) {
      oldWidget.actions.queue.removeListener(_onQueue);
      widget.actions.queue.addListener(_onQueue);
    }
    if (oldWidget.path != widget.path) {
      _sidecar = null;
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    widget.actions.queue.removeListener(_onQueue);
    super.dispose();
  }

  /// A recognition of this file that just wrote its text: read it again.
  void _onQueue() {
    final job = widget.actions.queue.jobFor(_relative);
    if (job == null || job.phase != OcrJobPhase.done) return;
    if (job.id == _loadedFor) return;
    _loadedFor = job.id;
    unawaited(_load());
  }

  Future<void> _load() async {
    final path = widget.path;
    final found = await findOcrSidecar(widget.actions.ops, _relative);
    if (!mounted || path != widget.path) return;
    setState(() => _sidecar = found);
  }

  @override
  Widget build(BuildContext context) {
    final sidecar = _sidecar;
    if (sidecar == null) return widget.scan;
    final text = OcrTextPane(
      path: sidecar.path,
      text: sidecar.text,
      onOpenAsNote: () => widget.actions.openNote(sidecar.path),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= OcrScanText.besideWidth) {
          return OcrTextToggle(
            shown: _shown,
            toggle: () => setState(() => _shown = !_shown),
            child: Row(
              children: [
                Expanded(child: widget.scan),
                if (_shown) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: (constraints.maxWidth * 0.4).clamp(280, 460),
                    child: text,
                  ),
                ],
              ],
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SegmentedButton<bool>(
                key: const Key('ocr-scan-text-switch'),
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(AppStrings.ocrScanTitle),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(AppStrings.ocrTextTitle),
                  ),
                ],
                selected: {_textSide},
                onSelectionChanged: (side) =>
                    setState(() => _textSide = side.single),
              ),
            ),
            Expanded(
              // The scan stays built while the text is read: back on it,
              // the reader finds the page where it was.
              child: IndexedStack(
                index: _textSide ? 1 : 0,
                children: [widget.scan, text],
              ),
            ),
          ],
        );
      },
    );
  }
}
