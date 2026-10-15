/// The frontmatter panel's editing in place, where a pointer aims (#712):
/// a value turns into a field where it is, a date opens a calendar under
/// itself, a list takes one more item from a field of its own, and a new
/// key is typed in a row — no dialog, and no dialog on a dialog. A phone
/// keeps the panel's dialog.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/ui/action_sheet.dart';

/// A scalar's value, read as text until it is clicked, then a field:
/// `Enter` or a click elsewhere keeps what was typed, `Esc` leaves it.
/// A [date] opens a calendar under itself instead.
final class FrontmatterInlineValue extends StatefulWidget {
  /// The value [value], kept through [onCommit].
  const new({
    required this.value,
    required this.onCommit,
    this.date = false,
    this.startEditing = false,
    super.key,
  });

  /// The value as the panel reads it.
  final String value;

  /// Keeps a new value, as typed; not called when nothing changed.
  final ValueChanged<String> onCommit;

  /// Whether the value is a date, picked in a calendar.
  final bool date;

  /// Whether the field opens at once: a key just added waits for its value.
  final bool startEditing;

  @override
  State<FrontmatterInlineValue> createState() => _FrontmatterInlineValueState();
}

final class _FrontmatterInlineValueState extends State<FrontmatterInlineValue> {
  late bool _editing = widget.startEditing && !widget.date;

  @override
  void didUpdateWidget(FrontmatterInlineValue old) {
    super.didUpdateWidget(old);
    // A row that is already there is asked to open too: a key typed into
    // the add row that the block has.
    if (widget.startEditing && !old.startEditing && !widget.date) {
      _editing = true;
    }
  }

  Future<void> _pickDate() async {
    final anchor = menuAnchorOf(context);
    if (anchor == null) return;
    final picked = await showCalendarPopover(
      context,
      anchor: anchor,
      initial: DateTime.tryParse(widget.value.trim()),
    );
    if (picked == null) return;
    final iso = picked.toIso8601String().substring(0, 10);
    if (iso != widget.value) widget.onCommit(iso);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    if (_editing) {
      return InlineField(
        initial: widget.value,
        style: style,
        onDone: (text) {
          setState(() => _editing = false);
          if (text != null && text != widget.value) widget.onCommit(text);
        },
      );
    }
    return InkWell(
      onTap: widget.date
          ? () => unawaited(_pickDate())
          : () => setState(() => _editing = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          widget.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}

/// A one-line field that answers once: what was typed, on `Enter` or when
/// it loses the focus, or null on `Esc`.
final class InlineField extends StatefulWidget {
  /// Opens on [initial], all of it selected.
  const new({
    required this.initial,
    required this.onDone,
    this.hint,
    this.style,
    super.key,
  });

  /// The text it opens on.
  final String initial;

  /// What was typed, trimmed, or null when given up.
  final ValueChanged<String?> onDone;

  /// What an empty field says.
  final String? hint;

  /// The text's style, the row's own.
  final TextStyle? style;

  @override
  State<InlineField> createState() => _InlineFieldState();
}

final class _InlineFieldState extends State<InlineField> {
  late final TextEditingController _text =
      TextEditingController(text: widget.initial)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initial.length,
        );
  final FocusNode _focus = FocusNode();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _finish(_text.text.trim());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _finish(String? text) {
    if (_done) return;
    _done = true;
    widget.onDone(text);
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () => _finish(null),
    },
    child: TextField(
      key: const Key('frontmatter-inline-field'),
      controller: _text,
      focusNode: _focus,
      style: widget.style,
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onSubmitted: (text) => _finish(text.trim()),
    ),
  );
}

/// A calendar under [anchor] (a place on screen), on [initial] or today;
/// the day picked, or null when clicked away.
Future<DateTime?> showCalendarPopover(
  BuildContext context, {
  required Rect anchor,
  DateTime? initial,
}) {
  final day = initial ?? DateTime.now();
  return showGeneralDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 100),
    pageBuilder: (context, _, _) {
      final overlay =
          Navigator.of(context).overlay!.context.findRenderObject()!
              as RenderBox;
      final at = Rect.fromPoints(
        overlay.globalToLocal(anchor.topLeft),
        overlay.globalToLocal(anchor.bottomRight),
      );
      return CustomSingleChildLayout(
        delegate: _BelowAnchor(at),
        child: Material(
          key: const Key('calendar-popover'),
          elevation: 8,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 320,
            height: 340,
            // The picker reports a year chosen in its year grid through the
            // same callback as a day, and the year is not the date: the
            // day is still to pick. The grid replaces the days while it
            // shows, so one under this subtree is the year being chosen.
            child: Builder(
              builder: (here) => CalendarDatePicker(
                initialDate: day,
                firstDate: DateTime(day.year - 100),
                lastDate: DateTime(day.year + 100),
                onDateChanged: (picked) {
                  if (!_showsYearGrid(here)) Navigator.pop(context, picked);
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Whether the year grid of a [CalendarDatePicker] is showing under
/// [context].
bool _showsYearGrid(BuildContext context) {
  var found = false;
  void visit(Element element) {
    if (found) return;
    if (element.widget is YearPicker) {
      found = true;
      return;
    }
    element.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
  return found;
}

/// Under [anchor] where there is room, above it where there is not, and
/// inside the window either way.
final class _BelowAnchor extends SingleChildLayoutDelegate {
  const new(this.anchor);

  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    const margin = 8.0;
    final x = anchor.left.clamp(
      margin,
      (size.width - child.width - margin).clamp(margin, double.infinity),
    );
    final below = anchor.bottom + 4;
    final y = below + child.height <= size.height - margin
        ? below
        : (anchor.top - child.height - 4).clamp(margin, double.infinity);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_BelowAnchor old) => old.anchor != anchor;
}
