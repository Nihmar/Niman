/// The phone's expandable "+" FAB and the scrim its menu draws (T-UI-05;
/// split out of `shell.dart` for #710): whether the menu is open, the list
/// folder its *New list note* names, and where the button is, so the
/// scrim's reveal circle grows out of it.
///
/// The button lives in the Scaffold's FAB slot and the scrim over the
/// body, two siblings: this holds what both read, and notifies as the
/// menu opens and closes.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/new_item_fab.dart';

/// The state of the "+" menu, and the two widgets that show it.
final class ShellFab extends ChangeNotifier {
  /// Creates the menu; [listFolder] reads the configured list folder.
  new({required this.listFolder});

  /// The configured list folder, read each time the menu opens (#131).
  final Future<String> Function() listFolder;

  /// Whether the menu (New note / New folder minis) is expanded.
  bool get expanded => _expanded;
  bool _expanded = false;

  /// The list folder the *New list note* entry names (issue #131): loaded
  /// when the menu opens, so the label is honest without a session read on
  /// every build.
  String? _listFolder;

  /// Where the main FAB is, so the scrim's reveal circle is centered on
  /// its icon. Written from the FAB's paint, read when the scrim builds.
  Offset? _anchor;

  /// The height of the screen's body, between the bars: the room the
  /// button and its menu share. Written from layout, read when the button
  /// next builds (the menu opening is one) — like [_anchor], never a
  /// `setState`.
  double? _room;

  /// The room the button's menu may take, margins above and below it
  /// kept — none, not less than none, on a body shorter than the margins;
  /// null before the body has been laid out.
  double? get _menuRoom {
    final room = _room;
    return room == null ? null : math.max(0, room - 2 * _margin);
  }

  /// The gap the Scaffold keeps between its FAB and the edges of its body.
  static const double _margin = 16;

  bool _disposed = false;

  /// Opens the menu, or closes it.
  void toggle() {
    // Opening the menu loads the list folder for the label; the setting
    // is read once per opening, not once per build.
    if (!_expanded) unawaited(_loadListFolder());
    _expanded = !_expanded;
    notifyListeners();
  }

  /// Closes the menu, saying so.
  void close() {
    _expanded = false;
    notifyListeners();
  }

  /// Closes the menu without saying so: for a caller that is rebuilding
  /// anyway.
  void collapse() => _expanded = false;

  Future<void> _loadListFolder() async {
    final folder = await listFolder();
    if (_disposed) return;
    _listFolder = folder;
    notifyListeners();
  }

  /// The "+" and its minis; each entry closes the menu before it runs.
  Widget button({
    required VoidCallback onNewNote,
    required VoidCallback onJournalToday,
    required VoidCallback onNewListNote,
    required VoidCallback onNewAudioNote,
    required VoidCallback onNewSlides,
    required VoidCallback onNewFromTemplate,
    required VoidCallback onNewFolder,
    required VoidCallback onCaptureWebPage,
  }) {
    VoidCallback closing(VoidCallback action) => () {
      close();
      action();
    };
    return NewItemFab(
      maxHeight: _menuRoom,
      onAnchor: (center) => _anchor = center,
      expanded: _expanded,
      listFolder: _listFolder,
      onToggle: toggle,
      onNewNote: closing(onNewNote),
      onJournalToday: closing(onJournalToday),
      onNewListNote: closing(onNewListNote),
      onNewAudioNote: closing(onNewAudioNote),
      onNewSlides: closing(onNewSlides),
      onNewFromTemplate: closing(onNewFromTemplate),
      onNewFolder: closing(onNewFolder),
      onCaptureWebPage: closing(onCaptureWebPage),
    );
  }

  /// Measures the body the button floats over, for the menu to fit in
  /// (#849). The Scaffold hands its FAB the whole screen to grow in and
  /// then sets it above the bottom bar, so a menu taller than the body
  /// ends above the top of the screen.
  ///
  /// Always wrapped, never toggled, for the reason [withScrim] gives.
  Widget measuring(Widget body) => LayoutBuilder(
    builder: (context, constraints) {
      _room = constraints.maxHeight;
      return body;
    },
  );

  /// Covers [child] with the menu's scrim: a circle that grows out of the
  /// main FAB icon, dims the body, and closes the menu on any tap (the
  /// FABs live in the Scaffold's FAB slot, above this layer, so they stay
  /// tappable). Always mounted; inert while collapsed.
  ///
  /// [enabled] is false on the tabs that have no expandable FAB. Not an
  /// optimisation: the scrim resolves the FAB's anchor key during layout,
  /// and since the Files and Todo tabs share one FAB slot, a scrim left
  /// mounted on Todo reaches for an anchor that tab does not have.
  ///
  /// Never toggle this wrapper around a kept-alive subtree (like the tab
  /// stack): swapping between the bare child and the [Stack] reparents it
  /// and remounts every state inside. The Files slot is always wrapped;
  /// hiding it via [Offstage] skips layout, so the anchor is only
  /// resolved while Files is visible.
  Widget withScrim(Widget child, {bool enabled = true}) {
    if (!enabled) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        FabScrim(anchor: _anchor, expanded: _expanded, onClose: close),
      ],
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
