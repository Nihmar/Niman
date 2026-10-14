import 'package:flutter/material.dart';
import 'package:niman/src/ui/pointer_menu.dart';

/// Puts the pointer's menus (`pointerMenuTheme`) into the theme below it.
///
/// Placed in `MaterialApp.builder`, above the navigator and so above every
/// route and menu: the theme it reads is the one the app is drawn with, its
/// text theme localized, which a theme built before the app exists is not.
final class PointerMenuScope extends StatelessWidget {
  /// Wraps [child].
  const new({required this.child, super.key});

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Theme(data: pointerMenuTheme(Theme.of(context)), child: child);
}
