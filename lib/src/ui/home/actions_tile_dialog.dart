/// An actions tile's buttons, edited (#535): their order, the ones to add
/// and to remove, and each one opened in the action editor.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/device_shape.dart';
import 'package:niman/src/ui/home/home_actions_editor.dart';
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
    fullscreen: !isWideShell(context),
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
  late List<HomeAction> _actions = widget.actions;

  Widget _editor() => HomeActionsEditor(
    actions: widget.actions,
    controller: widget.controller,
    onChanged: (actions) => _actions = actions,
  );

  @override
  Widget build(BuildContext context) {
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
            children: [_editor()],
          ),
        ),
      );
    }
    return AlertDialog(
      key: const Key('home-actions-dialog'),
      title: title,
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(child: _editor()),
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
