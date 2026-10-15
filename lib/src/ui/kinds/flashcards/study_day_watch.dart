import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/resume_observer.dart';
import 'package:niman/src/flashcards/study_day.dart';

/// The clock the deck view counts the study day by: a seam, since a widget
/// test cannot make `DateTime.now` cross midnight.
final studyClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Tells a view that counts cards for a study day when that day turns (#966).
///
/// A deck stays open on a desktop overnight, and a phone sleeps through the
/// hour a day starts: the counts a view drew for yesterday are wrong the
/// moment the new day begins, and nothing written tells it. So the watch
/// knows the day it was told ([track]) and asks again at the instant the next
/// day starts and whenever the app returns to the foreground, where a timer
/// that ran while the device slept is not to be trusted.
final class StudyDayWatch {
  /// A watch reading the time from [now], calling [onTurn] when the study
  /// day is no longer the one tracked.
  new({required this.now, required this.onTurn}) {
    _resume = ResumeObserver(check);
    WidgetsBinding.instance.addObserver(_resume);
  }

  /// The clock.
  final DateTime Function() now;

  /// Called when the study day changed; the view counts again and tracks
  /// the day it found.
  final VoidCallback onTurn;

  late final ResumeObserver _resume;
  Timer? _timer;
  int _dayStartHour = 0;
  DateTime? _day;

  /// The study day is [day] with a day starting at [dayStartHour]: the watch
  /// waits for the end of it.
  void track(int dayStartHour, DateTime day) {
    _dayStartHour = dayStartHour;
    _day = day;
    _arm();
  }

  /// Calls [onTurn] when the study day is no longer the tracked one.
  void check() {
    final tracked = _day;
    if (tracked == null) return;
    if (studyToday(now(), _dayStartHour) == tracked) {
      _arm();
      return;
    }
    // Told once: the view tracks the new day, which arms the next turn.
    _day = null;
    _timer?.cancel();
    onTurn();
  }

  /// Waits for the hour the day after the tracked one starts.
  void _arm() {
    _timer?.cancel();
    final tracked = _day;
    if (tracked == null) return;
    final next = DateTime(
      tracked.year,
      tracked.month,
      tracked.day + 1,
      _dayStartHour,
    );
    _timer = Timer(next.difference(now()), check);
  }

  /// Stops watching.
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(_resume);
  }
}
