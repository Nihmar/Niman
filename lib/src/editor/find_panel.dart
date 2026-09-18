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
/// replace, Esc close); [NimanShortcutsActivatorsBuilder] adds the
/// classic Ctrl+H for replace on non-mac desktop, and lives here because
/// the find bar was the first thing that needed it. It has since grown
/// past find: the page keys and the word-wise keys are there too.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:re_editor/re_editor.dart';

/// The find/replace bar (see the library docs). [CodeEditor] calls the
/// builder with the note's find [controller] on every state change.
final class NimanFindPanel extends StatelessWidget
    implements PreferredSizeWidget {
  /// Creates the panel over [controller].
  const new({
    required this.controller,
    required this.readOnly,
    this.column = NoteColumn.off,
    super.key,
  });

  /// The note's column: the bar's rows keep to it (issue #171).
  final NoteColumn column;

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
          NoteColumnPadding(
            column: column,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _findRow(theme, value),
                if (value.replaceMode) _replaceRow(theme, value),
              ],
            ),
          ),
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
              decoration: InputDecoration(
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
              decoration: InputDecoration(
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

/// The editor's shortcuts: the package defaults, the page keys the package
/// forgets to bind, the word-wise keys Windows and Linux actually use, and
/// the classic Ctrl+H for the replace bar (non-mac desktop — mac keeps
/// Cmd+Alt+F).
final class NimanShortcutsActivatorsBuilder
    extends CodeShortcutsActivatorsBuilder {
  /// Creates the builder.
  const new();

  /// Word-wise navigation on the keys Windows and Linux use for it.
  ///
  /// re_editor's non-mac map is the mac one with the modifier left alone
  /// (`code_shortcuts.dart`, `_kDefaultCommonCodeShortcutsActivators`):
  /// word jump sits on **Alt**+Arrow, and `Ctrl`+Arrow — the key everything
  /// else on these two platforms uses for it — is spent on line start/end,
  /// which `Home` and `End` already do. Word-wise *selection* is then
  /// `Shift`+`Alt`+Arrow, so `Ctrl`+`Shift`+Arrow is bound to nothing at all
  /// and the gesture simply does not exist in the editor (device report,
  /// 2026-09-18). `Alt`+Arrow is not a text gesture here either: on Windows
  /// it is Back and Forward.
  ///
  /// So the whole set is replaced rather than added to — leaving `Ctrl`+Arrow
  /// on line start/end would shadow the new binding, since `SingleActivator`
  /// has no value equality and the first entry registered for a key wins.
  ///
  /// The package's forward/backward names are inverted in *both* the map and
  /// the controller (`extendSelectionToWordBoundaryForward` walks the extent
  /// left), which cancels out. The pairing below keeps that cancellation:
  /// it is the package's, not a second mistake.
  static const Map<CodeShortcutType, List<ShortcutActivator>> _wordWise = {
    CodeShortcutType.cursorMoveLineStart: [
      SingleActivator(LogicalKeyboardKey.home),
    ],
    CodeShortcutType.cursorMoveLineEnd: [
      SingleActivator(LogicalKeyboardKey.end),
    ],
    CodeShortcutType.cursorMoveWordBoundaryBackward: [
      SingleActivator(LogicalKeyboardKey.arrowLeft, control: true),
    ],
    CodeShortcutType.cursorMoveWordBoundaryForward: [
      SingleActivator(LogicalKeyboardKey.arrowRight, control: true),
    ],
    CodeShortcutType.selectionExtendWordBoundaryForward: [
      SingleActivator(LogicalKeyboardKey.arrowLeft, control: true, shift: true),
    ],
    CodeShortcutType.selectionExtendWordBoundaryBackward: [
      SingleActivator(
        LogicalKeyboardKey.arrowRight,
        control: true,
        shift: true,
      ),
    ],
  };

  @override
  List<ShortcutActivator>? build(CodeShortcutType type) {
    final defaults = const DefaultCodeShortcutsActivatorsBuilder().build(type);
    if (!kIsMacOS) {
      final wordWise = _wordWise[type];
      if (wordWise != null) return wordWise;
    }
    // The package ships the page-move intents and their action wiring but
    // binds no key to them, and the controller methods behind them are
    // `// TODO` stubs (re_editor 0.10.0): Niman binds the keys here and
    // implements the move in `NoteEditor.shortcutOverrideActions`.
    if (type == CodeShortcutType.cursorMovePageUp ||
        type == CodeShortcutType.cursorMovePageDown) {
      final key = type == CodeShortcutType.cursorMovePageUp
          ? LogicalKeyboardKey.pageUp
          : LogicalKeyboardKey.pageDown;
      return [...?defaults, SingleActivator(key)];
    }
    if (!kIsMacOS && type == CodeShortcutType.replace) {
      return [
        ...?defaults,
        const SingleActivator(LogicalKeyboardKey.keyH, control: true),
      ];
    }
    return defaults;
  }
}
