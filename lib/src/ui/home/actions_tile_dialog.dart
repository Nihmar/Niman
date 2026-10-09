/// An actions tile's buttons, edited (#535): their order, the ones to add
/// and to remove, and each one opened in the action editor.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/home/action_editor.dart';
import 'package:niman/src/ui/home/home_icons.dart';
import 'package:niman/src/ui/strings.dart';

/// Edits [actions] over [controller]'s library; resolves to the new list,
/// or null when cancelled.
Future<List<HomeAction>?> showActionsTileDialog(
  BuildContext context, {
  required List<HomeAction> actions,
  required LibrarySession controller,
}) => showDialog<List<HomeAction>>(
  context: context,
  builder: (context) => _ActionsTileDialog(
    actions: actions,
    controller: controller,
    fullscreen: MediaQuery.sizeOf(context).width < wideBreakpoint,
  ),
);

final class _ActionsTileDialog extends StatefulWidget {
  const new({
    required this.actions,
    required this.controller,
    required this.fullscreen,
  });

  final List<HomeAction> actions;
  final LibrarySession controller;
  final bool fullscreen;

  @override
  State<_ActionsTileDialog> createState() => _ActionsTileDialogState();
}

final class _ActionsTileDialogState extends State<_ActionsTileDialog> {
  late final List<HomeAction> _actions = [...widget.actions];

  /// The paths the actions name that the library no longer holds.
  Set<String> _missing = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_check());
  }

  Future<void> _check() async {
    final missing = await widget.controller.missingPaths([
      for (final a in _actions) ...a.requiredPaths,
    ]);
    if (mounted) setState(() => _missing = missing);
  }

  /// An id no action of the tile has.
  String _freshId() {
    final rng = Random();
    while (true) {
      final id = 'a${rng.nextInt(1 << 20).toRadixString(36)}';
      if (_actions.every((a) => a.id != id)) return id;
    }
  }

  Future<void> _edit(int? at) async {
    final edited = await showActionEditor(
      context,
      action: at == null
          ? HomeAction(id: _freshId(), label: '', kind: HomeActionKind.newNote)
          : _actions[at],
      controller: widget.controller,
      missing: _missing,
    );
    if (edited == null || !mounted) return;
    setState(() {
      if (at == null) {
        _actions.add(edited);
      } else {
        _actions[at] = edited;
      }
    });
    unawaited(_check());
  }

  Widget _list() => ReorderableListView.builder(
    shrinkWrap: true,
    buildDefaultDragHandles: false,
    itemCount: _actions.length,
    onReorderItem: (from, to) =>
        setState(() => _actions.insert(to, _actions.removeAt(from))),
    itemBuilder: (context, i) {
      final action = _actions[i];
      final gone = action.requiredPaths.where(_missing.contains).firstOrNull;
      final scheme = Theme.of(context).colorScheme;
      return ListTile(
        key: ValueKey(action.id),
        contentPadding: EdgeInsets.zero,
        leading: ReorderableDragStartListener(
          index: i,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.drag_indicator),
          ),
        ),
        title: Row(
          children: [
            Icon(homeActionIcon(action), size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(homeActionLabel(action))),
          ],
        ),
        subtitle: Text(
          gone == null
              ? action.kind == null
                    ? ''
                    : homeActionKindName(action.kind!)
              : AppStrings.homeActionMissing(gone),
          style: gone == null ? null : TextStyle(color: scheme.error),
        ),
        // A kind a later build wrote can be moved and removed, not edited.
        onTap: action.kind == null ? null : () => unawaited(_edit(i)),
        trailing: IconButton(
          key: Key('home-action-remove-${action.id}'),
          tooltip: AppStrings.actionDelete,
          onPressed: () => setState(() => _actions.removeAt(i)),
          icon: const Icon(Icons.delete_outline),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final add = TextButton.icon(
      key: const Key('home-action-add'),
      onPressed: () => unawaited(_edit(null)),
      icon: const Icon(Icons.add),
      label: Text(AppStrings.homeActionAdd),
    );
    final save = FilledButton(
      key: const Key('home-actions-save'),
      onPressed: () => Navigator.pop(context, _actions),
      child: Text(AppStrings.actionSave),
    );
    final title = Text(AppStrings.homeTileActions);
    if (widget.fullscreen) {
      return Dialog.fullscreen(
        child: Scaffold(
          key: const Key('home-actions-dialog'),
          appBar: AppBar(
            leading: CloseButton(onPressed: () => Navigator.pop(context)),
            title: title,
            actions: [
              Padding(padding: const EdgeInsets.only(right: 12), child: save),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _list(),
              Align(alignment: Alignment.centerLeft, child: add),
            ],
          ),
        ),
      );
    }
    return AlertDialog(
      key: const Key('home-actions-dialog'),
      title: title,
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _list(),
              Align(alignment: Alignment.centerLeft, child: add),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.actionCancel),
        ),
        save,
      ],
    );
  }
}
