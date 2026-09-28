/// The template checker's hint (T-TPL-09): what is wrong with the span the
/// caret is on, and the one fix the checker offered for it.
///
/// Drawn where the design draws it (`docs/design/template-checker`): the
/// message, then the fix as a single action, or a plain line saying no fix
/// is offered where the checker gave none. The labels come from
/// `ui/strings.dart`, so the chrome of the hint is translated; the corrected
/// text is drawn in the template colour the source colours its commands in.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/ui/strings.dart';

/// The hint card, positioned at [anchor] in the overlay's coordinates.
///
/// Nothing here rewrites the note: [onFix] is a tap the writer makes, and
/// the checker itself never edits — the fix is the writer's choice, never
/// automatic, as the issue asks. [onDismiss] takes the hint away and
/// changes nothing.
final class TemplateHint extends StatelessWidget {
  /// Creates the hint for [message], with [suggestion] as the fix or null.
  const new({
    required this.anchor,
    required this.message,
    required this.suggestion,
    required this.onFix,
    required this.onDismiss,
    super.key,
  });

  /// Where the wavy mark is, in the overlay's coordinates.
  final Rect anchor;

  /// What is wrong, from the checker.
  final String message;

  /// The corrected text for the span, or null when no fix is safe.
  final String? suggestion;

  /// Applies the fix — a tap, never automatic.
  final VoidCallback onFix;

  /// Takes the hint away without changing anything.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final fix = suggestion;
    return Positioned(
      left: anchor.left,
      top: anchor.bottom + 7,
      child: Material(
        key: const Key('template-hint'),
        color: colors.surfaceContainerHigh,
        elevation: 8,
        borderRadius: BorderRadius.circular(9),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, style: theme.textTheme.bodySmall),
                const SizedBox(height: 5),
                if (fix == null)
                  Text(AppStrings.templateHintNoFix, style: muted)
                else
                  _fixLine(context, muted, fix),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (fix != null)
                      FilledButton(
                        key: const Key('template-hint-fix'),
                        onPressed: onFix,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(0, 32),
                        ),
                        child: Text(AppStrings.templateHintFixAction),
                      ),
                    if (fix != null) const SizedBox(width: 6),
                    TextButton(
                      key: const Key('template-hint-dismiss'),
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                      ),
                      child: Text(AppStrings.templateHintDismissAction),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The fix line: the sentence [AppStrings.templateHintDidYouMean] answers
  /// for [fix], with the corrected text itself in the template colour.
  ///
  /// The whole sentence is one label — it owns the word order and the
  /// punctuation, which are not the same in every language — and the fix is
  /// picked out of it by its own text, which is the only part of it that is
  /// not in the label.
  Widget _fixLine(BuildContext context, TextStyle? muted, String fix) {
    final sentence = AppStrings.templateHintDidYouMean(fix);
    final at = sentence.indexOf(fix);
    if (at < 0) return Text(sentence, style: muted);
    return Text.rich(
      TextSpan(
        style: muted,
        children: [
          TextSpan(text: sentence.substring(0, at)),
          TextSpan(
            text: fix,
            style: TextStyle(
              fontFamily: 'monospace',
              color: SyntaxColors.of(context).template,
            ),
          ),
          TextSpan(text: sentence.substring(at + fix.length)),
        ],
      ),
    );
  }
}
