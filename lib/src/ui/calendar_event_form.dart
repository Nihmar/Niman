/// The Add event form (#730): a day's own event, written from here.
///
/// A start time and an optional end, the text with the tokens both files
/// already use a tap away, a reminder by lead time, and the line exactly
/// as it will be written — the writer's own answer, so the preview can
/// never promise something the file would not hold. It is inline in the
/// dock's journal pane on a window and a sheet on a phone: a dialog does
/// not go over a calendar (#712).
///
/// A Repeat row and an Ends row (#1191) make the event a rule: `rec:` and,
/// when it ends, `until:`. The days the rule skips (`except:`) are not on
/// the form, and travel through it untouched.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/calendar_occurrence_edits.dart';
import 'package:niman/src/calendar/calendar_recurrence.dart';
import 'package:niman/src/calendar/calendar_writer.dart';
import 'package:niman/src/core/recurrence/recurrence_bounds.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';
import 'package:niman/src/ui/app_switch.dart';
import 'package:niman/src/ui/calendar_event_preview.dart';
import 'package:niman/src/ui/calendar_event_repeat.dart';
import 'package:niman/src/ui/calendar_event_times.dart';
import 'package:niman/src/ui/journal/journal_flow.dart' show journalDayLabel;
import 'package:niman/src/ui/menu_choice_button.dart';
import 'package:niman/src/ui/strings.dart';

/// The lead times the reminder offers, in minutes before the event.
const List<int> calendarReminderLeads = [5, 10, 15, 30, 60];

/// The form: fill it and Add writes the event ([draft] given, it edits
/// one instead).
final class CalendarEventForm extends StatefulWidget {
  /// Creates the form for [day].
  ///
  /// [knownTokens] are the `+`/`@`/`#` tokens the two files already use;
  /// [preview] answers the line the writer would write for a draft;
  /// [draft] prefills an edit; [scope] says which occurrences of a repeating
  /// event it edits — for this one only, the event becomes a plain one and
  /// its Repeat and Ends rows are off.
  const new({
    required this.day,
    required this.knownTokens,
    required this.preview,
    required this.onCancel,
    required this.onSave,
    this.draft,
    this.scope,
    super.key,
  });

  /// The day the event is written onto: for an occurrence, its own day.
  final DateTime day;

  /// The tokens both files already use, sigil included.
  final Set<String> knownTokens;

  /// The day's line as [draft] would leave it.
  final String Function(CalendarEventDraft draft) preview;

  /// Leaves without writing.
  final VoidCallback onCancel;

  /// Writes the event.
  final void Function(CalendarEventDraft draft) onSave;

  /// The event being edited, or null when one is added.
  final CalendarEventDraft? draft;

  /// The occurrences an edit covers, or null for an event added or one that
  /// does not repeat.
  final CalendarOccurrenceScope? scope;

  @override
  State<CalendarEventForm> createState() => _CalendarEventFormState();
}

final class _CalendarEventFormState extends State<CalendarEventForm> {
  /// How many suggested tokens the form offers.
  static const int _suggestions = 6;

  late final TextEditingController _text = TextEditingController(
    text: widget.draft?.text ?? '',
  );
  final FocusNode _textFocus = FocusNode();

  /// An added event starts at the next whole hour; an edited one keeps
  /// its own time, an untimed event its none.
  late int? _start = widget.draft == null
      ? _nextHour(DateTime.now())
      : widget.draft!.startMinutes;
  late int? _end = widget.draft?.endMinutes;
  late bool _remind = widget.draft?.reminderMinutes != null;
  late int _lead = _leadOf(widget.draft);

  /// The rule and its end; what the rule skips is kept as it came.
  late RecurrenceRule? _rule = _only ? null : widget.draft?.recurrence?.rule;
  late DateTime? _until = _only ? null : widget.draft?.recurrence?.bounds.until;
  late final Set<DateTime> _except = {
    ...?widget.draft?.recurrence?.bounds.except,
  };
  bool _customOpen = false;

  /// Whether this edits one occurrence only, which then stands alone.
  bool get _only => widget.scope == CalendarOccurrenceScope.thisOne;

  @override
  void dispose() {
    _text.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  /// The next whole hour: what an added event starts at until it is
  /// changed.
  static int _nextHour(DateTime now) => ((now.hour + 1) % 24) * 60;

  /// The lead time an edited event's reminder was set with — its own, even
  /// when it is not one of the offered ones — or the default.
  static int _leadOf(CalendarEventDraft? draft) {
    final start = draft?.startMinutes;
    final reminder = draft?.reminderMinutes;
    if (start == null || reminder == null) return 15;
    return start - reminder;
  }

  /// What the form holds, as the writer takes it: null with nothing to
  /// write at all.
  CalendarEventDraft? _draft() {
    final text = _text.text.trim();
    // A time with nothing to say is not an event: the text is what the
    // line is for.
    if (text.isEmpty) return null;
    final start = _start;
    final reminder = _remind && start != null ? start - _lead : null;
    return CalendarEventDraft(
      text: text,
      startMinutes: start,
      endMinutes: _end,
      // A lead that would land on the day before is not written: a
      // calendar line's `rem:` is a clock time on its own day.
      reminderMinutes: reminder == null || reminder < 0 ? null : reminder,
      recurrence: _rule == null
          ? null
          : CalendarRecurrence(
              rule: _rule!,
              bounds: RecurrenceBounds(until: _until, except: _except),
            ),
    );
  }

  void _setRule(RecurrenceRule? rule) {
    setState(() {
      _rule = rule;
      if (rule == null) {
        _until = null;
        _customOpen = false;
      }
    });
  }

  /// Opens the custom editor under the Repeat row, or closes it. An event
  /// with no rule yet starts at every day, so the editor shows what is set.
  void _toggleCustom() {
    if (!_customOpen && _rule == null) {
      _rule = RecurrenceRule(unit: RecurrenceUnit.day);
    }
    setState(() => _customOpen = !_customOpen);
  }

  /// Inserts [token] at the end of the text, spaced, and keeps the caret
  /// there so typing continues after it.
  void _insertToken(String token) {
    final head = _text.text;
    final spaced = head.isEmpty || head.endsWith(' ') ? head : '$head ';
    final text = '$spaced$token ';
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
    _textFocus.requestFocus();
  }

  /// The suggested tokens: the pool the two files carry, without the ones
  /// already written in the field.
  List<String> _suggestionsFor() {
    final written = parseTokens(_text.text);
    final rest = [
      for (final token in widget.knownTokens)
        if (!written.contains(token)) token,
    ]..sort();
    return rest.take(_suggestions).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final draft = _draft();
    final suggestions = _suggestionsFor();
    return Card.filled(
      key: const Key('calendar-event-form'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(
          // Wrapped, not filled: on a phone the form rides in a bottom
          // sheet, whose loose height it would otherwise take in full and
          // push its own head under the status bar.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  widget.draft == null
                      ? AppStrings.calendarNewEvent
                      : AppStrings.todoEditAction,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    journalDayLabel(widget.day),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            CalendarEventTimes(
              start: _start,
              end: _end,
              onStart: (start) => setState(() {
                _start = start;
                if (start == null) _remind = false;
              }),
              onEnd: (end) => setState(() => _end = end),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('calendar-event-text'),
              controller: _text,
              focusNode: _textFocus,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                hintText: 'meeting with Luca',
              ),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final token in suggestions)
                    ActionChip(
                      key: Key('calendar-event-suggest-$token'),
                      label: Text(token),
                      onPressed: () => _insertToken(token),
                    ),
                ],
              ),
            ],
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ActionChip(
                  label: Text(AppStrings.todoAddProject),
                  onPressed: () => _insertToken('+'),
                ),
                ActionChip(
                  label: Text(AppStrings.todoAddContext),
                  onPressed: () => _insertToken('@'),
                ),
                ActionChip(
                  label: Text(AppStrings.todoAddHashtag),
                  onPressed: () => _insertToken('#'),
                ),
              ],
            ),
            CalendarEventRepeat(
              day: widget.day,
              rule: _rule,
              until: _until,
              enabled: !_only,
              customOpen: _customOpen,
              onRule: _setRule,
              onUntil: (until) => setState(() => _until = until),
              onToggleCustom: _toggleCustom,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.calendarRemindMe,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (_remind && _start != null)
                  MenuChoiceButton<int>(
                    key: const Key('calendar-event-lead'),
                    value: _lead,
                    options: [
                      // The event's own lead too, when it is not one of
                      // the offered ones: editing must not quietly move a
                      // reminder that was set elsewhere.
                      for (final lead in {...calendarReminderLeads, _lead})
                        (lead, AppStrings.calendarRemindBefore(lead)),
                    ],
                    onChanged: (lead) => setState(() => _lead = lead),
                  ),
                AppSwitch(
                  key: const Key('calendar-event-remind'),
                  value: _remind,
                  onChanged: _start == null
                      ? null
                      : (value) => setState(() => _remind = value),
                ),
              ],
            ),
            if (draft != null &&
                (draft.text.isNotEmpty || draft.startMinutes != null)) ...[
              const SizedBox(height: 4),
              Text(
                AppStrings.calendarLinePreview,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              CalendarEventPreview(
                line: widget.preview(draft),
                body: calendarEventAsText(draft),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('calendar-event-cancel'),
                  onPressed: widget.onCancel,
                  child: Text(AppStrings.actionCancel),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  key: const Key('calendar-event-save'),
                  onPressed: draft == null ? null : _save,
                  child: Text(
                    widget.draft == null
                        ? AppStrings.calendarAdd
                        : AppStrings.todoSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final draft = _draft();
    if (draft == null) return;
    widget.onSave(draft);
  }
}

/// The `+`/`@`/`#` tokens in [text], sigil included — what the form leaves
/// out of the suggestions.
Set<String> parseTokens(String text) => {
  for (final match in RegExp(r'(?:^|\s)([+@#]\S+)').allMatches(text))
    ?match.group(1),
};
