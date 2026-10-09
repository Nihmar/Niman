/// The load a Home tile (#535) runs for what it shows, again whenever the
/// Home's revision moves.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';

/// Loads a [T] and builds from it; what was loaded last stays on screen
/// while the next load runs, so a refresh never flashes empty.
final class HomeTileLoader<T> extends StatefulWidget {
  /// Runs [load] now and whenever [revision] changes, and draws its answer
  /// with [builder]; until the first answer, [initial], or nothing.
  const new({
    required this.revision,
    required this.load,
    required this.builder,
    this.initial,
    super.key,
  });

  /// What to draw before the first answer, in a record so a null [T] can
  /// be one; null draws nothing.
  final ({T value})? initial;

  /// Bumped by the Home when the library changed.
  final int revision;

  /// What the tile reads.
  final Future<T> Function() load;

  /// Draws the answer.
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<HomeTileLoader<T>> createState() => _HomeTileLoaderState<T>();
}

final class _HomeTileLoaderState<T> extends State<HomeTileLoader<T>> {
  static const _log = AppLogger(name: 'home');

  late ({T value})? _loaded = widget.initial;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(HomeTileLoader<T> old) {
    super.didUpdateWidget(old);
    if (old.revision != widget.revision) unawaited(_load());
  }

  Future<void> _load() async {
    final token = ++_token;
    try {
      final value = await widget.load();
      if (!mounted || token != _token) return;
      setState(() => _loaded = (value: value));
    } on Object catch (error) {
      _log.warning('a tile could not load: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loaded = _loaded;
    return loaded == null
        ? const SizedBox.shrink()
        : widget.builder(context, loaded.value);
  }
}
