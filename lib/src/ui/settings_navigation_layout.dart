/// Settings → Library → Navigation (#536): the order of the bar and the
/// rail, the destinations they show, the one the app opens on (#706), and
/// whether this device keeps its own.
///
/// The preview is the bar or the rail itself, drawn from the layout being
/// edited: what the shell will show, not a picture of it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/strings.dart';

/// The Navigation area.
final class SettingsNavigationLayoutScreen extends StatefulWidget {
  /// The area for [controller]'s library; [highlight] is the row the
  /// settings search landed on.
  const new({required this.controller, this.highlight, super.key});

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row to flash, or null.
  final Key? highlight;

  @override
  State<SettingsNavigationLayoutScreen> createState() =>
      _SettingsNavigationLayoutScreenState();
}

final class _SettingsNavigationLayoutScreenState
    extends State<SettingsNavigationLayoutScreen> {
  ({NavigationLayout? library, NavigationLayout? device})? _navigation;
  StreamSubscription<int>? _sessionEvents;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _sessionEvents = widget.controller.events.listen((_) => unawaited(_load()));
  }

  @override
  void dispose() {
    unawaited(_sessionEvents?.cancel());
    super.dispose();
  }

  Future<void> _load() async {
    final navigation = await widget.controller.ops?.navigation;
    if (navigation == null || !mounted) return;
    setState(() => _navigation = navigation);
  }

  NavigationLayout get _layout =>
      _navigation?.device ?? _navigation?.library ?? const NavigationLayout();

  bool get _onDevice => _navigation?.device != null;

  Future<void> _save(NavigationLayout layout, {required bool onDevice}) async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    await ops.setNavigation(layout, onDevice: onDevice);
    widget.controller.notify();
    await _load();
  }

  /// The layout with [placed] as the user left it.
  Future<void> _keep(
    List<({ShellDestination destination, bool hidden})> placed,
  ) => _save(
    _layout.keep([
      for (final p in placed) (name: p.destination.name, hidden: p.hidden),
    ]),
    onDevice: _onDevice,
  );

  @override
  Widget build(BuildContext context) {
    final navigation = _navigation;
    final theme = Theme.of(context);
    final placed = placedDestinations(_layout);
    final visible = visibleDestinations(_layout);
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final list = ReorderableListView(
      key: const Key('navigation-layout-list'),
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(bottom: 16),
      onReorderItem: (from, to) {
        final next = [...placed];
        next.insert(to, next.removeAt(from));
        unawaited(_keep(next));
      },
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              AppStrings.navigationIntro,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          HighlightRow(
            key: SettingsKeys.navigationScope,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(AppStrings.navigationScopeLibrary),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(AppStrings.navigationScopeDevice),
                  ),
                ],
                selected: {_onDevice},
                showSelectedIcon: false,
                onSelectionChanged: (choice) => unawaited(
                  choice.first
                      // The device starts from what it shows now.
                      ? _save(_layout, onDevice: true)
                      : _save(
                          navigation?.library ?? const NavigationLayout(),
                          onDevice: false,
                        ),
                ),
              ),
            ),
          ),
          _startRow(theme),
        ],
      ),
      footer: wide
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _preview(visible, wide: false),
            ),
      children: [
        for (final (i, p) in placed.indexed)
          ListTile(
            key: Key('navigation-row-${p.destination.name}'),
            leading: ReorderableDragStartListener(
              index: i,
              child: const Icon(Icons.drag_handle),
            ),
            title: Text(p.destination.label),
            trailing: lockedDestinations.contains(p.destination.name)
                ? Tooltip(
                    message: AppStrings.navigationAlwaysShown,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(Icons.lock_outline),
                    ),
                  )
                : Switch(
                    key: Key('navigation-switch-${p.destination.name}'),
                    value: !p.hidden,
                    // The last ones shown stay: a bar needs two (#667).
                    onChanged:
                        !p.hidden && visible.length <= minShownDestinations
                        ? null
                        : (shown) => unawaited(
                            _keep([
                              for (final q in placed)
                                if (q.destination == p.destination)
                                  (destination: q.destination, hidden: !shown)
                                else
                                  q,
                            ]),
                          ),
                  ),
          ),
      ],
    );
    return SettingsAreaShell(
      title: AppStrings.settingsAreaNavigation,
      controller: widget.controller,
      library: true,
      highlight: widget.highlight,
      body: navigation == null
          ? const SizedBox.shrink()
          : wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: list),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    // Room for every destination the rail can hold, the
                    // library switch and Settings: a rail button is 50 high.
                    height: 460,
                    child: _preview(visible, wide: true),
                  ),
                ),
              ],
            )
          : list,
    );
  }

  /// The destination the app opens on (#706), among the shown ones that
  /// can be; a chosen one hidden since says which took its place.
  Widget _startRow(ThemeData theme) {
    final layout = _layout;
    final starts = startDestinations(layout);
    final start = startDestination(layout);
    String? hiddenStart;
    if (layout.start case final name?) {
      for (final p in placedDestinations(layout)) {
        if (p.destination.name == name && p.destination.tab != start) {
          hiddenStart = p.destination.label;
        }
      }
    }
    return HighlightRow(
      key: SettingsKeys.navigationStart,
      child: ListTile(
        title: Text(AppStrings.navigationStart),
        subtitle: switch ((hiddenStart, startLabel(layout))) {
          (final hidden?, final shown?) => Text(
            AppStrings.navigationStartHidden(hidden, shown),
          ),
          _ => null,
        },
        trailing: start == null
            ? null
            : DropdownButton<ShellTab>(
                key: const Key('navigation-start'),
                value: start,
                items: [
                  for (final d in starts)
                    DropdownMenuItem(
                      key: Key('navigation-start-${d.name}'),
                      value: d.tab,
                      child: Text(d.label),
                    ),
                ],
                onChanged: (tab) {
                  if (tab == null) return;
                  final name = starts.firstWhere((d) => d.tab == tab).name;
                  unawaited(
                    _save(
                      // Files is the start a layout without one has.
                      layout.withStart(tab == ShellTab.files ? null : name),
                      onDevice: _onDevice,
                    ),
                  );
                },
              ),
      ),
    );
  }

  /// The bar or the rail as [visible] makes it, for looking at only.
  Widget _preview(List<ShellDestination> visible, {required bool wide}) =>
      ExcludeFocus(
        child: IgnorePointer(
          key: const Key('navigation-preview'),
          child: wide
              ? ShellRail(
                  destinations: visible,
                  current: visible.first.tab,
                  onDestinationSelected: (_) {},
                  onSwitchLibrary: () {},
                )
              : ShellTabBar(
                  destinations: visible,
                  current: visible.first.tab,
                  onDestinationSelected: (_) {},
                ),
        ),
      );
}
