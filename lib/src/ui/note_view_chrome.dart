/// The note view's chrome (#51): the frontmatter warning banner, the
/// status row and the formatting toolbar bar. Purely presentational —
/// everything they read arrives as constructor params, and every tap
/// leaves through a callback — so the state file keeps the behaviour
/// while these keep the pixels.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/editor/toolbar.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/ui/strings.dart';

/// The frontmatter parse-error banner.
final class FrontmatterWarningBanner extends StatelessWidget {
  /// Creates the banner for [message].
  const new({required this.message, super.key});

  /// The parse error to report.
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('frontmatter-error'),
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 16,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.frontmatterInvalid(message),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The status row (T-UI-07): outline toggle + word count left, saved/
/// unsaved right.
final class NoteStatusRow extends StatelessWidget {
  /// Creates the row; every tap leaves through a callback.
  const new({
    required this.loading,
    required this.splitPreview,
    required this.showPreview,
    required this.showWysiwyg,
    required this.spellCheckAvailable,
    required this.canSwitchEditorKind,
    required this.wordCount,
    required this.statusText,
    required this.statusActions,
    required this.onOutline,
    required this.onFind,
    required this.onSpellCheck,
    required this.onToggleEditorKind,
    super.key,
  });

  /// Whether a note is still loading (hides the buttons).
  final bool loading;

  /// Whether editor and preview sit side by side.
  final bool splitPreview;

  /// Whether the preview is the visible pane.
  final bool showPreview;

  /// Whether the WYSIWYG surface is the visible editor.
  final bool showWysiwyg;

  /// Whether the spell checker can open.
  final bool spellCheckAvailable;

  /// Whether the editor-kind toggle shows.
  final bool canSwitchEditorKind;

  /// The word count left of the status.
  final int wordCount;

  /// The saved/unsaved text right of the count.
  final String statusText;

  /// Extra actions after the status text.
  final List<Widget> statusActions;

  /// Opens the outline sheet.
  final Future<void> Function() onOutline;

  /// Opens find (source bar or WYSIWYG panel, chosen by the owner).
  final VoidCallback onFind;

  /// Opens the spell checker.
  final Future<void> Function() onSpellCheck;

  /// Flips between the source editor and the WYSIWYG surface.
  final VoidCallback onToggleEditorKind;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    // Desktop breathing room (user, 2026-09-11): the phone keeps the row
    // tight; on desktop each icon stands off its neighbours and the word
    // count stands off the icons.
    final desktop = !(Platform.isAndroid || Platform.isIOS);
    final iconPadding = EdgeInsets.symmetric(horizontal: desktop ? 3 : 0);
    return Padding(
      key: const Key('status-row'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        children: [
          if (!loading)
            Padding(
              padding: iconPadding,
              child: IconButton(
                key: const Key('outline-toggle'),
                tooltip: AppStrings.outlineTooltip,
                icon: const Icon(Icons.toc),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 26),
                onPressed: () => unawaited(onOutline()),
              ),
            ),
          // Find & replace lives in the editor pane (hidden in
          // preview-only mode).
          if (!loading && (splitPreview || !showPreview))
            Padding(
              padding: iconPadding,
              child: IconButton(
                key: const Key('editor-find-open'),
                tooltip: AppStrings.findInNoteTooltip,
                icon: const Icon(Icons.search),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 26),
                onPressed: onFind,
              ),
            ),
          if (!loading && spellCheckAvailable)
            Padding(
              padding: iconPadding,
              child: IconButton(
                key: const Key('spell-check-open'),
                tooltip: AppStrings.spellCheckTooltip,
                icon: const Icon(Icons.spellcheck),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 26),
                onPressed: () => unawaited(onSpellCheck()),
              ),
            ),
          // The quick way between the two editors (T-WYS-12): the setting
          // stays per library, the button just flips it.
          if (!loading && canSwitchEditorKind)
            Padding(
              padding: iconPadding,
              child: IconButton(
                key: const Key('editor-kind-toggle'),
                tooltip: showWysiwyg
                    ? AppStrings.switchToSourceTooltip
                    : AppStrings.switchToWysiwygTooltip,
                icon: Icon(
                  showWysiwyg ? Icons.code : Icons.edit_note,
                  size: 18,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 26),
                onPressed: onToggleEditorKind,
              ),
            ),
          if (!loading)
            Padding(
              padding: EdgeInsets.only(left: desktop ? 6 : 0),
              child: Text(
                '$wordCount words',
                style: labelStyle?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const Spacer(),
          Text(statusText, style: labelStyle),
          for (final action in statusActions) ...[
            const SizedBox(width: 6),
            action,
          ],
        ],
      ),
    );
  }
}

/// The formatting toolbar's button bar: one button per visible layout
/// item, pressed while its format is on at the caret.
final class NoteToolbarBar extends StatelessWidget {
  /// Creates the bar over [layout], pressing through [actions].
  const new({
    required this.actions,
    required this.active,
    required this.layout,
    super.key,
  });

  /// What each toolbar button does.
  final Map<ToolbarItem, VoidCallback> actions;

  /// The formats on at the caret.
  final Set<ToolbarItem> active;

  /// Which buttons show, in order.
  final ToolbarLayout layout;

  @override
  Widget build(BuildContext context) => EditorToolbar(
    buttons: [
      for (final item in layout.visible)
        EditorToolbarButton(
          key: item.widgetKey,
          icon: item.icon,
          tooltip: item.label,
          active: active.contains(item),
          onPressed: actions[item]!,
        ),
    ],
  );
}
