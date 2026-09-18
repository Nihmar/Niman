/// The editor's Tools sheet (#136): one button, a list of tools.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/editor_tool.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/strings.dart';

/// Shows the tools the editor offers; resolves to the one picked, or
/// null when the sheet was dismissed.
///
/// Every tool is listed, always. One that cannot run on this note right
/// now is greyed, with the reason under it, rather than left out: a row
/// that comes and goes is a row nobody learns is there, and the writer
/// is owed the reason at the moment they look for it rather than after
/// they tap.
Future<EditorTool?> showEditorToolsSheet(
  BuildContext context, {
  required Set<EditorTool> available,
}) {
  return showActionSheet<EditorTool>(
    context,
    sheetKey: const Key('editor-tools-sheet'),
    title: AppStrings.editorToolsTitle,
    items: (context) => [
      for (final tool in EditorTool.values)
        ListTile(
          key: Key('editor-tool-${tool.name}'),
          enabled: available.contains(tool),
          leading: Icon(tool.icon),
          title: Text(tool.label),
          subtitle: Text(
            available.contains(tool)
                ? tool.description
                : tool.unavailableReason,
          ),
          onTap: available.contains(tool)
              ? () => Navigator.of(context).pop(tool)
              : null,
        ),
    ],
  );
}
