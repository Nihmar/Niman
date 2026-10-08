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
import 'package:niman/src/ui/search_request.dart';
import 'package:niman/src/ui/search_screen.dart';
import 'package:niman/src/ui/tags_screen.dart';

/// Search, with Tags flipping in over it.
final class SearchSlot extends StatefulWidget {
  /// Creates the slot over [controller]'s library; [requests] carries
  /// what the Home asks it to show.
  const new({
    required this.controller,
    required this.onOpenNote,
    this.requests,
    super.key,
  });

  /// What to show next, when asked from elsewhere.
  final ValueListenable<SearchRequest?>? requests;

  /// The open library.
  final LibrarySession controller;

  /// Opens a hit: the shell's own search-result open.
  final void Function(String path) onOpenNote;

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
              requests: widget.requests,
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
                onBack: () => setState(() => _showTags = false),
              ),
            ),
          ),
      ],
    );
  }
}
