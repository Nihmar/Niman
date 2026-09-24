/// The journal's settings (#7): where the entries go, how they are named,
/// which template makes them, and when a new day begins.
///
/// Library settings, kept in `.niman/settings.json`: the journal is part
/// of how the library is organised, so it travels with it.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/journal/journal_pattern.dart';

/// The folder a fresh library keeps its entries in.
const String defaultJournalFolder = 'Journal';

/// The latest hour a day may be said to start at: past it, "yesterday"
/// would be most of today.
const int maxJournalDayStartHour = 6;

/// The journal's settings.
@immutable
final class JournalSettings {
  /// Settings with [folder], [entryName], [template] and [dayStartHour];
  /// the defaults are a fresh library's.
  const new({
    this.folder = defaultJournalFolder,
    this.entryName = defaultJournalEntryName,
    this.template,
    this.dayStartHour = 0,
  });

  /// Reads the four keys out of `settings.json`. A value that is missing,
  /// of the wrong type or out of range reads as the default, the settings
  /// file's rule; an entry name that cannot name one entry per day too.
  factory fromJson(Map<String, Object?> json) {
    final folder = json[folderKey];
    final name = json[entryNameKey];
    final template = json[templateKey];
    final start = json[dayStartKey];
    return JournalSettings(
      folder: folder is String
          ? cleanJournalFolder(folder)
          : defaultJournalFolder,
      entryName: name is String && JournalPattern.tryParse(name) != null
          ? name
          : defaultJournalEntryName,
      template: template is String && template.trim().isNotEmpty
          ? template.trim()
          : null,
      dayStartHour:
          start is int && start >= 0 && start <= maxJournalDayStartHour
          ? start
          : 0,
    );
  }

  /// The `settings.json` keys.
  static const String folderKey = 'journalFolder';

  /// See [folderKey].
  static const String entryNameKey = 'journalEntryName';

  /// See [folderKey].
  static const String templateKey = 'journalTemplate';

  /// See [folderKey].
  static const String dayStartKey = 'journalDayStart';

  /// Every key, for the settings file's known-key list.
  static const Set<String> keys = {
    folderKey,
    entryNameKey,
    templateKey,
    dayStartKey,
  };

  /// The library-relative folder the entries go in; empty is the root.
  final String folder;

  /// The entry-name pattern ([JournalPattern]).
  final String entryName;

  /// The library-relative path of the template that makes an entry, or
  /// null for the built-in one: a heading with the day's date.
  final String? template;

  /// The hour a new day begins, 0 to [maxJournalDayStartHour]: at 4,
  /// "today" until four in the morning is still the day before.
  final int dayStartHour;

  /// The parsed [entryName].
  JournalPattern get pattern => JournalPattern.orDefault(entryName);

  /// The library-relative path of [day]'s entry.
  String entryPath(DateTime day) {
    final name = '${pattern.format(day)}.md';
    return folder.isEmpty ? name : '$folder/$name';
  }

  /// The day [path] is the entry of, or null when it is not an entry.
  DateTime? dayOfPath(String path) {
    if (!path.endsWith('.md')) return null;
    final prefix = folder.isEmpty ? '' : '$folder/';
    if (!path.startsWith(prefix)) return null;
    return pattern.dayOf(
      path.substring(prefix.length, path.length - '.md'.length),
    );
  }

  /// The journal's day at [now]: the calendar day, or the one before
  /// while it is still earlier than [dayStartHour].
  DateTime today(DateTime now) {
    final shifted = now.hour < dayStartHour
        ? DateTime(now.year, now.month, now.day - 1)
        : now;
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  /// The keys as `settings.json` holds them; a null template is left out.
  Map<String, Object?> toJson() => {
    folderKey: folder,
    entryNameKey: entryName,
    templateKey: ?template,
    dayStartKey: dayStartHour,
  };

  /// These settings with the given fields replaced; [clearTemplate] goes
  /// back to the built-in template.
  JournalSettings copyWith({
    String? folder,
    String? entryName,
    String? template,
    bool clearTemplate = false,
    int? dayStartHour,
  }) => JournalSettings(
    folder: folder ?? this.folder,
    entryName: entryName ?? this.entryName,
    template: clearTemplate ? null : template ?? this.template,
    dayStartHour: dayStartHour ?? this.dayStartHour,
  );

  @override
  bool operator ==(Object other) =>
      other is JournalSettings &&
      other.folder == folder &&
      other.entryName == entryName &&
      other.template == template &&
      other.dayStartHour == dayStartHour;

  @override
  int get hashCode => Object.hash(folder, entryName, template, dayStartHour);
}

/// [folder] trimmed, without empty, `.` or `..` segments or a leading
/// or trailing `/`; empty is the library root.
String cleanJournalFolder(String folder) => folder
    .trim()
    .split('/')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty && s != '.' && s != '..')
    .join('/');
