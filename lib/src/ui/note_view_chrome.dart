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
import 'package:re_editor/re_editor.dart';

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

/// The status row (T-UI-07): the controls on the left, what the note
/// reads as — its word count and whether it is saved — on the right.
///
/// The phone's row used to keep a tight hand (34×26 touch targets,
/// below the 48 dp guideline, left alone on purpose: a tight phone
/// row was asked for on 2026-09-11, and the space to loosen it
/// honestly only existed while the tab bar sat under the note).
/// The tab bar is gone from the note page (issue #73, item 1), so
/// the freed height funds the guideline-sized targets.
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

  /// The note's word count, left of the status.
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
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall;
    // Desktop breathing room (user, 2026-09-11): the phone keeps the row
    // tight; on desktop each icon stands off its neighbours.
    final desktop = !(Platform.isAndroid || Platform.isIOS);
    final iconPadding = EdgeInsets.symmetric(horizontal: desktop ? 3 : 0);
    return Padding(
      key: const Key('status-row'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      // The row stands as tall as the editor switch whenever there is a
      // switch to show, so going to the preview and back does not change
      // its height (user, 2026-09-18). The switch is 48 and the icon
      // buttons beside it are 40 — `VisualDensity.compact` takes 8 off
      // their 48 constraint — so the row used to shrink with it.
      //
      // A floor rather than a fixed height, and only where the button
      // can appear at all: a library with one editor enabled never sees
      // it, and has no reason to pay 8 dp of note for it.
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: canSwitchEditorKind ? 48 : 0),
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
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => unawaited(onOutline()),
                ),
              ),
            // Find & replace lives in the editor pane, so preview-only mode
            // has nothing to search — but the button keeps its slot and
            // goes grey rather than dropping out of the row. This row is
            // laid out from the left, so a button that comes and goes
            // drags every icon after it sideways, and the eye is tapped
            // often enough that the icons would move under a thumb already
            // on them (the app bar had the same fault, #122).
            if (!loading)
              Padding(
                padding: iconPadding,
                // In the editor's tap region like the formatting toolbar:
                // re_editor unfocuses the editor on any tap outside it, so
                // an unwrapped find button closes the keyboard on tap-down
                // and the find field reopens it a frame later. Wrapped,
                // focus moves straight to the find field and the keyboard
                // never leaves.
                child: CodeEditorTapRegion(
                  child: IconButton(
                    key: const Key('editor-find-open'),
                    tooltip: AppStrings.findInNoteTooltip,
                    icon: const Icon(Icons.search),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: splitPreview || !showPreview ? onFind : null,
                  ),
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
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => unawaited(onSpellCheck()),
                ),
              ),
            // The quick way between the two editors (T-WYS-12): the setting
            // stays per library, the button just flips it. Icon and word
            // together — the tooltip that named the surface only appears
            // after a long press on Android, and a bare noun does not say
            // whether it is where you are or where you would land, which
            // the icon answers.
            //
            // Written in the muted colour the rest of the row wears: a
            // button in the accent was the only coloured thing here and
            // read as a link.
            //
            // Preview-only mode has no editor on screen, so there are not
            // two of them to be between: the button goes (device report,
            // 2026-09-18). It is dropped rather than disabled — the
            // keep-its-place rule is about controls sliding under a thumb
            // that is already on them, and this one is the last thing
            // before the Spacer, so nothing to its left moves and what is
            // to its right is anchored to the other edge.
            if (!loading &&
                canSwitchEditorKind &&
                (splitPreview || !showPreview))
              Padding(
                padding: iconPadding,
                child: Tooltip(
                  message: showWysiwyg
                      ? AppStrings.switchToSourceTooltip
                      : AppStrings.switchToWysiwygTooltip,
                  child: TextButton.icon(
                    key: const Key('editor-kind-toggle'),
                    onPressed: onToggleEditorKind,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: labelStyle,
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    icon: Icon(
                      showWysiwyg ? Icons.code : Icons.edit_note,
                      size: 18,
                    ),
                    label: Text(
                      showWysiwyg
                          ? AppStrings.switchToSourceLabel
                          : AppStrings.switchToWysiwygLabel,
                    ),
                  ),
                ),
              ),
            const Spacer(),
            // Both readings of the note sit together on the right, after
            // the controls: the switch is the only control whose width
            // changes with its label, and nothing follows it now, so
            // flipping the editor no longer slides the count sideways.
            if (!loading) ...[
              Text(
                AppStrings.wordCount(wordCount),
                style: labelStyle?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(statusText, style: labelStyle),
            for (final action in statusActions) ...[
              const SizedBox(width: 6),
              action,
            ],
          ],
        ),
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
