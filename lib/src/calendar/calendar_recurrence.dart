/// The rule an event of `calendar.txt` repeats by (#1190): its first
/// `rec:` token, bounded by `until:` and `except:`.
///
/// ```text
/// 2026-10-21 Wed w43  9-9:30 Standup @work rec:1w until:2026-12-31. 17 jog
/// ```
///
/// The grammar is the one tasks use (`RecurrenceRule`); the bounds are
/// `RecurrenceBounds`. What the parser keeps of the three is a `key:value`
/// token as for any other, so reading them here changes nothing about the
/// round trip: a line comes back as it was written.
///
/// Pure Dart, no I/O.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/core/recurrence/recurrence_bounds.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';

/// The rule of an event and the days it does not run on.
@immutable
final class CalendarRecurrence {
  /// Creates a recurrence of [rule] within [bounds].
  const new({required this.rule, required this.bounds});

  /// The rule: every 2 weeks, every weekday, and so on.
  final RecurrenceRule rule;

  /// The last day (`until:`) and the skipped days (`except:`).
  final RecurrenceBounds bounds;

  /// The days from [from] to [to] (inclusive) the event with its own day
  /// [anchor] falls on: the anchor itself — unless it is skipped — and every
  /// day the rule reaches, `until:` and `except:` applied.
  List<DateTime> occurrences({
    required DateTime anchor,
    required DateTime from,
    required DateTime to,
  }) => rule.occurrences(anchor: anchor, from: from, to: to, bounds: bounds);

  /// Reads the recurrence [tokens] spell, or null when there is no readable
  /// `rec:` among them.
  ///
  /// The first `rec:` counts, as it does on a task. An `until:` or
  /// `except:` the grammar cannot read is ignored (the editor flags it):
  /// the first `until:` is the end, and every `except:` list adds its days.
  static CalendarRecurrence? of(List<CalendarToken> tokens) {
    RecurrenceRule? rule;
    DateTime? until;
    var untilSeen = false;
    final except = <DateTime>[];
    var ruleSeen = false;
    for (final token in tokens) {
      final key = ruleKeyOf(token);
      if (key == null) continue;
      final value = token.value.substring(key.length + 1);
      switch (key) {
        case 'rec':
          if (ruleSeen) break;
          ruleSeen = true;
          rule = RecurrenceRule.parse(value);
        case 'until':
          if (untilSeen) break;
          untilSeen = true;
          until = RecurrenceBounds.parseUntil(value);
        case 'except':
          except.addAll(RecurrenceBounds.parseExcept(value) ?? const []);
      }
    }
    if (rule == null) return null;
    return CalendarRecurrence(
      rule: rule,
      bounds: RecurrenceBounds(until: until, except: except),
    );
  }

  @override
  String toString() => 'CalendarRecurrence(rec:${rule.token})';
}

/// The key (`rec`, `until` or `except`) [token] is, or null for any other
/// token.
String? ruleKeyOf(CalendarToken token) {
  if (token.kind != CalendarTokenKind.keyValue) return null;
  final colon = token.value.indexOf(':');
  if (colon < 0) return null;
  final key = token.value.substring(0, colon);
  return _ruleKeys.contains(key) ? key : null;
}

/// Whether [token] is a `rec:`, `until:` or `except:` whose value the
/// grammar does not read: kept as written, doing nothing, and flagged in
/// the editor.
bool isUnreadableRuleToken(CalendarToken token) {
  final key = ruleKeyOf(token);
  if (key == null) return false;
  final value = token.value.substring(key.length + 1);
  return switch (key) {
    'rec' => RecurrenceRule.parse(value) == null,
    'until' => RecurrenceBounds.parseUntil(value) == null,
    _ => RecurrenceBounds.parseExcept(value) == null,
  };
}

const Set<String> _ruleKeys = {'rec', 'until', 'except'};

/// What an event repeats by.
extension CalendarEventRecurrence on CalendarEvent {
  /// The rule the event repeats by, or null when it does not.
  CalendarRecurrence? get recurrence => CalendarRecurrence.of(tokens);
}
