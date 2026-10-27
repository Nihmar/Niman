/// The custom repeat on a phone: a bottom sheet (#1189, #1191).
///
/// A desktop with the room edits it in place, under the Repeat row, like the
/// due date's calendar; a touch screen gets this sheet instead, with the
/// soft keyboard's room made for the interval.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';
import 'package:niman/src/ui/repeat_custom.dart';
import 'package:niman/src/ui/repeat_row.dart' show RepeatRow;
import 'package:niman/src/ui/strings.dart';

/// Opens the custom repeat editor on [initial] (every day when null) and
/// resolves to the rule when OK is tapped, or null on dismissal. [anchor]
/// is the task's due date, or today, or the event's day. [keyPrefix] and
/// [countsFrom] are the row's ([RepeatRow]).
Future<RecurrenceRule?> showRepeatSheet(
  BuildContext context, {
  required RecurrenceRule? initial,
  required DateTime anchor,
  String keyPrefix = 'todo',
  bool countsFrom = true,
}) {
  return showModalBottomSheet<RecurrenceRule>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _RepeatSheet(
      initial: initial,
      anchor: anchor,
      keyPrefix: keyPrefix,
      countsFrom: countsFrom,
    ),
  );
}

final class _RepeatSheet extends StatefulWidget {
  const new({
    required this.initial,
    required this.anchor,
    required this.keyPrefix,
    required this.countsFrom,
  });

  final RecurrenceRule? initial;
  final DateTime anchor;
  final String keyPrefix;
  final bool countsFrom;

  @override
  State<_RepeatSheet> createState() => _RepeatSheetState();
}

final class _RepeatSheetState extends State<_RepeatSheet> {
  late RecurrenceRule _rule =
      widget.initial ?? RecurrenceRule(unit: RecurrenceUnit.day);

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Above the keyboard the interval is typed on.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        key: Key('${widget.keyPrefix}-repeat-sheet'),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  AppStrings.todoRepeat,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              RepeatCustom(
                initial: widget.initial,
                anchor: widget.anchor,
                keyPrefix: widget.keyPrefix,
                countsFrom: widget.countsFrom,
                onChanged: (rule) => _rule = rule,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: Key('${widget.keyPrefix}-repeat-sheet-ok'),
                    onPressed: () => Navigator.pop(context, _rule),
                    child: Text(AppStrings.actionOk),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
