import 'package:flutter/material.dart';
import 'package:niman/src/todo/todo_list_item.dart';
import 'package:niman/src/todo/todo_sections.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/todo_section_label.dart';

/// The header of a todo section (#1003): a chevron, the heading and, at the
/// end, how many tasks the section holds. The whole row is the target that
/// folds or opens the section.
///
/// On a thumb the row is 48 dp tall; where a pointer aims it is as tight as
/// a list row. The Overdue heading wears the error colour. [selected] is
/// the desktop list's keyboard row, drawn with the bar at the start the
/// task rows use.
final class TodoSectionHeader extends StatelessWidget {
  /// Creates the header of [item]; [onToggle] folds or opens its section.
  const new({
    required this.item,
    required this.onToggle,
    this.selected = false,
    super.key,
  });

  /// The section this header heads.
  final TodoHeaderItem item;

  /// Folds the section, or opens it when it is folded.
  final VoidCallback onToggle;

  /// Whether the keyboard's selection is on this header.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final overdue = item.section == todoDueOverdueSectionId;
    final label = todoSectionLabel(item.section);
    return Semantics(
      container: true,
      button: true,
      expanded: !item.collapsed,
      label: '$label, ${item.count}',
      excludeSemantics: true,
      onTap: onToggle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? scheme.secondaryContainer.withValues(alpha: 0.4)
              : null,
          border: BorderDirectional(
            start: BorderSide(
              width: 2,
              color: selected ? scheme.primary : Colors.transparent,
            ),
          ),
        ),
        child: InkWell(
          onTap: onToggle,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: pointerDense(theme) ? 32 : thumbTarget,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 16, 0),
              child: Row(
                children: [
                  Icon(
                    item.collapsed ? Icons.chevron_right : Icons.expand_more,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: overdue ? scheme.error : scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.count}',
                    key: const Key('todo-section-count'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: overdue ? scheme.error : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
