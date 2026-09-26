/// Where a tour step finds the control it points at (#266).
///
/// A widget that can be pointed at wraps itself in a [TourTarget]; the
/// state owns a key and registers it under the target's id. An id may be
/// on screen more than once — the rail and the tab bar are the same
/// "navigation" step — so the registry holds a list per id and a step
/// takes the first one that is laid out; a control that is not there at
/// all (a hidden rail, a closed dock) registers nothing, and the step is
/// skipped.
///
/// Deliberately not a Riverpod provider: the wrappers sit deep in widgets
/// that widget tests pump on their own (the cheatsheet, the note chrome),
/// and a target is a piece of widget identity — nothing to scope, nothing
/// to override.
library;

import 'package:flutter/material.dart';

/// The registered keys, by target id, in mount order.
final Map<String, List<GlobalKey>> _targets = <String, List<GlobalKey>>{};

/// Marks [child] as the widget a tour step points at.
final class TourTarget extends StatefulWidget {
  /// Wraps [child] under [id].
  const new({required this.id, required this.child, super.key});

  /// One of the ids in `tour_steps.dart` (`TourTargets`).
  final String id;

  /// The control itself.
  final Widget child;

  @override
  State<TourTarget> createState() => _TourTargetState();
}

final class _TourTargetState extends State<TourTarget> {
  late final GlobalKey _key = GlobalKey(debugLabel: 'tour-${widget.id}');

  @override
  void initState() {
    super.initState();
    (_targets[widget.id] ??= <GlobalKey>[]).add(_key);
  }

  @override
  void dispose() {
    _targets[widget.id]?.remove(_key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}

/// The rectangle [id] occupies right now, in global coordinates, or null
/// when nothing is showing it.
///
/// Global, because the overlay is a route above the shell: the target's
/// own coordinates have to be carried up to the top of the window. The
/// first laid-out registration answers, so a duplicated id (the rail and
/// the tab bar) points at whichever one the layout is actually showing.
Rect? tourTargetRect(String id) {
  for (final key in _targets[id] ?? const <GlobalKey>[]) {
    final object = key.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.hasSize) continue;
    return object.localToGlobal(Offset.zero) & object.size;
  }
  return null;
}
