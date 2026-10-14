import 'package:flutter/material.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/pointer_menu.dart';

/// The app's one list of choices.
///
/// A phone gets the sheet its thumb reaches: a modal bottom sheet holding
/// full-width rows, the shape the tree's long-press menu set (user,
/// 2026-09-09): a choice made on a phone belongs under the thumb, not
/// centred in a dialog the hand has to reach across. Every list of
/// choices in the app opens this way, so a person learns the gesture
/// once.
///
/// A pointer gets a pop-up menu at [anchor] — the button that opened it,
/// from [menuAnchorOf] — because a desktop never answers a click near the
/// top of the window with a sheet from the bottom edge (#712). The rows
/// are the same widgets in both shapes: each closes the list itself with
/// `Navigator.pop(context, value)`.
///
/// Scroll-controlled on the phone, so the sheet takes the height its rows
/// need instead of the default cap — which silently clipped whatever did
/// not fit — and bounded at [maxHeightFraction] of the screen so the note
/// behind it stays visible and a long list scrolls inside the sheet.
///
/// [menuMaxWidth] caps the pop-up's width: a panel of its own — the sync
/// status, the todo filter — takes more room than a list of verbs.
Future<T?> showActionSheet<T>(
  BuildContext context, {
  required List<Widget> Function(BuildContext context) items,
  String? title,
  Key? sheetKey,
  double maxHeightFraction = 0.7,
  Rect? anchor,
  double menuMaxWidth = 400,
}) {
  if (pointerDense(Theme.of(context))) {
    return _showActionSheetMenu<T>(
      context,
      items: items,
      title: title,
      menuKey: sheetKey,
      anchor: anchor,
      maxWidth: menuMaxWidth,
    );
  }
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

/// [context]'s widget as a rectangle on screen, for [showActionSheet]'s
/// `anchor`: the button a menu should grow from, where there is one.
///
/// In global coordinates, as a tap's `globalPosition` is: the menu turns
/// it into its own overlay's space, which inside a floating window is not
/// the screen's (#780).
Rect? menuAnchorOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.attached) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// A point on screen — where a tap landed — as an `anchor`.
Rect menuAnchorAt(Offset globalPosition) => globalPosition & Size.zero;

/// The pointer's shape of [showActionSheet]: the same rows in a pop-up
/// menu at [anchor], or a third of the way down the window when nothing
/// anchors it — a key or the palette opened it, and there is no control
/// to grow from.
Future<T?> _showActionSheetMenu<T>(
  BuildContext context, {
  required List<Widget> Function(BuildContext context) items,
  required String? title,
  required Key? menuKey,
  required Rect? anchor,
  required double maxWidth,
}) {
  // The overlay the menu's route is drawn in: the navigator's, which
  // `showMenu` pushes on.
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  final at = anchor == null
      ? Rect.fromCenter(
          center: Offset(overlay.size.width / 2, overlay.size.height / 3),
          width: 1,
          height: 1,
        )
      : Rect.fromPoints(
          overlay.globalToLocal(anchor.topLeft),
          overlay.globalToLocal(anchor.bottomRight),
        );
  return showMenu<T>(
    context: context,
    position: RelativeRect.fromRect(at, Offset.zero & overlay.size),
    constraints: BoxConstraints(minWidth: 240, maxWidth: maxWidth),
    items: [_ActionSheetMenuEntry<T>(key: menuKey, items: items, title: title)],
  );
}

/// The rows of [showActionSheet]'s menu, in the menu's own route: their
/// own taps close it with their value, exactly as the sheet's do.
final class _ActionSheetMenuEntry<T> extends PopupMenuEntry<T> {
  const new({required this.items, required this.title, super.key});

  final List<Widget> Function(BuildContext context) items;
  final String? title;

  /// The menu's own layout measures the rows; the fixed height only seeds
  /// the opening animation.
  @override
  double get height => 0;

  @override
  bool represents(T? value) => false;

  @override
  State<_ActionSheetMenuEntry<T>> createState() =>
      _ActionSheetMenuEntryState<T>();
}

final class _ActionSheetMenuEntryState<T>
    extends State<_ActionSheetMenuEntry<T>> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title case final title?) ActionSheetTitle(title),
        ...widget.items(context),
      ],
    );
    // The rows are whatever the sheet holds, tiles mostly: they take the
    // menu's compact tile, icon and label (`pointer_menu.dart`), as the
    // popup menus' own rows do.
    return ListTileTheme(
      data: theme.menuListTileTheme ?? theme.listTileTheme,
      child: IconTheme.merge(
        data: IconThemeData(size: theme.menuIconSize),
        child: rows,
      ),
    );
  }
}

/// The heading of an action sheet: what the rows below it are for.
///
/// For a sheet whose rows are values rather than verbs. A sheet of verbs
/// says instead what it acts on, which is a different thing and a
/// heavier one — see `RowMenuHeader`, which the tree menu opens with:
/// the sheet covers the tree, so the row that was pressed has to be
/// named or the verbs have no subject.
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
