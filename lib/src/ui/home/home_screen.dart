/// The Home (#535): the library's tiles, on a grid on a wide screen and in
/// a column on a phone.
///
/// It reads the library while it shows: a change to the library while the
/// Home is behind another tab only marks it stale, and the Home catches up
/// when it shows again. Writing in the Files tab never pays for a Home
/// nobody is looking at.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/ui/home/home_column.dart';
import 'package:niman/src/ui/home/home_grid.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_tile_view.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/strings.dart';

/// The Home tab's body.
final class HomeScreen extends StatefulWidget {
  /// The Home of [host]'s library; [tab] says which tab is on screen.
  const new({required this.host, required this.tab, super.key});

  /// The shell's side of the Home.
  final HomeHost host;

  /// The tab on screen: the phone keeps its bodies built across a switch,
  /// so the Home hears of one here rather than through a rebuild.
  final ValueListenable<ShellTab> tab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends State<HomeScreen> {
  /// How long a burst of library changes is let settle before a reload.
  static const _settle = Duration(milliseconds: 300);

  HomeLayout? _layout;

  /// Bumped on every reload: the tiles read the library again.
  int _revision = 0;

  /// Whether the library changed while the Home was not on screen.
  bool _stale = false;

  StreamSubscription<int>? _events;
  Timer? _settling;

  @override
  void initState() {
    super.initState();
    _events = widget.host.controller.events.listen((_) => _changed());
    widget.tab.addListener(_tabChanged);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(HomeScreen old) {
    super.didUpdateWidget(old);
    if (old.tab != widget.tab) {
      old.tab.removeListener(_tabChanged);
      widget.tab.addListener(_tabChanged);
    }
  }

  @override
  void dispose() {
    widget.tab.removeListener(_tabChanged);
    unawaited(_events?.cancel());
    _settling?.cancel();
    super.dispose();
  }

  bool get _visible => widget.tab.value == ShellTab.home;

  void _tabChanged() {
    if (_visible && _stale) {
      _stale = false;
      _reload();
    }
  }

  void _changed() {
    if (!_visible) {
      _stale = true;
      return;
    }
    _settling?.cancel();
    _settling = Timer(_settle, _reload);
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _revision++);
    unawaited(_load());
  }

  Future<void> _load() async {
    final ops = widget.host.controller.ops;
    if (ops == null) return;
    final home = await ops.home;
    if (!mounted) return;
    setState(() {
      _layout = home.device ?? home.library ?? HomeLayout.defaults;
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = _layout;
    if (layout == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= HomeGridMetrics.minWidth;
        Widget tile(HomeTile t, {bool fit = false}) => HomeTileView(
          tile: t,
          host: widget.host,
          revision: _revision,
          fit: fit,
        );
        return SingleChildScrollView(
          key: const Key('home-screen'),
          padding: wide
              ? const EdgeInsets.fromLTRB(20, 8, 20, 20)
              : const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide) const _HomeHeader(),
              if (wide)
                HomeGrid(layout: layout.settled(), tile: tile)
              else
                HomeColumn(layout: layout, tile: tile),
            ],
          ),
        );
      },
    );
  }
}

/// The wide Home's title and today's date: the phone's app bar says it.
final class _HomeHeader extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Text(AppStrings.tabHome, style: theme.textTheme.titleLarge),
          const SizedBox(width: 12),
          Text(
            formatDateTime(DateTime.now(), 'dddd D MMMM'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
