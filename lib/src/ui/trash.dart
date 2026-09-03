import 'dart:async';

import 'package:copist/src/library/note_ops.dart';
import 'package:copist/src/library/session.dart';
import 'package:flutter/material.dart';

/// Lists trash items and supports restoring / permanent deletion.
final class TrashScreen extends StatefulWidget {
  /// Creates the trash screen.
  const TrashScreen({required this.controller, super.key});

  /// The session of the library whose trash this screen lists.
  final LibrarySession controller;

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

final class _TrashScreenState extends State<TrashScreen> {
  List<TrashItem>? _items;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    final items = await ops.trashItems();
    if (mounted) {
      setState(() => _items = items);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
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
        title: const Text('Delete permanently'),
        content: Text(
          '${item.name} will be deleted permanently (no restore)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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
        title: const Text('Empty trash'),
        content: const Text(
          'This deletes everything in the trash folder permanently, '
          'including items Copist did not put there.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Empty'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: const Text('Trash')),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('Trash is empty'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final deletedOn =
                        item.deletedAt.toIso8601String().substring(0, 10);
                    return Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          'was: ${item.originalPath}\n$deletedOn',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Restore',
                              icon: const Icon(Icons.restore),
                              onPressed: _busy
                                  ? null
                                  : () =>
                                      _act(
                                        (item) =>
                                            widget.controller.ops!
                                                .restoreTrash(item.name),
                                        item,
                                      ),
                            ),
                            IconButton(
                              tooltip: 'Delete permanently',
                              icon: const Icon(Icons.delete_forever),
                              onPressed: _busy
                                  ? null
                                  : () => _confirmPermanently(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: items != null && items.isNotEmpty
          ? FloatingActionButton(
              tooltip: 'Empty trash',
              onPressed: _busy ? null : _confirmEmptyTrash,
              child: const Icon(Icons.delete_sweep),
            )
          : null,
    );
  }
}
