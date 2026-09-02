import 'dart:async';

import 'package:copist/src/library/session.dart';
import 'package:flutter/material.dart';

/// Library-level settings (M1: trash toggle, re-index, close).
///
/// Global theme/layout settings arrive with the M6 token system.
final class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({required this.controller, super.key});

  /// The session of the library whose settings this screen edits.
  final LibrarySession controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

final class _SettingsScreenState extends State<SettingsScreen> {
  bool? _trash;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    final enabled = await ops.trashEnabled;
    if (mounted) {
      setState(() => _trash = enabled);
    }
  }

  Future<void> _toggleTrash(bool value) async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    await ops.setTrashEnabled(enabled: value);
    widget.controller.notify();
    if (mounted) {
      setState(() => _trash = value);
    }
  }

  Future<void> _rescan() async {
    try {
      await widget.controller.rescanNow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Re-index complete')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Trash'),
            subtitle: const Text(
              'Deletions move to .trash/ (off = hard delete)',
            ),
            value: _trash ?? true,
            onChanged: _toggleTrash,
          ),
          const Divider(),
          ListTile(
            title: const Text('Library path'),
            subtitle: Text(controller.root ?? ''),
          ),
          ListTile(
            title: const Text('Re-index now'),
            leading: const Icon(Icons.refresh),
            onTap: _rescan,
          ),
          ListTile(
            title: const Text('Close library'),
            leading: const Icon(Icons.link_off),
            onTap: () async {
              await controller.close();
              if (mounted) {
                Navigator.of(this.context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
