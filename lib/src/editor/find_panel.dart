/// The classic in-editor find & replace (T-M2-xx: requested during the
/// M3 verification pass — "the classic one every editor has").
///
/// re_editor ships the machinery — [CodeFindController]: literal search on
/// a persistent isolate (so a 931K note never janks), every-match
/// highlighting, current-match navigation with auto-scroll, replace-one /
/// replace-all through the normal undoable edit path — and this panel is
/// the app's own face over it: the two-row bar that [CodeEditor] reserves
/// above the text area while the find is open, in the app's strings and
/// theme. A zero preferred size keeps the editor untouched while closed.
///
/// The editor's default shortcuts apply (Ctrl/Cmd+F find, Ctrl/Cmd+Alt+F
/// replace, Esc close); [CopistShortcutsActivatorsBuilder] adds the
/// classic Ctrl+H for replace on non-mac desktop.
library;

import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';

/// The find/replace bar (see the library docs). [CodeEditor] calls the
/// builder with the note's find [controller] on every state change.
final class CopistFindPanel extends StatelessWidget
    implements PreferredSizeWidget {
  /// Creates the panel over [controller].
  const CopistFindPanel({
    required this.controller,
    required this.readOnly,
    super.key,
  });

  /// The find state + actions (the note's own [CodeFindController]).
  final CodeFindController controller;

  /// Whether the editor is read-only (the bar still allows searching).
  final bool readOnly;

  /// Height of one row of the bar.
  static const double _rowHeight = 44;

  @override
  Size get preferredSize => Size(
    double.infinity,
    controller.value == null
        ? 0
        : _rowHeight * (controller.value!.replaceMode ? 2 : 1),
  );

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    if (value == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _findRow(theme, value),
          if (value.replaceMode) _replaceRow(theme, value),
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }

  Widget _findRow(ThemeData theme, CodeFindValue value) {
    final result = value.result;
    final label = result == null
        ? (value.searching ? '…' : '0')
        : '${result.index + 1}/${result.matches.length}';
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          const SizedBox(width: 4),
          IconButton(
            key: const Key('editor-find-mode'),
            tooltip: value.replaceMode
                ? AppStrings.editorFindCloseTooltip
                : AppStrings.editorFindReplaceModeTooltip,
            icon: Icon(
              value.replaceMode
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 20,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: controller.toggleMode,
          ),
          Expanded(
            child: TextField(
              key: const Key('editor-find-input'),
              controller: controller.findInputController,
              focusNode: controller.findInputFocusNode,
              style: theme.textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: AppStrings.editorFindHint,
                border: InputBorder.none,
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                if (result != null) controller.nextMatch();
              },
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
          _iconButton(
            key: const Key('editor-find-case'),
            tooltip: AppStrings.editorFindCaseTooltip,
            icon: Icons.text_fields,
            active: value.option.caseSensitive,
            theme: theme,
            onPressed: controller.toggleCaseSensitive,
          ),
          _iconButton(
            key: const Key('editor-find-prev'),
            tooltip: AppStrings.editorFindPreviousTooltip,
            icon: Icons.keyboard_arrow_up,
            theme: theme,
            onPressed: result == null ? null : controller.previousMatch,
          ),
          _iconButton(
            key: const Key('editor-find-next'),
            tooltip: AppStrings.editorFindNextTooltip,
            icon: Icons.keyboard_arrow_down,
            theme: theme,
            onPressed: result == null ? null : controller.nextMatch,
          ),
          _iconButton(
            key: const Key('editor-find-close'),
            tooltip: AppStrings.editorFindCloseTooltip,
            icon: Icons.close,
            theme: theme,
            onPressed: controller.close,
          ),
        ],
      ),
    );
  }

  Widget _replaceRow(ThemeData theme, CodeFindValue value) {
    final result = value.result;
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: TextField(
              key: const Key('editor-replace-input'),
              controller: controller.replaceInputController,
              focusNode: controller.replaceInputFocusNode,
              style: theme.textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: AppStrings.editorReplaceHint,
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) {
                if (result != null) controller.replaceMatch();
              },
            ),
          ),
          _iconButton(
            key: const Key('editor-replace-one'),
            tooltip: AppStrings.editorReplaceOneTooltip,
            icon: Icons.find_replace,
            theme: theme,
            onPressed: result == null ? null : controller.replaceMatch,
          ),
          _iconButton(
            key: const Key('editor-replace-all'),
            tooltip: AppStrings.editorReplaceAllTooltip,
            icon: Icons.done_all,
            theme: theme,
            onPressed: result == null ? null : controller.replaceAllMatches,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _iconButton({
    required Key key,
    required String tooltip,
    required IconData icon,
    required ThemeData theme,
    VoidCallback? onPressed,
    bool active = false,
  }) {
    return IconButton(
      key: key,
      tooltip: tooltip,
      icon: Icon(
        icon,
        size: 18,
        color: active ? theme.colorScheme.primary : null,
      ),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}

/// The editor's shortcuts, defaults plus the classic Ctrl+H for the
/// replace bar (non-mac desktop — mac keeps Cmd+Alt+F).
final class CopistShortcutsActivatorsBuilder
    extends CodeShortcutsActivatorsBuilder {
  /// Creates the builder.
  const CopistShortcutsActivatorsBuilder();

  @override
  List<ShortcutActivator>? build(CodeShortcutType type) {
    final defaults = const DefaultCodeShortcutsActivatorsBuilder().build(
      type,
    );
    if (!kIsMacOS && type == CodeShortcutType.replace) {
      return [
        ...?defaults,
        const SingleActivator(LogicalKeyboardKey.keyH, control: true),
      ];
    }
    return defaults;
  }
}
