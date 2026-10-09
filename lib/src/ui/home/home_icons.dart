/// The icons and names of the Home's tiles and actions (#535).
///
/// An action keeps its icon by name: the file is the library's and travels
/// between builds, and an `IconData` built from a stored code point would
/// stop the icon font being trimmed to the icons the app uses.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The icons an action can wear, by the name the file keeps; outline, as
/// every icon of the app that does not say a state is on.
const Map<String, IconData> homeActionIcons = {
  'note_add': Icons.note_add_outlined,
  'edit_note': Icons.edit_note_outlined,
  'today': Icons.today_outlined,
  'add_task': Icons.add_task_outlined,
  'description': Icons.description_outlined,
  'content_cut': Icons.content_cut_outlined,
  'event': Icons.event_outlined,
  'groups': Icons.groups_outlined,
  'menu_book': Icons.menu_book_outlined,
  'lightbulb': Icons.lightbulb_outline,
  'receipt_long': Icons.receipt_long_outlined,
  'work': Icons.work_outline,
  'school': Icons.school_outlined,
  'bookmark': Icons.bookmark_border,
  'star': Icons.star_border,
  'link': Icons.link_outlined,
};

/// The icon a kind of action wears when it names none.
String defaultActionIcon(HomeActionKind? kind) => switch (kind) {
  HomeActionKind.newNote || null => 'note_add',
  HomeActionKind.addTask => 'add_task',
  HomeActionKind.openNote => 'description',
  HomeActionKind.journal => 'today',
  HomeActionKind.capture => 'content_cut',
};

/// [action]'s icon.
IconData homeActionIcon(HomeAction action) =>
    homeActionIcons[action.icon] ??
    homeActionIcons[defaultActionIcon(action.kind)]!;

/// What a kind of action does, as the editor names it.
String homeActionKindName(HomeActionKind kind) => switch (kind) {
  HomeActionKind.newNote => AppStrings.shortcutNewNote,
  HomeActionKind.addTask => AppStrings.todoAddTooltip,
  HomeActionKind.openNote => AppStrings.homeActionKindOpenNote,
  HomeActionKind.journal => AppStrings.journalToday,
  HomeActionKind.capture => AppStrings.captureWebPage,
};

/// [action]'s label: its own, or what its kind does.
String homeActionLabel(HomeAction action) {
  if (action.label.isNotEmpty) return action.label;
  return switch (action.kind) {
    HomeActionKind.newNote || null => AppStrings.shortcutNewNote,
    HomeActionKind.addTask => AppStrings.todoAddTooltip,
    HomeActionKind.openNote => p.basenameWithoutExtension(action.path ?? ''),
    HomeActionKind.journal => AppStrings.journalToday,
    HomeActionKind.capture => AppStrings.captureWebPage,
  };
}

/// The icon a tile of [kind] wears in its title.
IconData homeTileIcon(HomeTileKind kind) => switch (kind) {
  HomeTileKind.actions => Icons.bolt_outlined,
  HomeTileKind.journalToday => Icons.today_outlined,
  HomeTileKind.tasksDue => Icons.check_box_outlined,
  HomeTileKind.recent => Icons.history,
  HomeTileKind.pinned => Icons.push_pin_outlined,
  HomeTileKind.journalCalendar => Icons.calendar_month_outlined,
  HomeTileKind.topTags => Icons.sell_outlined,
  HomeTileKind.randomNote => Icons.casino_outlined,
  HomeTileKind.search => Icons.saved_search,
};

/// The name of a tile of [kind].
String homeTileName(HomeTileKind kind) => switch (kind) {
  HomeTileKind.actions => AppStrings.homeTileActions,
  HomeTileKind.journalToday => AppStrings.homeTileJournalToday,
  HomeTileKind.tasksDue => AppStrings.homeTileTasksDue,
  HomeTileKind.recent => AppStrings.homeTileRecent,
  HomeTileKind.pinned => AppStrings.homeTilePinned,
  HomeTileKind.journalCalendar => AppStrings.homeTileJournalCalendar,
  HomeTileKind.topTags => AppStrings.homeTileTopTags,
  HomeTileKind.randomNote => AppStrings.homeTileRandomNote,
  HomeTileKind.search => AppStrings.homeTileSearch,
};

/// [tile]'s title: a search tile's own name, else its kind's.
String homeTileTitle(HomeTile tile) {
  if (tile.kind == HomeTileKind.search && tile.title.isNotEmpty) {
    return tile.title;
  }
  return homeTileName(tile.kind!);
}
