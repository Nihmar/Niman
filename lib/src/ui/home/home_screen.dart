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
import 'package:niman/src/home/home_file.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/ui/home/home_column.dart';
import 'package:niman/src/ui/home/home_column_editor.dart';
import 'package:niman/src/ui/home/home_edit_dialogs.dart';
import 'package:niman/src/ui/home/home_editing.dart';
import 'package:niman/src/ui/home/home_grid.dart';
import 'package:niman/src/ui/home/home_grid_editor.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_scope_switch.dart';
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

  /// The Home shown, and edited; null with no library open.
  late final HomeEditing? _home = switch (widget.host.controller.ops) {
    final ops? => HomeEditing(ops),
    null => null,
  };

  /// Whether the grid is being edited, in place.
  bool _editing = false;

  /// Bumped on every reload: the tiles read the library again.
  int _revision = 0;

  /// Whether the library changed while the Home was not on screen.
  bool _stale = false;

  StreamSubscription<int>? _events;
  StreamSubscription<Set<String>>? _synced;
  Timer? _settling;

  @override
  void initState() {
    super.initState();
    _events = widget.host.controller.events.listen((_) => _changed());
    // A sync that brings only the Home's file moves no note: the index
    // says nothing, so the file is heard here (#680).
    _synced = widget.host.controller.sync?.localChanges.listen((paths) {
      if (paths.contains(HomeFile.filePath)) _changed();
    });
    widget.tab.addListener(_tabChanged);
    _home?.addListener(_homeChanged);
    unawaited(_home?.load());
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
    _home?.removeListener(_homeChanged);
    _home?.dispose();
    unawaited(_events?.cancel());
    unawaited(_synced?.cancel());
    _settling?.cancel();
    super.dispose();
  }

  void _homeChanged() => setState(() {});

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
    // An edit in progress stays: the read waits for its writes, and one
    // made while reading outdates what was read (#684).
    unawaited(_home?.load());
  }

  Future<void> _editColumn(HomeEditing home) async {
    await openHomeColumnEditor(context, home, widget.host.controller);
    if (mounted) unawaited(home.load());
  }

  @override
  Widget build(BuildContext context) {
    final home = _home;
    if (home == null || !home.loaded) return const SizedBox.shrink();
    final layout = home.layout;
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= HomeGridMetrics.minWidth;
        Widget tile(HomeTile t, {bool fit = false}) => HomeTileView(
          tile: t,
          host: widget.host,
          revision: _revision,
          fit: fit,
        );
        final editing = wide && _editing;
        return SingleChildScrollView(
          key: const Key('home-screen'),
          padding: wide
              ? const EdgeInsets.fromLTRB(20, 8, 20, 20)
              : const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                _GridHeader(
                  home: home,
                  editing: editing,
                  onEdit: (on) => setState(() => _editing = on),
                )
              else
                _ColumnHeader(onEdit: () => unawaited(_editColumn(home))),
              if (editing)
                HomeGridEditor(
                  editing: home,
                  controller: widget.host.controller,
                  tile: tile,
                )
              else if (wide)
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

/// Today, said under the title or beside it.
String _today() => formatDateTime(DateTime.now(), 'dddd D MMMM');

/// The wide Home's title, today's date and the way into editing; while
/// editing, where the Home is kept, a reset and *Done*.
final class _GridHeader extends StatelessWidget {
  const new({required this.home, required this.editing, required this.onEdit});

  final HomeEditing home;
  final bool editing;
  final ValueChanged<bool> onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Text(
                  editing ? AppStrings.homeEdit : AppStrings.tabHome,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(width: 12),
                if (!editing) Text(_today(), style: muted),
                const Spacer(),
                if (editing) ...[
                  HomeScopeSwitch(editing: home),
                  const SizedBox(width: 8),
                  TextButton(
                    key: const Key('home-reset'),
                    onPressed: () async {
                      if (await confirmHomeReset(context)) await home.reset();
                    },
                    child: Text(AppStrings.homeReset),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const Key('home-edit-done'),
                    onPressed: () => onEdit(false),
                    icon: const Icon(Icons.check),
                    label: Text(AppStrings.homeEditDone),
                  ),
                ] else
                  TextButton.icon(
                    key: const Key('home-edit'),
                    onPressed: () => onEdit(true),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(AppStrings.homeEdit),
                  ),
              ],
            ),
          ),
          if (editing) Text(AppStrings.homeGridHint, style: muted),
        ],
      ),
    );
  }
}

/// The phone's line over the column: today's date (the app bar says
/// *Home*) and the way into editing.
final class _ColumnHeader extends StatelessWidget {
  const new({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            _today(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        IconButton(
          key: const Key('home-edit'),
          tooltip: AppStrings.homeEdit,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    );
  }
}
