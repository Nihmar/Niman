import 'package:flutter/material.dart';
import 'package:niman/src/ui/dock/dock_toggles.dart';
import 'package:niman/src/ui/strings.dart';

/// The note row's side panel button: outline while the panel is off, filled
/// while it is on (docked, or laid over the note).
final class DockToggle extends StatefulWidget {
  /// A button that registers with [toggles] while it is on screen.
  const new({
    required this.toggles,
    required this.on,
    required this.onPressed,
    super.key,
  });

  /// Where the button lists itself.
  final DockToggles toggles;

  /// Whether the panel shows.
  final bool on;

  /// Shows or hides the panel.
  final VoidCallback onPressed;

  @override
  State<DockToggle> createState() => _DockToggleState();
}

final class _DockToggleState extends State<DockToggle> {
  @override
  void initState() {
    super.initState();
    widget.toggles.add(context);
  }

  @override
  void dispose() {
    widget.toggles.remove(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('dock-toggle'),
    tooltip: AppStrings.sidePanelTooltip,
    isSelected: widget.on,
    icon: const Icon(Icons.view_sidebar_outlined),
    selectedIcon: const Icon(Icons.view_sidebar),
    onPressed: widget.onPressed,
  );
}
