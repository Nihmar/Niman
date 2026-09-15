import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/ui/strings.dart';

/// The short label for why [reason] kept a version ("before editing").
String historyReasonLabel(HistoryReason reason) => switch (reason) {
  HistoryReason.session => AppStrings.historyReasonSession,
  HistoryReason.interval => AppStrings.historyReasonInterval,
  HistoryReason.restore => AppStrings.historyReasonRestore,
  HistoryReason.sync => AppStrings.historyReasonSync,
  HistoryReason.replace => AppStrings.historyReasonReplace,
  HistoryReason.unknown => AppStrings.historyReasonUnknown,
};

/// `HH:mm` of [time].
String historyTime(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// The day group [time] falls in, seen from [now]: "Today", "Yesterday",
/// or the day and short month ("12 Sep"), with the year when it is not
/// [now]'s.
String historyDay(DateTime time, DateTime now) {
  final day = DateTime(time.year, time.month, time.day);
  final today = DateTime(now.year, now.month, now.day);
  final age = today.difference(day).inDays;
  if (age == 0) return AppStrings.historyToday;
  if (age == 1) return AppStrings.historyYesterday;
  final month = AppStrings.monthNamesShort[time.month - 1];
  return time.year == now.year
      ? '${time.day} $month'
      : '${time.day} $month ${time.year}';
}

/// How a version is named in a sentence: "today, 08:24" or
/// "12 Sep, 09:15".
///
/// Only "today" and "yesterday" are lowercased: a month name keeps its
/// language's own case (German capitalizes it).
String historyWhen(DateTime time, DateTime now) {
  final day = historyDay(time, now);
  final relative =
      day == AppStrings.historyToday || day == AppStrings.historyYesterday;
  return '${relative ? day.toLowerCase() : day}, ${historyTime(time)}';
}
