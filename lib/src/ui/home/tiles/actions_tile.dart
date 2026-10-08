/// The Home's actions tile (#535): one button per action, each a function
/// the app already has with its parameters set.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_icons.dart';
import 'package:niman/src/ui/home/home_tile_frame.dart';

/// A group of action buttons.
final class ActionsTile extends StatelessWidget {
  /// Buttons for [actions], run through [host].
  const new({required this.host, required this.actions, super.key});

  /// The shell's side of the Home.
  final HomeHost host;

  /// The tile's actions, in order.
  final List<HomeAction> actions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final action in actions)
            // A kind a later build wrote is kept in the file, not shown.
            if (action.kind != null)
              FilledButton.icon(
                key: Key('home-action-${action.id}'),
                style: homeTileButtonStyle(context),
                onPressed: () => host.runAction(action),
                icon: Icon(homeActionIcon(action), size: 18),
                label: Text(
                  action.asks
                      ? '${homeActionLabel(action)}…'
                      : homeActionLabel(action),
                ),
              ),
        ],
      ),
    );
  }
}
