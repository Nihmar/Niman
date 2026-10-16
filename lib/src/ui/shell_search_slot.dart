/// The Search tab's body (issue #100, split out of `shell.dart`):
/// Search and Tags side by side, one of them showing.
///
/// Which of the two shows, and whether Tags has ever been opened, were
/// two fields on the shell that nothing else read. They live here now,
/// where they belong: the shell asks for the slot and hears back only
/// when a note is opened.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/search/task_events.dart';
import 'package:niman/src/ui/search_request.dart';
import 'package:niman/src/ui/search_screen.dart';
import 'package:niman/src/ui/search_task_events.dart';
import 'package:niman/src/ui/tags_screen.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

/// Search, with Tags flipping in over it.
final class SearchSlot extends StatefulWidget {
  /// Creates the slot over [controller]'s library; [requests] carries
  /// what the Home asks it to show.
  const new({
    required this.controller,
    required this.onOpenNote,
    this.onOpenHit,
    this.requests,
    this.commands,
    this.tree = false,
    this.taskEvents,
    this.onOpenTaskEvent,
    this.eventTimesClock = false,
    this.hitOpens,
    this.unsavedTracker,
    super.key,
  });

  /// What to show next, when asked from elsewhere.
  final ValueListenable<SearchRequest?>? requests;

  /// What to do, besides showing: focus the field, step through the hits
  /// (#712).
  final SearchCommands? commands;

  /// The open library.
  final LibrarySession controller;

  /// Opens a hit: the shell's own search-result open.
  final void Function(String path) onOpenNote;

  /// See [SearchScreen.onOpenHit].
  final void Function(String path, List<String> terms)? onOpenHit;

  /// The tasks and events already in memory (#730), and what opens one of
  /// their rows; both null in a host without the two files.
  final TaskEvents? taskEvents;

  /// Opens a row of the group: the shell's own open for a task, an event
  /// or a goal.
  final void Function(TaskEventHit hit)? onOpenTaskEvent;

  /// See [SearchScreen.eventTimesClock].
  final bool eventTimesClock;

  /// See [SearchScreen.hitOpens].
  final SearchHitOpens? hitOpens;

  /// See [SearchScreen.unsavedTracker].
  final UnsavedTracker? unsavedTracker;

  /// Whether Tags draws the wide sidebar's collapsible tree (#712);
  /// false keeps the phone's drill-down.
  final bool tree;

  @override
  State<SearchSlot> createState() => _SearchSlotState();
}

final class _SearchSlotState extends State<SearchSlot> {
  /// Whether Tags is the one showing.
  bool _showTags = false;

  /// Whether Tags has ever been opened: like the tabs, it mounts once and
  /// stays alive so its query survives the flip.
  bool _tagsVisited = false;

  @override
  void initState() {
    super.initState();
    widget.requests?.addListener(_requested);
    // A request made before the first visit mounted this slot.
    if (widget.requests?.value?.tag != null) {
      _showTags = true;
      _tagsVisited = true;
    }
  }

  @override
  void dispose() {
    widget.requests?.removeListener(_requested);
    super.dispose();
  }

  /// Flips to the side a request is for; the screens themselves read what.
  void _requested() {
    final request = widget.requests?.value;
    if (request == null) return;
    final tags = request.tag != null;
    if (tags == _showTags && (!tags || _tagsVisited)) return;
    if (!mounted) return;
    setState(() {
      _showTags = tags;
      if (tags) _tagsVisited = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The flip is instant (same tab, no transition); the outer fade
    // already covered entering the tab. Search retains layout while Tags
    // shows (T-TS-10): flipping back is then paint-only, matching the
    // tab-level switch into Search.
    return Stack(
      fit: StackFit.expand,
      children: [
        Visibility(
          visible: !_showTags,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: TickerMode(
            enabled: !_showTags,
            child: SearchScreen(
              controller: widget.controller,
              onOpenNote: widget.onOpenNote,
              onOpenHit: widget.onOpenHit,
              requests: widget.requests,
              commands: widget.commands,
              taskEvents: widget.taskEvents,
              onOpenTaskEvent: widget.onOpenTaskEvent,
              eventTimesClock: widget.eventTimesClock,
              hitOpens: widget.hitOpens,
              unsavedTracker: widget.unsavedTracker,
              onOpenTags: () => setState(() {
                _showTags = true;
                _tagsVisited = true;
              }),
            ),
          ),
        ),
        if (_tagsVisited)
          Offstage(
            offstage: !_showTags,
            child: TickerMode(
              enabled: _showTags,
              child: TagsScreen(
                controller: widget.controller,
                onOpenNote: widget.onOpenNote,
                requests: widget.requests,
                tree: widget.tree,
                onBack: () => setState(() => _showTags = false),
              ),
            ),
          ),
      ],
    );
  }
}
