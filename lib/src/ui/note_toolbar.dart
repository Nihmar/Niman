import 'package:flutter/material.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/ui/note_edit_commands.dart';
import 'package:niman/src/ui/note_view_chrome.dart';

/// The formatting toolbar of an open note (T-UI-08): pure markdown commands
/// applied through the surface, and the undo and redo buttons in front
/// (#1336).
///
/// It rebuilds when the formats at the caret change — the surface publishes
/// them into one notifier, read off the caret's line, so a pressed button
/// stays pressed until it is toggled off (T-WYS-06, #246) — and when the
/// history says there is something to undo or redo, or not any more.
final class NoteToolbar extends StatelessWidget {
  /// The toolbar of the note on [surface], pressing through [commands].
  const new({
    required this.commands,
    required this.surface,
    required this.activeFormats,
    required this.layout,
    required this.refocus,
    this.dense = false,
    super.key,
  });

  /// What each button does.
  final NoteEditCommands commands;

  /// The note's surface, null before one is open: no history buttons then.
  final MarkdownSurfaceController? surface;

  /// The formats on at the caret.
  final ValueNotifier<Set<ToolbarItem>> activeFormats;

  /// Which buttons show, in order.
  final ToolbarLayout layout;

  /// Gives the editor the keyboard back after an undo or a redo.
  final VoidCallback refocus;

  /// The desktop's dense bar (#173).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final actions = commands.toolbarActions();
    final menus = commands.toolbarMenus();
    final surface = this.surface;
    return ListenableBuilder(
      listenable: Listenable.merge([
        activeFormats,
        ?surface?.history.availability,
      ]),
      builder: (context, _) => NoteToolbarBar(
        dense: dense,
        actions: actions,
        menus: menus,
        active: activeFormats.value,
        layout: layout,
        history: surface == null
            ? null
            : (
                undo: surface.history.canUndo
                    ? () {
                        surface.undo();
                        refocus();
                      }
                    : null,
                redo: surface.history.canRedo
                    ? () {
                        surface.redo();
                        refocus();
                      }
                    : null,
              ),
      ),
    );
  }
}
