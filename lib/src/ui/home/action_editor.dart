/// One Home action, edited (#535): what it does, its label and icon, and
/// what it needs set in advance — a template, a folder, the note's name and
/// its fields, each fixed or asked.
///
/// A dialog on a wide window, a full page on a phone.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/folder_picker.dart';
import 'package:niman/src/ui/home/action_field_rows.dart';
import 'package:niman/src/ui/home/home_icons.dart';
import 'package:niman/src/ui/note_picker.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/template_picker.dart';

/// Edits [action] over [controller]'s library; resolves to the edited
/// action, or null when cancelled. [missing] are the paths the library no
/// longer holds, said where the action names them.
Future<HomeAction?> showActionEditor(
  BuildContext context, {
  required HomeAction action,
  required LibrarySession controller,
  Set<String> missing = const {},
}) {
  final fullscreen = MediaQuery.sizeOf(context).width < wideBreakpoint;
  return showDialog<HomeAction>(
    context: context,
    builder: (context) => _ActionEditor(
      action: action,
      controller: controller,
      missing: missing,
      fullscreen: fullscreen,
    ),
  );
}

final class _ActionEditor extends StatefulWidget {
  const new({
    required this.action,
    required this.controller,
    required this.missing,
    required this.fullscreen,
  });

  final HomeAction action;
  final LibrarySession controller;
  final Set<String> missing;
  final bool fullscreen;

  @override
  State<_ActionEditor> createState() => _ActionEditorState();
}

final class _ActionEditorState extends State<_ActionEditor> {
  late HomeActionKind _kind = widget.action.kind ?? HomeActionKind.newNote;
  late final TextEditingController _label = TextEditingController(
    text: widget.action.label,
  );
  late String _icon = widget.action.icon;
  late String? _template = widget.action.template;
  late String? _folder = widget.action.folder;
  late String? _path = widget.action.path;
  late bool _open = widget.action.open;
  late final ActionFieldRows _fields = ActionFieldRows(
    name: widget.action.name,
    fields: widget.action.fields,
  );
  late final TextEditingController _project = TextEditingController(
    text: widget.action.project ?? '',
  );
  late final TextEditingController _context = TextEditingController(
    text: widget.action.context ?? '',
  );

  LibrarySession get _controller => widget.controller;

  @override
  void dispose() {
    _label.dispose();
    _fields.dispose();
    _project.dispose();
    _context.dispose();
    super.dispose();
  }

  /// What a save would keep; the template and the note only where the
  /// kind uses them, so a kind changed leaves nothing stale behind.
  HomeAction get _edited {
    String? text(TextEditingController box) =>
        box.text.trim().isEmpty ? null : box.text.trim();
    return HomeAction(
      id: widget.action.id,
      label: _label.text.trim(),
      kind: _kind,
      icon: _icon,
      template: _kind == HomeActionKind.newNote ? _template : null,
      folder: switch (_kind) {
        HomeActionKind.newNote || HomeActionKind.capture => _folder,
        _ => null,
      },
      name: _fields.name,
      fields: _kind == HomeActionKind.newNote ? _fields.fields : const {},
      open: _open,
      project: _kind == HomeActionKind.addTask ? text(_project) : null,
      context: _kind == HomeActionKind.addTask ? text(_context) : null,
      path: _kind == HomeActionKind.openNote ? _path : null,
      extra: widget.action.extra,
    );
  }

  /// An action that cannot run is not saved: one that opens a note needs
  /// the note.
  bool get _complete => _kind != HomeActionKind.openNote || _path != null;

  void _save() => Navigator.pop(context, _edited);

  Future<void> _pickTemplate() async {
    final source = await _controller.templateSource;
    if (source == null) return;
    final templates = await source.templates();
    final folder = await source.folder;
    if (!mounted) return;
    final chosen = await showTemplatePicker(
      context,
      templates: templates,
      folder: folder,
    );
    if (chosen != null) setState(() => _template = chosen.path);
  }

  Future<void> _pickFolder() async {
    final ops = _controller.ops;
    if (ops == null) return;
    final folders = await _controller.folders();
    if (!mounted) return;
    final picked = await showFolderPicker(
      context,
      title: AppStrings.homeActionFolder,
      folders: folders,
      ops: ops,
      current: _folder,
      // A capture's empty folder is the capture folder, not the root
      // (#682): the root is offered where it is what empty means.
      allowRoot: _kind != HomeActionKind.capture,
    );
    if (picked != null) setState(() => _folder = picked);
  }

  Future<void> _pickNote() async {
    final picked = await showNotePicker(
      context,
      controller: _controller,
      title: AppStrings.homeActionNote,
      currentPath: _path,
    );
    if (picked != null) setState(() => _path = picked);
  }

  /// A path's line: what it is, or what is wrong with it.
  Widget _pathTile({
    required Key key,
    required String title,
    required String? path,
    required String empty,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final gone = path != null && widget.missing.contains(path);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        gone ? AppStrings.homeActionMissing(path) : path ?? empty,
        style: gone ? TextStyle(color: scheme.error) : null,
      ),
      leading: gone
          ? Icon(Icons.warning_amber_outlined, color: scheme.error)
          : null,
      trailing: path == null || onClear == null
          ? const Icon(Icons.chevron_right)
          : IconButton(
              tooltip: AppStrings.actionClear,
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
      onTap: onTap,
    );
  }

  List<Widget> _body() {
    final kind = _kind;
    final defaultLabel = homeActionLabel(
      HomeAction(id: '', label: '', kind: kind, path: _path),
    );
    return [
      DropdownButtonFormField<HomeActionKind>(
        key: const Key('home-action-kind'),
        initialValue: kind,
        decoration: InputDecoration(labelText: AppStrings.homeActionKind),
        items: [
          for (final k in HomeActionKind.values)
            DropdownMenuItem(value: k, child: Text(homeActionKindName(k))),
        ],
        onChanged: (k) => setState(() => _kind = k ?? kind),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('home-action-label'),
        controller: _label,
        decoration: InputDecoration(
          labelText: AppStrings.homeActionLabel,
          hintText: defaultLabel,
        ),
      ),
      const SizedBox(height: 12),
      Text(AppStrings.homeActionIcon),
      const SizedBox(height: 4),
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final MapEntry(key: name, value: icon)
              in homeActionIcons.entries)
            IconButton(
              key: Key('home-action-icon-$name'),
              isSelected:
                  (_icon.isEmpty ? defaultActionIcon(kind) : _icon) == name,
              onPressed: () => setState(() => _icon = name),
              icon: Icon(icon),
            ),
        ],
      ),
      const SizedBox(height: 8),
      ...switch (kind) {
        HomeActionKind.newNote => [
          _pathTile(
            key: const Key('home-action-template'),
            title: AppStrings.homeActionTemplate,
            path: _template,
            empty: AppStrings.homeActionNoTemplate,
            onTap: () => unawaited(_pickTemplate()),
            onClear: () => setState(() => _template = null),
          ),
          _pathTile(
            key: const Key('home-action-folder'),
            title: AppStrings.homeActionFolder,
            path: (_folder ?? '').isEmpty ? null : _folder,
            empty: AppStrings.libraryRoot,
            onTap: () => unawaited(_pickFolder()),
            onClear: () => setState(() => _folder = null),
          ),
          const SizedBox(height: 8),
          ActionFieldEditor(rows: _fields),
          SwitchListTile(
            key: const Key('home-action-open'),
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.homeActionOpenAfter),
            value: _open,
            onChanged: (open) => setState(() => _open = open),
          ),
        ],
        HomeActionKind.addTask => [
          TextField(
            key: const Key('home-action-project'),
            controller: _project,
            decoration: InputDecoration(
              labelText: AppStrings.homeActionProject,
              prefixText: '+',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('home-action-context'),
            controller: _context,
            decoration: InputDecoration(
              labelText: AppStrings.homeActionContext,
              prefixText: '@',
            ),
          ),
        ],
        HomeActionKind.openNote => [
          _pathTile(
            key: const Key('home-action-note'),
            title: AppStrings.homeActionNote,
            path: _path,
            empty: AppStrings.homeActionNoNote,
            onTap: () => unawaited(_pickNote()),
          ),
        ],
        HomeActionKind.capture => [
          _pathTile(
            key: const Key('home-action-folder'),
            title: AppStrings.homeActionFolder,
            path: (_folder ?? '').isEmpty ? null : _folder,
            empty: AppStrings.homeActionCaptureFolder,
            onTap: () => unawaited(_pickFolder()),
            onClear: () => setState(() => _folder = null),
          ),
        ],
        HomeActionKind.journal => const <Widget>[],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(AppStrings.homeActionEdit);
    final save = FilledButton(
      key: const Key('home-action-save'),
      onPressed: _complete ? _save : null,
      child: Text(AppStrings.actionSave),
    );
    if (widget.fullscreen) {
      return Dialog.fullscreen(
        child: Scaffold(
          key: const Key('home-action-editor'),
          appBar: AppBar(
            leading: CloseButton(onPressed: () => Navigator.pop(context)),
            title: title,
            actions: [
              Padding(padding: const EdgeInsets.only(right: 12), child: save),
            ],
          ),
          body: ListView(padding: const EdgeInsets.all(16), children: _body()),
        ),
      );
    }
    return AlertDialog(
      key: const Key('home-action-editor'),
      title: title,
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _body(),
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
