/// A link in a task, drawn as a chip (#1152): the note's name, tapped to open
/// the note.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/todo/task_row_links.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_dashed_box.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_link_host.dart';

/// One link of a task's text, as the Todo tab draws it.
///
/// A link that names a note — or may, until the library has answered, or fits
/// several — is a chip in the wikilink colour; one that names none is dashed
/// and dimmed, with an outline link-off icon. The answer changes the colour
/// and the words, never the size, so nothing moves as a fresh edit resolves.
///
/// A tap follows the link through the [host] (the note opens, a shared name
/// asks which, a missing note is offered); a long press on a touch screen
/// previews the note. A pointer hovering a note's chip is told where it goes.
/// Without a host the chip is drawn and does nothing.
final class TodoLinkChip extends StatelessWidget {
  /// The chip for [link]; [compact] is a desktop row's, a little smaller than
  /// the phone's thumb-sized one.
  const new({
    required this.link,
    required this.host,
    this.compact = false,
    super.key,
  });

  /// The link and its words.
  final TaskRowLink link;

  /// Follows the link; null draws it as it is.
  final TodoLinkHost? host;

  /// Whether to draw the smaller chip a pointer's row has.
  final bool compact;

  /// The widest a chip grows before its words are cut: a long note name must
  /// not push the row's text away.
  static const double maxWidth = 220;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SyntaxColors.of(context);
    final dead = link.state == TaskRowLinkState.dead;
    final color = dead ? colors.deadLink : colors.wikilink;
    final height = compact ? 20.0 : 24.0;
    final iconSize = compact ? 12.0 : 13.0;
    final body = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The file on a pointer's row, the link on a thumb's: the same
        // outline either way, and link-off when there is no note.
        Icon(
          dead
              ? Icons.link_off
              : compact
              ? Icons.description_outlined
              : Icons.link,
          size: iconSize,
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            link.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
    final h = host;
    final path = link.notePath;
    final chip = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        height: height,
        child: Material(
          color: dead ? Colors.transparent : color.withValues(alpha: 0.16),
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('todo-link-chip-${link.label}'),
            onTap: h == null ? null : () => _follow(context, h),
            onLongPress: h == null || !_touch(theme)
                ? null
                : () => h.preview(context, link),
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: dead ? 6 : 5,
                end: dead ? 8 : 8,
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
    final outlined = dead
        ? KanbanDashedBox(color: color, radius: height / 2, child: chip)
        : chip;
    if (path == null) return outlined;
    // A hover names the file; a long press on a touch screen is the preview's,
    // not the tooltip's.
    return Tooltip(
      message: AppStrings.taskLinkOpenTooltip(path),
      triggerMode: TooltipTriggerMode.manual,
      child: outlined,
    );
  }

  /// Follows the link, telling where the chip is, for a question it asks.
  void _follow(BuildContext context, TodoLinkHost host) {
    final box = context.findRenderObject();
    final anchor = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    unawaited(
      host.follow(
        context,
        link,
        anchor: _touch(Theme.of(context)) ? null : anchor,
      ),
    );
  }

  static bool _touch(ThemeData theme) => switch (theme.platform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
}
