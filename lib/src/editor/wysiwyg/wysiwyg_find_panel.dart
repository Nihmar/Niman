import 'package:flutter/material.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_find_controller.dart';
import 'package:niman/src/ui/strings.dart';

/// The WYSIWYG find & replace bar (T-WYS-08).
///
/// The same face as the source editor's panel, over [WysiwygFindController]
/// instead of re_editor's find machinery: the query row, the replace row,
/// the match counter and the navigation buttons.
final class WysiwygFindPanel extends StatelessWidget
    implements PreferredSizeWidget {
  /// Creates the panel over [controller].
  const new({required this.controller, super.key});

  /// The find state and actions.
  final WysiwygFindController controller;

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
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _findRow(theme),
          if (controller.replaceMode) _replaceRow(theme),
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
            key: const Key('wysiwyg-find-mode'),
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
              key: const Key('wysiwyg-find-input'),
              controller: controller.findInput,
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
            key: const Key('wysiwyg-find-case'),
            tooltip: AppStrings.editorFindCaseTooltip,
            icon: Icons.text_fields,
            active: controller.caseSensitive,
            theme: theme,
            onPressed: controller.toggleCaseSensitive,
          ),
          _iconButton(
            key: const Key('wysiwyg-find-prev'),
            tooltip: AppStrings.editorFindPreviousTooltip,
            icon: Icons.keyboard_arrow_up,
            theme: theme,
            onPressed: count == 0 ? null : controller.previousMatch,
          ),
          _iconButton(
            key: const Key('wysiwyg-find-next'),
            tooltip: AppStrings.editorFindNextTooltip,
            icon: Icons.keyboard_arrow_down,
            theme: theme,
            onPressed: count == 0 ? null : controller.nextMatch,
          ),
          _iconButton(
            key: const Key('wysiwyg-find-close'),
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
            key: const Key('wysiwyg-replace-input'),
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
          key: const Key('wysiwyg-replace-one'),
          tooltip: AppStrings.editorReplaceOneTooltip,
          icon: Icons.find_replace,
          theme: theme,
          onPressed: controller.matchCount == 0
              ? null
              : controller.replaceMatch,
        ),
        _iconButton(
          key: const Key('wysiwyg-replace-all'),
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
