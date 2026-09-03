import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/library/session.dart';
import 'package:file_picker/file_picker.dart';
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
  bool? _debugLogs;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final controller = widget.controller;
    final ops = controller.ops;
    if (ops == null) return;
    final enabled = await ops.trashEnabled;
    final debug = await controller.debugLogsEnabled;
    if (mounted) {
      setState(() {
        _trash = enabled;
        _debugLogs = debug;
      });
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

  Future<void> _toggleDebugLogs(bool value) async {
    final controller = widget.controller;
    await controller.setDebugLogsEnabled(enabled: value);
    if (mounted) {
      setState(() => _debugLogs = value);
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

  /// Opens a save dialog letting the user choose where the debug log goes,
  /// and writes the buffered lines (+ a context header) to the chosen file.
  Future<void> _exportLog() async {
    final controller = widget.controller;
    final lines = AppLog.lines();
    if (lines.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The debug log buffer is empty')),
        );
      }
      return;
    }
    final now = DateTime.now();
    final stamp = _fileStamp(now);
    final phase = 'phase: ${controller.phase.name}, '
        'lastError: ${controller.lastError ?? '-'}';
    final content = <String>[
      '# Copist debug log',
      '# exported: ${now.toIso8601String()}',
      '# library: ${controller.root ?? '(none)'}',
      '# $phase',
      '',
      ...lines,
    ].join('\n');
    try {
      final uri = await FilePicker.saveFile(
        fileName: 'copist-debug-log-$stamp.txt',
        bytes: Uint8List.fromList(utf8.encode(content)),
        mimeType: 'text/plain',
        dialogTitle: 'Export debug log',
      );
      if (uri == null) return; // The user canceled; nothing to report.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug log exported to $uri')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $error')),
        );
      }
    }
  }

  static String _fileStamp(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    String three(int v) => v.toString().padLeft(3, '0');
    return '${dt.year.toString().padLeft(4, '0')}-${two(dt.month)}'
        '-${two(dt.day)}-${two(dt.hour)}${two(dt.minute)}${two(dt.second)}'
        '.${three(dt.millisecond)}';
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
          SwitchListTile(
            title: const Text('Debug logs'),
            subtitle: const Text(
              'Record app events in an in-memory buffer',
            ),
            value: _debugLogs ?? true,
            onChanged: _toggleDebugLogs,
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
            title: const Text('Export debug log'),
            leading: const Icon(Icons.save_alt),
            subtitle: const Text(
              'Save the recorded events to a file you choose',
            ),
            onTap: _exportLog,
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
