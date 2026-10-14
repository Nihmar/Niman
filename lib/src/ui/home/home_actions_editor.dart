/// An actions tile's buttons, edited in place (#535, #712).
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/home/action_editor.dart';
import 'package:niman/src/ui/home/home_icons.dart';
import 'package:niman/src/ui/strings.dart';

/// An actions tile's buttons as a list to edit (#535): dragged into
/// order, removed, opened in the action editor, added. The dialog's body,
/// and on a desktop the Home inspector's (#712); every change is told at
/// once through [onChanged].
final class HomeActionsEditor extends StatefulWidget {
  /// Edits [actions] over [controller]'s library.
  const new({
    required this.actions,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  /// The buttons as they start.
  final List<HomeAction> actions;

  /// The open library, for the editor and the missing paths.
  final LibrarySession controller;

  /// The buttons as they are now, after each change.
  final ValueChanged<List<HomeAction>> onChanged;

  @override
  State<HomeActionsEditor> createState() => _HomeActionsEditorState();
}

final class _HomeActionsEditorState extends State<HomeActionsEditor> {
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
    widget.onChanged(List.of(_actions));
    unawaited(_check());
  }

  Widget _list() => ReorderableListView.builder(
    shrinkWrap: true,
    buildDefaultDragHandles: false,
    itemCount: _actions.length,
    onReorderItem: (from, to) {
      setState(() => _actions.insert(to, _actions.removeAt(from)));
      widget.onChanged(List.of(_actions));
    },
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
          onPressed: () {
            setState(() => _actions.removeAt(i));
            widget.onChanged(List.of(_actions));
          },
          icon: const Icon(Icons.delete_outline),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _list(),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: const Key('home-action-add'),
          onPressed: () => unawaited(_edit(null)),
          icon: const Icon(Icons.add),
          label: Text(AppStrings.homeActionAdd),
        ),
      ),
    ],
  );
}
