/// The journal's Add event form, and its edit form (#730): inline in the
/// dock, where the calendar is; in a sheet on a phone.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/calendar_occurrence_edits.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/calendar_writer.dart';
import 'package:niman/src/ui/calendar_event_form.dart';

/// The form itself, writing when it is told to and closing either way.
final class JournalEventEditor extends StatelessWidget {
  /// The Add event form for [day] — or the edit form for [editing], for
  /// the occurrences [scope] names.
  ///
  /// [onAddEvent] and [onEditEvent] write what the form saves; [onClose]
  /// closes it, after a save as after a cancel.
  const new({
    required this.day,
    required this.knownTokens,
    required this.onClose,
    this.editing,
    this.scope,
    this.calendarFile,
    this.onAddEvent,
    this.onEditEvent,
    super.key,
  });

  /// The day the form writes the event on.
  final DateTime day;

  /// The event the form is editing, or null when it is adding one.
  final CalendarEntryEvent? editing;

  /// The occurrences the edit covers, when the event repeats.
  final CalendarOccurrenceScope? scope;

  /// The `+`/`@`/`#` tokens the two files already use, for the form's
  /// suggestions (#730).
  final Set<String> knownTokens;

  /// The calendar file as it is now: the form previews the line the
  /// writer would make of it.
  final CalendarFileContent? calendarFile;

  /// Writes a new event on a day.
  final void Function(DateTime day, CalendarEventDraft event)? onAddEvent;

  /// Replaces an entry's event with the draft the form handed over, for
  /// the occurrences the scope names (#1191).
  final void Function(
    CalendarEntryEvent entry,
    CalendarEventDraft event,
    CalendarOccurrenceScope scope,
  )?
  onEditEvent;

  /// Closes the form: the sheet's pop on a phone, the inline form's end in
  /// the dock.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final editing = this.editing;
    return CalendarEventForm(
      // The form's fields are read once, from its draft: a form for another
      // event, day or scope, or for an added event after an edit, is another
      // state, not the open one with its fields (#1218).
      key: ValueKey((
        editing?.lineIndex,
        editing?.event.start,
        editing?.day,
        scope,
        day,
      )),
      day: day,
      knownTokens: knownTokens,
      draft: editing == null ? null : calendarDraftOf(editing.event),
      scope: scope,
      preview: _previewLine,
      onCancel: onClose,
      onSave: (draft) {
        if (editing != null) {
          onEditEvent?.call(
            editing,
            draft,
            scope ?? CalendarOccurrenceScope.all,
          );
        } else {
          onAddEvent?.call(draft.day ?? day, draft);
        }
        onClose();
      },
    );
  }

  /// The lines an added or edited [draft] would write — the day's, or two
  /// when the event moves or one occurrence leaves its rule — from the file
  /// as the shell last read it: the writer's own answer, so the preview
  /// promises exactly what the write does.
  String _previewLine(CalendarEventDraft draft) {
    final editing = this.editing;
    final file =
        calendarFile ?? const CalendarFileContent(lines: <CalendarRawLine>[]);
    final next = editing == null
        ? addCalendarEvent(file, draft.day ?? day, draft: draft)
        : updateCalendarOccurrence(
                file,
                CalendarEventRef(
                  line: editing.lineIndex,
                  day: editing.line.date ?? day,
                  start: editing.event.start,
                ),
                // The occurrence, whichever day the form is on.
                editing.day ?? day,
                draft,
                scope ?? CalendarOccurrenceScope.all,
              ) ??
              file;
    final before = {for (final line in file.lines) line.text};
    return [
      for (final line in next.lines)
        if (!before.contains(line.text)) line.text,
    ].join('\n');
  }
}
