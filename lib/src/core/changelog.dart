import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// One titled group of changelog bullets, e.g. "Added".
///
/// A group without a heading (a version whose entries are bare bullets)
/// carries a null [title] and still renders.
final class ChangelogSection {
  /// Creates a group of [items] under the optional [title].
  ///
  /// Not const: a const constructor would turn a list-literal [items]
  /// into a const list, and the parser appends to it.
  new({required this.items, this.title});

  /// The group's heading, or null for a heading-less group.
  final String? title;

  /// The bullet texts, in file order.
  final List<String> items;
}

/// One version's block of the changelog.
final class ChangelogVersion {
  /// Creates an entry for [version] with its [sections].
  ///
  /// Not const: a const constructor would turn a list-literal
  /// [sections] into a const list, and the parser appends to it.
  new({required this.version, required this.sections, this.date});

  /// The version string, e.g. `0.0.3`.
  final String version;

  /// The release date, when the heading carries one.
  final DateTime? date;

  /// The entry's groups, in file order.
  final List<ChangelogSection> sections;
}

/// The shape of a version heading: `## [1.2.3] - 2026-09-14`, the date
/// optional.
final _versionHeading = RegExp(
  r'^## \[([0-9][0-9A-Za-z.\-]*)\](?: - (\d{4}-\d{2}-\d{2}))?\s*$',
);

/// The shape of a group heading: `### Added`.
final _sectionHeading = RegExp(r'^### (.+?)\s*$');

/// The shape of a bullet: `- item` or `* item`.
final _bullet = RegExp(r'^[-*] (.+?)\s*$');

/// Parses [text] into version entries, in file order (newest first, as a
/// changelog is written).
///
/// Only the three shapes above count — a `#` title, prose, download
/// tables and links are all skipped, which is what lets the file keep
/// its human-readable introduction.
List<ChangelogVersion> parseChangelog(String text) {
  final entries = <ChangelogVersion>[];
  ChangelogVersion? version;
  ChangelogSection? section;
  for (final line in text.split('\n')) {
    final heading = _versionHeading.firstMatch(line);
    if (heading != null) {
      version = ChangelogVersion(
        version: heading.group(1)!,
        date: heading.group(2) == null
            ? null
            : DateTime.parse(heading.group(2)!),
        sections: [],
      );
      entries.add(version);
      section = null;
      continue;
    }
    if (version == null) continue;
    final group = _sectionHeading.firstMatch(line);
    if (group != null) {
      section = ChangelogSection(title: group.group(1), items: []);
      version.sections.add(section);
      continue;
    }
    final item = _bullet.firstMatch(line);
    if (item != null) {
      if (section == null) {
        section = ChangelogSection(items: []);
        version.sections.add(section);
      }
      section.items.add(item.group(1)!);
    }
  }
  return entries;
}

/// Whether [a] is a strictly newer version than [b].
///
/// Versions read `major.minor.patch`; a missing piece counts as zero, so
/// `0.2` and `0.2.0` tie, and a non-numeric piece counts as zero too
/// rather than crashing a startup check.
bool isNewerVersion(String a, String b) {
  final partsA = _versionParts(a);
  final partsB = _versionParts(b);
  for (var i = 0; i < 3; i++) {
    if (partsA[i] != partsB[i]) return partsA[i] > partsB[i];
  }
  return false;
}

List<int> _versionParts(String version) {
  final pieces = version.split('.');
  return [
    for (var i = 0; i < 3; i++)
      if (i < pieces.length) int.tryParse(pieces[i]) ?? 0 else 0,
  ];
}

/// The app's own version, `major.minor.patch` as the build reports it.
///
/// Throws when the platform channel is unavailable (tests, web before
/// load): callers that only display the version catch it.
Future<String> appVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}

/// [appVersion] as a provider, for the app root's update check.
final appVersionProvider = FutureProvider<String>((ref) => appVersion());

/// The changelog shipped inside the build, newest version first.
final changelogProvider = FutureProvider<List<ChangelogVersion>>(
  (ref) => _loadChangelog(),
);

/// The versions the user has not seen yet, or null when there is nothing
/// to show.
///
/// Null cases: the first launch (the column is null, and there is no
/// "before" to compare against), a build with no entries newer than the
/// seen one, and any failure along the way (no store metadata, no
/// database — the test bed is one of those). A failure degrades to no
/// dialog rather than to a startup crash.
///
/// The current version is marked seen BEFORE the entries are returned,
/// so a force-quit with the dialog still up does not re-ask on the next
/// launch.
final changelogUpdateProvider = FutureProvider<List<ChangelogVersion>?>((
  ref,
) async {
  try {
    final version = await ref.watch(appVersionProvider.future);
    final entries = await ref.watch(changelogProvider.future);
    final db = await defaultAppDatabase();
    try {
      final repo = AppSettingsRepo(db);
      final seen = await repo.changelogSeenVersion();
      if (seen == null) {
        await repo.setChangelogSeenVersion(version);
        return null;
      }
      final fresh = entries
          .where(
            (entry) =>
                isNewerVersion(entry.version, seen) &&
                // An entry ahead of this build (the file was updated for
                // the next tag) is not news yet.
                !isNewerVersion(version, entry.version),
          )
          .toList();
      if (fresh.isEmpty) return null;
      await repo.setChangelogSeenVersion(version);
      return fresh;
    } finally {
      await db.close();
    }
  } on Object catch (error) {
    const AppLogger(name: 'changelog')
        .warning('update notice skipped ($error)');
    return null;
  }
});

Future<List<ChangelogVersion>> _loadChangelog() async {
  final text = await rootBundle.loadString('CHANGELOG.md');
  return parseChangelog(text);
}
