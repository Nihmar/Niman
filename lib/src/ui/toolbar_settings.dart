import 'dart:async';

import 'package:copist/src/editor/toolbar_item.dart';
import 'package:copist/src/editor/toolbar_layout.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// The editor-toolbar settings (T-TB-05): the buttons as a reorderable
/// list, each with an eye that shows or hides it.
///
/// Every change is written immediately — there is no save button — and
/// the session is notified, so an open editor picks the new toolbar up
/// without being reopened.
final class ToolbarSettingsScreen extends StatefulWidget {
  /// Creates the screen over [controller]'s stored layout.
  const new({required this.controller, super.key});

  /// The session holding the setting.
  final LibrarySession controller;

  @override
  State<ToolbarSettingsScreen> createState() => _ToolbarSettingsScreenState();
}

final class _ToolbarSettingsScreenState extends State<ToolbarSettingsScreen> {
  ToolbarLayout _layout = ToolbarLayout.defaults;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final stored = await widget.controller.editorToolbar;
    if (!mounted) return;
    setState(() {
      _layout = ToolbarLayout.parse(stored);
      _loaded = true;
    });
  }

  Future<void> _save(ToolbarLayout layout) async {
    setState(() => _layout = layout);
    await widget.controller.setEditorToolbar(layout.encode());
    widget.controller.notify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.toolbarSettingsTitle),
        actions: [
          TextButton(
            key: const Key('toolbar-reset'),
            onPressed: _loaded
                ? () => unawaited(_save(ToolbarLayout.defaults))
                : null,
            child: Text(AppStrings.toolbarResetOrder),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    AppStrings.toolbarSettingsHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: _layout.order.length,
                    onReorderItem: (oldIndex, newIndex) => unawaited(
                      _save(_layout.reorderedItem(oldIndex, newIndex)),
                    ),
                    itemBuilder: (context, index) =>
                        _row(theme, _layout.order[index], index),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _row(ThemeData theme, ToolbarItem item, int index) {
    final visible = _layout.isVisible(item);
    // A hidden button stays in place, dimmed: the eye is a state, not a
    // removal, so putting it back does not mean finding its slot again.
    final color = visible
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    return ListTile(
      key: ValueKey(item.id),
      leading: Icon(item.icon, color: color),
      title: Text(item.label, style: TextStyle(color: color)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('toolbar-visibility-${item.id}'),
            tooltip: visible
                ? AppStrings.toolbarHideButton
                : AppStrings.toolbarShowButton,
            icon: Icon(
              visible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: color,
            ),
            onPressed: () =>
                unawaited(_save(_layout.withVisible(item, visible: !visible))),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Icon(
              Icons.drag_indicator,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
