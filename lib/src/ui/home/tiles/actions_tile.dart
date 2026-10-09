/// The Home's actions tile (#535): one button per action, each a function
/// the app already has with its parameters set.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_icons.dart';
import 'package:niman/src/ui/home/home_tile_frame.dart';
import 'package:niman/src/ui/home/home_tile_loader.dart';
import 'package:niman/src/ui/strings.dart';

/// A group of action buttons.
///
/// An action whose template or note the library no longer holds is marked,
/// its tooltip saying what is gone: pressed, it says so rather than half
/// running.
final class ActionsTile extends StatelessWidget {
  /// Buttons for [actions], run through [host], checked on [revision].
  const new({
    required this.host,
    required this.actions,
    required this.revision,
    super.key,
  });

  /// The shell's side of the Home.
  final HomeHost host;

  /// The tile's actions, in order.
  final List<HomeAction> actions;

  /// The Home's revision.
  final int revision;

  @override
  Widget build(BuildContext context) {
    final paths = [for (final a in actions) ...a.requiredPaths];
    return HomeTileLoader<Set<String>>(
      // New actions are new paths to check.
      key: ValueKey(paths.join('\n')),
      revision: revision,
      initial: (value: const <String>{}),
      load: () => host.controller.missingPaths(paths),
      builder: (context, gone) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final action in actions)
              // A kind a later build wrote is kept in the file, not shown.
              if (action.kind != null) _button(context, action, gone),
          ],
        ),
      ),
    );
  }

  Widget _button(BuildContext context, HomeAction action, Set<String> gone) {
    final missing = action.requiredPaths.where(gone.contains).firstOrNull;
    final label = action.asks
        ? '${homeActionLabel(action)}…'
        : homeActionLabel(action);
    final button = FilledButton.icon(
      key: Key('home-action-${action.id}'),
      style: homeTileButtonStyle(context),
      onPressed: () => host.runAction(action),
      icon: missing == null
          ? Icon(homeActionIcon(action), size: 18)
          : Icon(
              Icons.warning_amber_outlined,
              key: Key('home-action-broken-${action.id}'),
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
      label: Text(label),
    );
    if (missing == null) return button;
    return Tooltip(
      message: AppStrings.homeActionMissing(missing),
      child: button,
    );
  }
}
