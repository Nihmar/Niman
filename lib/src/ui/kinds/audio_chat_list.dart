import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/audio_chat_row.dart';

/// The scrolling chat of an audio note: bubbles fade and expand in as
/// rows arrive, collapse out as they go, and update in place otherwise.
class AudioChatList extends StatefulWidget {
  /// Creates the list over [rows], each drawn by [buildRow].
  const new({required this.rows, required this.buildRow, super.key});

  /// The rows in document order; a new list instance re-syncs the chat.
  final List<AudioChatRow> rows;

  /// Draws one bubble.
  final Widget Function(AudioChatRow row) buildRow;

  @override
  State<AudioChatList> createState() => _AudioChatListState();
}

class _AudioChatListState extends State<AudioChatList> {
  late List<AudioChatRow> _rows;
  // Re-created after a wholesale reorder, so the list rebuilds from
  // scratch instead of replaying stale insert/remove animations.
  GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final ScrollController _scroll = ScrollController();

  /// Whether the list keeps the bottom while the last turn grows (#735):
  /// a recording landing brings its own grow animation, and the extent an
  /// animation to the bottom read before it is short by the time it ends.
  /// A reader's own scroll turns this off, and it comes back when they
  /// scroll to the bottom again.
  bool _followBottom = false;

  /// How many of the list's own glides to the bottom are running: their
  /// end is not a reader letting go (#767).
  int _glides = 0;

  @override
  void initState() {
    super.initState();
    _rows = List.of(widget.rows);
    // Open a loaded conversation at its latest message.
    if (_rows.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void didUpdateWidget(AudioChatList old) {
    super.didUpdateWidget(old);
    if (!identical(old.rows, widget.rows)) _sync(widget.rows);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Applies the re-parsed [next] rows to the animated list.
  void _sync(List<AudioChatRow> next) {
    final list = _listKey.currentState;
    if (list == null) {
      _rows = List.of(next);
      return;
    }
    final oldKeys = _keysOf(_rows);
    final newKeys = _keysOf(next);
    final wasAtBottom =
        _scroll.hasClients &&
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 1;
    for (var i = _rows.length - 1; i >= 0; i--) {
      if (!newKeys.contains(oldKeys[i])) {
        final row = _rows[i];
        list.removeItem(i, (context, animation) => _animated(row, animation));
        _rows.removeAt(i);
      }
    }
    for (var j = 0; j < next.length; j++) {
      if (!oldKeys.contains(newKeys[j])) {
        // The insert animation reaches the row through itemBuilder.
        list.insertItem(j);
        _rows.insert(j, next[j]);
      }
    }
    if (!_sameKeySequence(_keysOf(_rows), newKeys)) {
      // The rows came back reordered (an external edit): rebuild the list
      // without animation.
      _listKey = GlobalKey();
    }
    _rows = List.of(next);
    // A new turn is always brought into view; a change that grows a turn
    // in place — the transcript of one, arriving later — keeps the bottom
    // only for a reader who was already there (#735).
    if (next.length > oldKeys.length) {
      _followBottom = true;
      _scrollToBottom();
    } else {
      _followBottom = wasAtBottom;
    }
  }

  List<String> _keysOf(List<AudioChatRow> rows) =>
      rows.map((row) => row.key).toList();

  bool _sameKeySequence(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      if (position.pixels >= position.maxScrollExtent) return;
      final target = position.maxScrollExtent;
      _glides++;
      unawaited(
        _scroll
            .animateTo(
              target,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            )
            // The extent the glide aimed at was an estimate while the
            // inserted row is growing: the rest is a jump, not a second
            // animation (#735).
            .whenComplete(() {
              _glides--;
              if (!mounted || !_scroll.hasClients) return;
              final landed = _scroll.position;
              if ((landed.pixels - target).abs() > 0.5) {
                // Cut short by the reader. A drag that takes over a glide
                // sends no scroll start (the position was scrolling
                // already), and a wheel's or the scrollbar's scroll end
                // went by while the glide still counted: so their scroll
                // decides — still under way, its own end will; over,
                // where it left the list does.
                if (!landed.isScrollingNotifier.value) {
                  _followBottom = landed.pixels >= landed.maxScrollExtent - 1;
                }
                return;
              }
              if (!_followBottom) return;
              if (landed.pixels < landed.maxScrollExtent) {
                landed.jumpTo(landed.maxScrollExtent);
              }
            }),
      );
    });
  }

  /// The list grew while it follows the bottom — the inserted row's own
  /// grow animation, mostly (#735): the bottom is taken again once the
  /// frame is over, and while an animation or a drag is running the
  /// gesture keeps its say.
  bool _onMetrics(ScrollMetricsNotification notification) {
    if (!_followBottom || !mounted) return false;
    final position = _scroll.hasClients ? _scroll.position : null;
    if (position == null || position.isScrollingNotifier.value) return false;
    if (position.pixels >= position.maxScrollExtent) return false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_followBottom || !_scroll.hasClients) return;
      final landed = _scroll.position;
      if (landed.isScrollingNotifier.value) return;
      if (landed.pixels < landed.maxScrollExtent) {
        landed.jumpTo(landed.maxScrollExtent);
      }
    });
    return false;
  }

  /// A reader taking the list over ends the following; letting go at the
  /// bottom starts it again.
  ///
  /// The end of the list's own glide is no reader's (#767): Flutter sends
  /// it as the glide's activity is replaced, before the glide's future
  /// completes, with the pixels of the stale target and an extent the
  /// growing row already raised. Read as a reader's, it turned the
  /// following off, and the jump that finishes the glide never ran.
  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _followBottom = false;
    } else if (notification is ScrollEndNotification && _glides == 0) {
      _followBottom =
          notification.metrics.pixels >=
          notification.metrics.maxScrollExtent - 1;
    }
    return false;
  }

  Widget _animated(AudioChatRow row, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        alignment: Alignment.topLeft,
        child: widget.buildRow(row),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetrics,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: AnimatedList(
          key: _listKey,
          controller: _scroll,
          initialItemCount: _rows.length,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          itemBuilder: (context, index, animation) =>
              _animated(_rows[index], animation),
        ),
      ),
    );
  }
}
