import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/link_preview/link_preview_card.dart';
import 'package:niman/src/ui/link_preview/link_preview_controller.dart';

/// Puts the link preview card over [child] when [controller] has one (#846):
/// an overlay entry anchored at the pointer, inside the window, below and to
/// its right where there is room and above or to its left where there is
/// not.
///
/// Closes the card on `Esc`, on a press anywhere outside it, and on anything
/// [closeOn] announces (the note's scrolls); it leaves what [child] does
/// alone, and draws nothing while no card is up.
final class LinkPreviewHost extends StatefulWidget {
  /// The card of [controller] over [child], its math typeset through
  /// [mathCache].
  const new({
    required this.controller,
    required this.mathCache,
    required this.child,
    this.closeOn,
    super.key,
  });

  /// Which card is up.
  final LinkPreviewController controller;

  /// The math render cache the card's note is typeset through.
  final MathCache mathCache;

  /// What the card goes over.
  final Widget child;

  /// What closes the card when it fires: the scroll positions of the note.
  final Listenable? closeOn;

  @override
  State<LinkPreviewHost> createState() => _LinkPreviewHostState();
}

final class _LinkPreviewHostState extends State<LinkPreviewHost> {
  final OverlayPortalController _portal = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.closeOn?.addListener(_onScrolled);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void didUpdateWidget(LinkPreviewHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
    if (!identical(oldWidget.closeOn, widget.closeOn)) {
      oldWidget.closeOn?.removeListener(_onScrolled);
      widget.closeOn?.addListener(_onScrolled);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    widget.closeOn?.removeListener(_onScrolled);
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    if (widget.controller.shown != null) {
      _portal.show();
    } else if (_portal.isShowing) {
      _portal.hide();
    }
  }

  void _onScrolled() => widget.controller.close();

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        widget.controller.shown != null) {
      widget.controller.close();
    }
    // The key is the note's as well: closing the card is not all it may do.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _card,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => widget.controller.close(),
        child: widget.child,
      ),
    );
  }

  Widget _card(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final shown = widget.controller.shown;
        final overlay = Overlay.of(context).context.findRenderObject();
        if (shown == null || overlay is! RenderBox || !overlay.hasSize) {
          return const SizedBox.shrink();
        }
        return CustomSingleChildLayout(
          delegate: _CardLayout(overlay.globalToLocal(shown.at)),
          child: LinkPreviewCard(
            preview: shown.preview,
            mathCache: widget.mathCache,
            onEnter: widget.controller.cardEntered,
            onExit: widget.controller.cardLeft,
          ),
        );
      },
    );
  }
}

/// Where the card stands: a hand's breadth off the pointer, kept inside the
/// window.
final class _CardLayout extends SingleChildLayoutDelegate {
  const new(this.pointer);

  /// The pointer, in the overlay's own coordinates.
  final Offset pointer;

  static const double _gap = 14;
  static const double _margin = 8;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = LinkPreviewCard.size.width;
    final height = LinkPreviewCard.size.height;
    return BoxConstraints.tight(
      Size(
        width.clamp(0, constraints.maxWidth - 2 * _margin),
        height.clamp(0, constraints.maxHeight - 2 * _margin),
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = pointer.dx + _gap;
    if (x + childSize.width > size.width - _margin) {
      x = pointer.dx - _gap - childSize.width;
    }
    var y = pointer.dy + _gap;
    if (y + childSize.height > size.height - _margin) {
      y = pointer.dy - _gap - childSize.height;
    }
    return Offset(
      x.clamp(_margin, size.width - childSize.width - _margin),
      y.clamp(_margin, size.height - childSize.height - _margin),
    );
  }

  @override
  bool shouldRelayout(_CardLayout oldDelegate) =>
      oldDelegate.pointer != pointer;
}
