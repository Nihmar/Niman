/// The kind of the note on screen (T-TK-02; issue #100 moved it out of the
/// shell): what its view reports, whether the raw editor is shown in place
/// of the kind's GUI (T-TK-05), and the kind of every other open tab.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/strings.dart';

/// The open notes' kinds, as their views last reported them.
final class ShellNoteKind {
  /// The kinds of a library whose [features] say which views are on, every
  /// change through [update], the shell's `setState`, while [mounted]
  /// holds.
  new({required this.features, required this.update, required this.mounted});

  /// The library's features (#1109): a kind whose feature is off has no
  /// view.
  final Features Function() features;

  /// The shell's `setState`: the app bar and the panes read the kind.
  final void Function(VoidCallback change) update;

  /// Whether the shell is still up.
  final bool Function() mounted;

  /// The open note's kind (the frontmatter `type`, null = plain note or
  /// no note); reported by the open NoteView (T-TK-02).
  String? type;

  /// Whether the open note shows the raw editor instead of its kind GUI
  /// (the app-bar pencil toggle, T-TK-05).
  bool raw = false;

  /// Each open note's kind as its view last reported it, by path (#1081): a
  /// pane's own controls are decided by its own note, not by the focused
  /// pane's.
  final Map<String, String?> _tabKinds = {};

  /// The open NoteView reports the note's kind; the app bar shows the
  /// kind toggle for known kinds.
  void reported(String? type) {
    if (!mounted()) return;
    update(() => this.type = type);
  }

  /// The view of the tab at [path] reports its note's [kind].
  void tabReported(String path, String? kind) {
    if (!mounted()) return;
    if (_tabKinds.containsKey(path) && _tabKinds[path] == kind) return;
    update(() => _tabKinds[path] = kind);
  }

  /// The GUI behind the open note's kind (T-TK-02): null for a plain
  /// note, no note, a `type` without a registered GUI (a `type: list`
  /// note is a list, everything else is a document) or one whose feature
  /// is off (#1109).
  NoteKindGUI? get gui => NoteKinds.forType(type, features());

  /// The kind the open note is shown as: [type], when its view is on.
  String? get shown => gui?.type;

  /// Whether the note on screen is a deck shown as its slides (#534).
  bool get showsSlides => shown == 'slides' && !raw;

  /// Whether the note on screen is a flashcard deck shown as its cards
  /// (#533).
  bool get showsDeck => shown == 'flashcard' && !raw;

  /// Forgets the open note's kind: another note is about to report its own.
  /// In the `setState` of the caller.
  void reset() {
    type = null;
    raw = false;
  }

  /// The GUI behind the kind the tab at [path] last reported.
  NoteKindGUI? guiOf(String path) =>
      NoteKinds.forType(_tabKinds[path], features());

  /// The tabs under [from] were renamed or moved to [to]: their kinds go
  /// with them.
  void moved(String from, String to) {
    for (final entry in [..._tabKinds.entries]) {
      final path = entry.key;
      if (path == from || path.startsWith('$from/')) {
        _tabKinds
          ..remove(path)
          ..[to + path.substring(from.length)] = entry.value;
      }
    }
  }

  /// Forgets the kinds of the tabs whose view is not [mounted] any more.
  void keepOnly(Set<String> mounted) =>
      _tabKinds.removeWhere((path, _) => !mounted.contains(path));

  /// The kind toggle actions (T-TK-05): a note whose kind has a GUI offers
  /// the raw editor (pencil, [onEditRaw]); in raw mode the kind GUI is
  /// offered back. A [wide] window presents slides from the bar
  /// ([onPresent]). Empty when the open note has no kind GUI (including
  /// unknown `type`s).
  List<Widget> actions({
    required bool wide,
    required VoidCallback onPresent,
    required VoidCallback onEditRaw,
  }) {
    if (gui == null) return const [];
    final icon = switch (type) {
      'audio' => Icons.mic_outlined,
      'slides' => Icons.slideshow_outlined,
      'flashcard' => Icons.style_outlined,
      'kanban' => Icons.view_kanban_outlined,
      'shopping-list' => Icons.shopping_cart_outlined,
      _ => Icons.checklist,
    };
    return [
      // The phone presents from the button under its slides, or by
      // turning: its bar keeps to the pencil and the ⋮.
      if (showsSlides && wide)
        IconButton(
          key: const Key('slides-present-action'),
          tooltip: switch (AppKeyMap.current.value.bindingOf(
            AppCommand.presentSlides,
          )) {
            final keys? =>
              '${AppStrings.slidesPresent} (${describeActivator(keys)})',
            null => AppStrings.slidesPresent,
          },
          icon: const Icon(Icons.present_to_all_outlined),
          onPressed: onPresent,
        ),
      if (raw)
        IconButton(
          key: const Key('kind-show-list'),
          tooltip: switch (type) {
            'audio' => AppStrings.showAudioTooltip,
            'slides' => AppStrings.showSlidesTooltip,
            'flashcard' => AppStrings.showFlashcardsTooltip,
            'kanban' => AppStrings.showKanbanTooltip,
            _ => AppStrings.showListTooltip,
          },
          icon: Icon(icon),
          onPressed: () => update(() => raw = false),
        )
      else
        IconButton(
          key: const Key('kind-edit-raw'),
          tooltip: AppStrings.editRawTooltip,
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEditRaw,
        ),
    ];
  }
}
