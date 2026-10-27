/// The custom repeat editor (#1189, #1191): every N days, weeks, months or
/// years, on which weekdays, on the Nth weekday of the month, and — for a
/// task — counted from the due date or from the completion.
///
/// Every change is answered at once through [RepeatCustom.onChanged]: the
/// task dialog writes it into the line as it goes (in place on a desktop),
/// the event form keeps it, and the phone's sheet keeps the last one for its
/// button.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';
import 'package:niman/src/core/recurrence/recurrence_weekday.dart';
import 'package:niman/src/core/week_start.dart';
import 'package:niman/src/ui/recurrence_words.dart';
import 'package:niman/src/ui/strings.dart';

/// The units the editor offers (business days are the menu's Weekdays).
const List<RecurrenceUnit> _units = <RecurrenceUnit>[
  RecurrenceUnit.day,
  RecurrenceUnit.week,
  RecurrenceUnit.month,
  RecurrenceUnit.year,
];

/// The editor: interval and unit, the weekdays of a weekly rule, the Nth
/// weekday of a monthly one, and what the next copy counts from.
final class RepeatCustom extends StatefulWidget {
  /// An editor opened on [initial] (every day when null); [anchor] is the
  /// task's due date, or today, or the event's day, which a monthly rule's
  /// Nth weekday is taken from. [keyPrefix] names its keys, and [countsFrom]
  /// offers the choice of counting from the due date or the completion: a
  /// task's, not an event's.
  const new({
    required this.initial,
    required this.anchor,
    required this.onChanged,
    this.keyPrefix = 'todo',
    this.countsFrom = true,
    super.key,
  });

  /// The rule it opens on.
  final RecurrenceRule? initial;

  /// The day the weekday options are offered from.
  final DateTime anchor;

  /// Called with the rule after every change.
  final ValueChanged<RecurrenceRule> onChanged;

  /// The prefix of the editor's keys.
  final String keyPrefix;

  /// Whether the editor offers the due date and the completion to count from.
  final bool countsFrom;

  @override
  State<RepeatCustom> createState() => _RepeatCustomState();
}

final class _RepeatCustomState extends State<RepeatCustom> {
  late RecurrenceUnit _unit = _startUnit;
  late int _interval = widget.initial?.interval ?? 1;
  late Set<int> _weekdays = <int>{...?widget.initial?.weekdays};
  late NthWeekday? _nth = widget.initial?.nthWeekday;
  late bool _strict = widget.initial?.strict ?? false;
  late final TextEditingController _count = TextEditingController(
    text: '$_interval',
  );

  RecurrenceUnit get _startUnit {
    final unit = widget.initial?.unit ?? RecurrenceUnit.day;
    return unit == RecurrenceUnit.businessDay ? RecurrenceUnit.day : unit;
  }

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  RecurrenceRule get _rule => RecurrenceRule(
    unit: _unit,
    interval: _interval,
    strict: _strict,
    weekdays: _unit == RecurrenceUnit.week
        ? (<int>[..._weekdays]..sort())
        : const <int>[],
    nthWeekday: _unit == RecurrenceUnit.month ? _nth : null,
  );

  void _changed(VoidCallback change) {
    setState(change);
    widget.onChanged(_rule);
  }

  void _typed(String text) {
    final value = int.tryParse(text);
    if (value == null || value < 1 || value > RecurrenceRule.maxInterval) {
      return;
    }
    _changed(() => _interval = value);
  }

  String _unitLabel(RecurrenceUnit unit) => switch (unit) {
    RecurrenceUnit.day => AppStrings.recurUnitDays,
    RecurrenceUnit.week => AppStrings.recurUnitWeeks,
    RecurrenceUnit.month => AppStrings.recurUnitMonths,
    RecurrenceUnit.year => AppStrings.recurUnitYears,
    RecurrenceUnit.businessDay => AppStrings.recurUnitDays,
  };

  /// The weekdays in the order the week starts on: Material counts Sunday
  /// as 0, `DateTime.weekday` counts it as 7.
  List<int> get _weekOrder {
    final first = AppWeekStart.firstDayIndex == 0
        ? 7
        : AppWeekStart.firstDayIndex;
    return <int>[for (var i = 0; i < 7; i++) (first - 1 + i) % 7 + 1];
  }

  /// The Nth weekdays a monthly rule can be on: none (the same date), the
  /// anchor's own (unless it is a fifth), the last of its kind, and the
  /// rule's own when it is neither.
  List<NthWeekday?> get _nthOptions {
    final day = widget.anchor;
    final own = (day.day - 1) ~/ 7 + 1;
    final options = <NthWeekday?>[
      null,
      if (own <= 4) NthWeekday(own, day.weekday),
      NthWeekday(-1, day.weekday),
    ];
    final current = _nth;
    if (current != null && !options.contains(current)) options.add(current);
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final names = AppStrings.weekdayNamesShort;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(AppStrings.recurEvery),
              const SizedBox(width: 12),
              SizedBox(
                width: 72,
                child: TextField(
                  key: Key('${widget.keyPrefix}-repeat-interval'),
                  controller: _count,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(isDense: true),
                  onChanged: _typed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final unit in _units)
                ChoiceChip(
                  key: Key('${widget.keyPrefix}-repeat-unit-${unit.name}'),
                  label: Text(_unitLabel(unit)),
                  selected: _unit == unit,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => _changed(() => _unit = unit),
                ),
            ],
          ),
          if (_unit == RecurrenceUnit.week) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final weekday in _weekOrder)
                  FilterChip(
                    key: Key('${widget.keyPrefix}-repeat-weekday-$weekday'),
                    label: Text(names[weekday - 1]),
                    selected: _weekdays.contains(weekday),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    onSelected: (on) => _changed(() {
                      _weekdays = on
                          ? {..._weekdays, weekday}
                          : ({..._weekdays}..remove(weekday));
                    }),
                  ),
              ],
            ),
          ],
          if (_unit == RecurrenceUnit.month) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final nth in _nthOptions)
                  ChoiceChip(
                    key: Key(
                      '${widget.keyPrefix}-repeat-month-'
                      '${nth?.token ?? 'date'}',
                    ),
                    label: Text(_monthLabel(nth)),
                    selected: _nth == nth,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => _changed(() => _nth = nth),
                  ),
              ],
            ),
          ],
          if (widget.countsFrom) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  key: Key('${widget.keyPrefix}-repeat-from-due'),
                  label: Text(AppStrings.recurFromDueDate),
                  selected: _strict,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => _changed(() => _strict = true),
                ),
                ChoiceChip(
                  key: Key('${widget.keyPrefix}-repeat-from-completion'),
                  label: Text(AppStrings.recurFromCompletion),
                  selected: !_strict,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => _changed(() => _strict = false),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            key: Key('${widget.keyPrefix}-repeat-summary'),
            sentenceCase(
              recurrenceWords(_rule.description, fromDue: widget.countsFrom),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// A monthly option in words: "Every month on the 2nd Tuesday".
  String _monthLabel(NthWeekday? nth) => sentenceCase(
    recurrenceWords(
      RecurrenceRule(
        unit: RecurrenceUnit.month,
        interval: _interval,
        nthWeekday: nth,
      ).description,
    ),
  );
}
