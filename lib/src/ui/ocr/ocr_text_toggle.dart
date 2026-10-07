import 'package:flutter/widgets.dart';

/// Whether a scan's Text pane is shown, for the file bar's button that
/// shows and hides it (#595). Only where the file has a recognized text.
final class OcrTextToggle extends InheritedWidget {
  /// The toggle: the pane [shown], flipped by [toggle].
  const new({
    required this.shown,
    required this.toggle,
    required super.child,
    super.key,
  });

  /// Whether the Text pane is on screen.
  final bool shown;

  /// Shows or hides it.
  final VoidCallback toggle;

  /// The toggle above [context], or null where the file has no text.
  static OcrTextToggle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OcrTextToggle>();

  @override
  bool updateShouldNotify(OcrTextToggle oldWidget) => shown != oldWidget.shown;
}
