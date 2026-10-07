/// A button that copies a code block's code (#541), kept at the top right
/// of the part of the block on screen: a block taller than the pane has it
/// wherever it is scrolled to, not only at its top.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/ui/strings.dart';

/// How far in from the block's corner the button stands.
const double codeCopyMargin = 4;

/// The button's side.
const double codeCopySize = 32;

/// The copy button: an outline icon, a tick for a moment once copied.
final class CodeCopyButton extends StatefulWidget {
  /// Copies what [code] answers when pressed.
  const new({required this.code, super.key});

  /// The block's code, read when the button is pressed.
  final String Function() code;

  @override
  State<CodeCopyButton> createState() => _CodeCopyButtonState();
}

final class _CodeCopyButtonState extends State<CodeCopyButton> {
  Timer? _done;

  @override
  void dispose() {
    _done?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code()));
    if (!mounted) return;
    _done?.cancel();
    setState(() {
      _done = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _done = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final copied = _done != null;
    return SizedBox.square(
      dimension: codeCopySize,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          key: const Key('code-copy'),
          tooltip: copied ? AppStrings.codeCopied : AppStrings.copyCode,
          iconSize: 18,
          padding: EdgeInsets.zero,
          color: scheme.onSurfaceVariant,
          onPressed: _copy,
          icon: Icon(copied ? Icons.check : Icons.copy_outlined),
        ),
      ),
    );
  }
}

/// [child], a code block in a scrolling list, with a [CodeCopyButton] at
/// the top right of the part of it inside the scroll view: it follows the
/// scroll down a tall block, and stops at the block's bottom.
final class CodeCopyFrame extends StatefulWidget {
  /// Frames [child], whose code [code] answers.
  const new({required this.code, required this.child, super.key});

  /// The block's code, read when the button is pressed.
  final String Function() code;

  /// The block as drawn.
  final Widget child;

  @override
  State<CodeCopyFrame> createState() => _CodeCopyFrameState();
}

final class _CodeCopyFrameState extends State<CodeCopyFrame> {
  /// How far down the block the button stands.
  final ValueNotifier<double> _top = ValueNotifier<double>(0);
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _position)) {
      _position?.removeListener(_place);
      _position = position?..addListener(_place);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _place());
  }

  @override
  void dispose() {
    _position?.removeListener(_place);
    _top.dispose();
    super.dispose();
  }

  /// Puts the button below the scroll view's top edge when the block starts
  /// above it, and no lower than the block's bottom.
  ///
  /// Where the block starts is asked of the viewport's layout, as the offset
  /// that would bring it to the top: a scroll notifies before the frame
  /// lays the list out again, and the block's place on screen is the last
  /// frame's then.
  void _place() {
    final position = _position;
    final box = context.findRenderObject();
    if (!mounted || position == null || !position.hasPixels) return;
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    final above = position.pixels - viewport.getOffsetToReveal(box, 0).offset;
    final lowest = box.size.height - codeCopySize - 2 * codeCopyMargin;
    _top.value = above.clamp(0.0, lowest < 0 ? 0.0 : lowest);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _place());
    return Stack(
      children: <Widget>[
        widget.child,
        ValueListenableBuilder<double>(
          valueListenable: _top,
          builder: (context, top, button) => Positioned(
            top: top + codeCopyMargin,
            right: codeCopyMargin,
            child: button!,
          ),
          child: CodeCopyButton(code: widget.code),
        ),
      ],
    );
  }
}
