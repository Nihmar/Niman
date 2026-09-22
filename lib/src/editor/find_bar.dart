/// The find & replace bar over a surface's own find state (T-WYS-08, #245).
///
/// The same face as the legacy source editor's panel, over whichever
/// [FindBarModel] the surface keeps — the WYSIWYG's over the Quill document,
/// the unified surface's over its buffer — instead of re_editor's find
/// machinery: the query row, the replace row, the match counter and the
/// navigation buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/ui/strings.dart';

/// What a find bar shows and drives: the state and the actions of one
/// surface's find.
abstract interface class FindBarModel implements Listenable {
  /// Whether the bar is open.
  bool get visible;

  /// Whether the bar shows its replace row.
  bool get replaceMode;

  /// Whether the query is matched case-sensitively.
  bool get caseSensitive;

  /// How many matches the query has.
  int get matchCount;

  /// The 0-based index of the current match, or -1.
  int get matchIndex;

  /// The query the bar edits.
  TextEditingController get findInput;

  /// The query field's focus, when the model moves it itself; null lets the
  /// field take the focus as it appears.
  FocusNode? get findFocus;

  /// The replacement the bar edits.
  TextEditingController get replaceInput;

  /// Runs the search again: the query changed.
  void search();

  /// Flips the replace row.
  void toggleMode();

  /// Flips case sensitivity.
  void toggleCaseSensitive();

  /// Goes to the next match, wrapping around.
  void nextMatch();

  /// Goes to the previous match, wrapping around.
  void previousMatch();

  /// Replaces the current match.
  void replaceMatch();

  /// Replaces every match.
  void replaceAllMatches();

  /// Closes the bar.
  void close();
}

/// The bar over [controller].
final class FindBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates the bar over [controller]; [keyPrefix] names its fields and
  /// buttons (`wysiwyg-find-input`, …).
  const new({
    required this.controller,
    this.column = NoteColumn.off,
    this.keyPrefix = 'wysiwyg',
    super.key,
  });

  /// The find state and actions.
  final FindBarModel controller;

  /// What the bar's keys start with.
  final String keyPrefix;

  /// The note's column: the bar's rows keep to it (issue #171).
  final NoteColumn column;

  /// Height of one row of the bar.
  static const double _rowHeight = 44;

  @override
  Size get preferredSize => Size(
    double.infinity,
    controller.visible && controller.replaceMode ? _rowHeight * 2 : _rowHeight,
  );

  @override
  Widget build(BuildContext context) {
    if (!controller.visible) return const SizedBox.shrink();
    final theme = Theme.of(context);
    // The keys every find bar answers from its fields: Escape closes it,
    // Shift+Enter and F3 walk the matches.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): controller.close,
        const SingleActivator(LogicalKeyboardKey.enter, shift: true):
            controller.previousMatch,
        const SingleActivator(LogicalKeyboardKey.f3): controller.nextMatch,
        const SingleActivator(LogicalKeyboardKey.f3, shift: true):
            controller.previousMatch,
      },
      child: _bar(theme),
    );
  }

  Widget _bar(ThemeData theme) {
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
                _findRow(theme),
                if (controller.replaceMode) _replaceRow(theme),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }

  Widget _findRow(ThemeData theme) {
    final count = controller.matchCount;
    final label = count == 0 ? '0' : '${controller.matchIndex + 1}/$count';
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          const SizedBox(width: 4),
          IconButton(
            key: Key('$keyPrefix-find-mode'),
            tooltip: controller.replaceMode
                ? AppStrings.editorFindCloseTooltip
                : AppStrings.editorFindReplaceModeTooltip,
            icon: Icon(
              controller.replaceMode
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 20,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: controller.toggleMode,
          ),
          Expanded(
            child: TextField(
              key: Key('$keyPrefix-find-input'),
              controller: controller.findInput,
              focusNode: controller.findFocus,
              autofocus: true,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: AppStrings.editorFindHint,
                border: InputBorder.none,
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onChanged: (_) => controller.search(),
              onSubmitted: (_) => controller.nextMatch(),
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
          _iconButton(
            key: Key('$keyPrefix-find-case'),
            tooltip: AppStrings.editorFindCaseTooltip,
            icon: Icons.text_fields,
            active: controller.caseSensitive,
            theme: theme,
            onPressed: controller.toggleCaseSensitive,
          ),
          _iconButton(
            key: Key('$keyPrefix-find-prev'),
            tooltip: AppStrings.editorFindPreviousTooltip,
            icon: Icons.keyboard_arrow_up,
            theme: theme,
            onPressed: count == 0 ? null : controller.previousMatch,
          ),
          _iconButton(
            key: Key('$keyPrefix-find-next'),
            tooltip: AppStrings.editorFindNextTooltip,
            icon: Icons.keyboard_arrow_down,
            theme: theme,
            onPressed: count == 0 ? null : controller.nextMatch,
          ),
          _iconButton(
            key: Key('$keyPrefix-find-close'),
            tooltip: AppStrings.editorFindCloseTooltip,
            icon: Icons.close,
            theme: theme,
            onPressed: controller.close,
          ),
        ],
      ),
    );
  }

  Widget _replaceRow(ThemeData theme) => SizedBox(
    height: _rowHeight,
    child: Row(
      children: [
        const SizedBox(width: 48),
        Expanded(
          child: TextField(
            key: Key('$keyPrefix-replace-input'),
            controller: controller.replaceInput,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: AppStrings.editorReplaceHint,
              border: InputBorder.none,
              isDense: true,
            ),
            onSubmitted: (_) => controller.replaceMatch(),
          ),
        ),
        _iconButton(
          key: Key('$keyPrefix-replace-one'),
          tooltip: AppStrings.editorReplaceOneTooltip,
          icon: Icons.find_replace,
          theme: theme,
          onPressed: controller.matchCount == 0
              ? null
              : controller.replaceMatch,
        ),
        _iconButton(
          key: Key('$keyPrefix-replace-all'),
          tooltip: AppStrings.editorReplaceAllTooltip,
          icon: Icons.done_all,
          theme: theme,
          onPressed: controller.matchCount == 0
              ? null
              : controller.replaceAllMatches,
        ),
        const SizedBox(width: 4),
      ],
    ),
  );

  Widget _iconButton({
    required Key key,
    required String tooltip,
    required IconData icon,
    required ThemeData theme,
    VoidCallback? onPressed,
    bool active = false,
  }) => IconButton(
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
