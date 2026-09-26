/// An embedded file, drawn: an image, or the placeholder that says why not.
///
/// The preview has drawn embeds since T-M3-07, but through the package's
/// element-builder seam, which is going away with the preview. This is the same
/// rendering in the render layer, where the unified engine can reach it, and it
/// keeps the two decisions the preview made on purpose:
///
/// * **a non-image is not an error.** `![[notes.md]]` is a link to a file that
///   happens to be an embed; it renders as a muted `![[target]]` rather than as
///   a broken image, because the note is fine;
/// * **the placeholder is the note's own text.** A reader looking at a missing
///   image sees what the note said, so it can be fixed from what is on screen.
///
/// Resolution is the caller's: the resolver answers with an absolute path, and
/// a null answer means the file is not there. The renderer does no IO of its
/// own beyond opening the image it was handed, which is what keeps this widget
/// usable from a test with no filesystem at all.
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:niman/src/preview/aspect_image.dart';

/// An embed, resolved and drawn.
final class EmbedView extends StatefulWidget {
  /// Draws the embed of [target], showing [display] when it cannot be drawn.
  const new({
    required this.target,
    required this.display,
    this.onResolve,
    this.placeholder,
    this.image,
    super.key,
  });

  /// What the note pointed at, as written.
  final String target;

  /// What to show when the target is not an image that can be drawn.
  final String display;

  /// What to show instead of the picture, when the note wrote something other
  /// than an embed: a Markdown image shows `![alt](src)` as it was written, and
  /// an embed shows `![[target]]`.
  final String? placeholder;

  /// Resolves [target] to an absolute path, or null. Null resolver = nothing
  /// can be resolved, so the placeholder is drawn without asking.
  final Future<String?> Function(String target)? onResolve;

  /// The picture itself, already decoded.
  ///
  /// An export that read the bytes on its own hands it here: the raster
  /// fallback runs without a frame loop, so a resolution round — and the
  /// decode behind it — could not be waited for, and the picture is drawn
  /// on the first build instead (#63, H3).
  final ui.Image? image;

  /// Image extensions an embed renders inline.
  static final RegExp imageExtensions = RegExp(
    r'\.(png|jpe?g|gif|webp|bmp)$',
    caseSensitive: false,
  );

  @override
  State<EmbedView> createState() => EmbedViewState();
}

/// The embed's state, public so a test can wait for the resolution.
final class EmbedViewState extends State<EmbedView> {
  String? _path;
  bool _settled = false;

  /// Whether the resolver has answered.
  bool get settled => _settled;

  /// The path the resolver answered with, or null.
  String? get path => _path;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(EmbedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _path = null;
      _settled = false;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final resolve = widget.onResolve;
    if (resolve == null) {
      if (mounted) setState(() => _settled = true);
      return;
    }
    String? path;
    try {
      path = await resolve(widget.target);
    } on Object {
      // A resolver that throws is a missing file, not a broken note.
      path = null;
    }
    if (mounted && (path != _path || !_settled)) {
      setState(() {
        _path = path;
        _settled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    if (image != null) return _picture(context, image);
    final path = _path;
    if (path == null || !EmbedView.imageExtensions.hasMatch(widget.target)) {
      return _placeholder(context);
    }
    return AspectImage(
      provider: FileImage(File(path)),
      fit: BoxFit.fitWidth,
      errorBuilder: (context, error, stack) => _placeholder(context),
    );
  }

  /// The already-decoded picture, with the box [AspectImage] would reserve
  /// for it: its own ratio, capped for the surface it is drawn on.
  Widget _picture(BuildContext context, ui.Image image) {
    final ratio = image.height <= 0 ? 1.0 : image.width / image.height;
    return Align(
      alignment: Alignment.centerLeft,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: heightCapFor(context)),
        child: AspectRatio(
          aspectRatio: ratio,
          child: RawImage(image: image, fit: BoxFit.fitWidth),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      widget.placeholder ?? '![[${widget.display}]]',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      softWrap: true,
    );
  }
}
