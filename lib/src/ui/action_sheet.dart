import 'package:flutter/material.dart';

/// The app's one pop-up menu: a modal sheet from the bottom edge holding
/// full-width rows.
///
/// The tree's long-press menu was the first of these and is the shape the
/// rest follow (user, 2026-09-09): a choice made on a phone belongs under
/// the thumb, not centred in a dialog the hand has to reach across. Every
/// list of choices in the app opens this way, so a person learns the
/// gesture once.
///
/// Scroll-controlled, so the sheet takes the height its rows need instead
/// of the default cap — which silently clipped whatever did not fit — and
/// bounded at [maxHeightFraction] of the screen so the note behind it
/// stays visible and a long list scrolls inside the sheet.
Future<T?> showActionSheet<T>(
  BuildContext context, {
  required List<Widget> Function(BuildContext context) items,
  String? title,
  Key? sheetKey,
  double maxHeightFraction = 0.7,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      key: sheetKey,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxHeightFraction,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ActionSheetTitle(title),
              ...items(context),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The heading of an action sheet: what the rows below it are for.
///
/// The tree menu has none — its rows say what they do, and the row it was
/// opened from is the subject. A sheet whose rows are values rather than
/// verbs needs one.
final class ActionSheetTitle extends StatelessWidget {
  /// Creates a sheet heading reading [text].
  const new(this.text, {super.key});

  /// The heading text.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
