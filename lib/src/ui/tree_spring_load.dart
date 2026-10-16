/// Spring-loaded folders (#1071): a drag that dwells on a closed folder
/// opens it, so a target inside it can be reached; the folders opened that
/// way close again once the drag ends anywhere but inside them.
library;

import 'dart:async';

import 'package:niman/src/core/files.dart';

/// The folders a drag opens by dwelling on them, for one tree or grid.
final class TreeSpringLoad {
  /// Opens folders through [toggle], which flips a folder's open state;
  /// [isOpen] says what the state is now.
  new({
    required this.isOpen,
    required this.toggle,
    this.dwell = const Duration(milliseconds: 600),
  });

  /// Whether the folder at the path is open.
  final bool Function(String path) isOpen;

  /// Opens the folder at the path if closed, closes it if open.
  final void Function(String path) toggle;

  /// How long the pointer stays on a closed folder before it opens.
  final Duration dwell;

  final Set<String> _opened = <String>{};
  Timer? _timer;
  String? _hovered;
  String? _droppedInto;

  /// The folders this drag has opened and not closed again.
  Set<String> get opened => Set.unmodifiable(_opened);

  /// The pointer is over the closed folder at [path]: it opens after
  /// [dwell] unless the pointer leaves first.
  void hover(String path) {
    if (isOpen(path)) return;
    _timer?.cancel();
    _hovered = path;
    _timer = Timer(dwell, () {
      _timer = null;
      _hovered = null;
      if (isOpen(path)) return;
      _opened.add(path);
      toggle(path);
    });
  }

  /// The pointer left the folder at [path].
  void leave(String path) {
    if (_hovered != path) return;
    _timer?.cancel();
    _timer = null;
    _hovered = null;
  }

  /// A drop landed in [folder] (`''` the root): the folders opened on the
  /// way to it, and it, stay open.
  void dropped(String folder) {
    _droppedInto = folder;
    leave(folder);
  }

  /// The drag is over: the folders it opened close, but those the drop
  /// landed in or under.
  void finish() {
    _timer?.cancel();
    _timer = null;
    _hovered = null;
    final into = _droppedInto;
    _droppedInto = null;
    final opened = _opened.toList();
    _opened.clear();
    // Deepest first: a folder closes before the one that holds it.
    opened.sort((a, b) => b.length.compareTo(a.length));
    for (final path in opened) {
      final kept = into != null && into.isNotEmpty && _holds(path, into);
      if (!kept && isOpen(path)) toggle(path);
    }
  }

  /// Whether [folder] is [path] or inside it.
  static bool _holds(String path, String folder) =>
      path == folder || isUnder(path, folder);

  /// Stops the dwell for good.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
