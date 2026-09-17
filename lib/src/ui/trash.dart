import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/history/history_labels.dart';
import 'package:niman/src/ui/settings_trash_history.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// Lists trash items and supports restoring / permanent deletion.
///
/// Flat rows like every other list in the app (issue #131): the only
/// `Card` list is gone. **Empty** sits in the app bar — the corner it
/// used to own is where every other screen puts *create* — and the
/// auto-empty setting rides at the bottom, reachable from the screen
/// it governs.
final class TrashScreen extends StatefulWidget {
  /// Creates the trash screen.
  const new({required this.controller, super.key});

  /// The session of the library whose trash this screen lists.
  final LibrarySession controller;

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

final class _TrashScreenState extends State<TrashScreen> {
  List<TrashItem>? _items;
  int _autoEmptyDays = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final controller = widget.controller;
    final ops = controller.ops;
    if (ops == null) return;
    final items = await ops.trashItems();
    final autoEmptyDays = await controller.trashAutoEmptyDays;
    if (mounted) {
      setState(() {
        _items = items;
        _autoEmptyDays = autoEmptyDays;
      });
    }
  }

  Future<void> _act(
    Future<void> Function(TrashItem) action,
    TrashItem item,
  ) async {
    setState(() => _busy = true);
    try {
      await action(item);
      await _load();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirmPermanently(TrashItem item) async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.trashDeletePermanently),
        content: Text(AppStrings.trashDeleteConfirm(item.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _act((item) => ops.deleteTrashPermanently(item.name), item);
  }

  Future<void> _confirmEmptyTrash() async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.trashEmptyAction),
        content: Text(AppStrings.trashEmptyConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.actionEmpty),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ops.emptyTrash();
      await _load();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Opens the auto-empty setting and re-reads it on the way back:
  /// the footer row shows its value, which the pushed screen changes.
  Future<void> _openAutoEmpty() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsTrashHistoryScreen(
          controller: widget.controller,
          highlight: const Key('trash-auto-empty-setting'),
        ),
      ),
    );
    if (mounted) unawaited(_load());
  }

  /// Where the item was deleted from: the parent folder, or the
  /// library root for a top-level note.
  static String _wasAt(String originalPath) {
    final parent = p.dirname(originalPath);
    return parent == '.'
        ? AppStrings.trashOriginalRoot
        : AppStrings.trashOriginalPath(parent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _items;
    final canEmpty = !_busy && items != null && items.isNotEmpty;
    final library = p.basename(widget.controller.root ?? '');
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.trashTitle),
            if (items != null)
              Text(
                '${AppStrings.trashItemCount(items.length)} · '
                '${AppStrings.settingsGroupLibrary(library)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          Tooltip(
            message: AppStrings.trashEmptyAction,
            child: TextButton(
              key: const Key('empty-trash-action'),
              onPressed: canEmpty ? _confirmEmptyTrash : null,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: Text(AppStrings.actionEmpty),
            ),
          ),
        ],
      ),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: items.isEmpty
                      ? Center(child: Text(AppStrings.trashEmpty))
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (context, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            // The day, written the way the history screen
                            // writes it (today, yesterday, "12 Sep")
                            // rather than the ISO date the string happened
                            // to start with.
                            final deletedOn = historyDay(
                              item.deletedAt,
                              DateTime.now(),
                            );
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                '${_wasAt(item.originalPath)}\n$deletedOn',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: AppStrings.actionRestore,
                                    icon: const Icon(Icons.restore),
                                    onPressed: _busy
                                        ? null
                                        : () => _act(
                                            (item) => widget.controller.ops!
                                                .restoreTrash(item.name),
                                            item,
                                          ),
                                  ),
                                  IconButton(
                                    tooltip: AppStrings.trashDeletePermanently,
                                    icon: Icon(
                                      Icons.delete_forever,
                                      color: theme.colorScheme.error,
                                    ),
                                    onPressed: _busy
                                        ? null
                                        : () => _confirmPermanently(item),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('trash-auto-empty-row'),
                  title: Text(AppStrings.trashAutoEmptyTitle),
                  subtitle: Text(AppStrings.trashAutoEmptySubtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.trashAutoEmptyValue(_autoEmptyDays),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: _openAutoEmpty,
                ),
              ],
            ),
    );
  }
}
