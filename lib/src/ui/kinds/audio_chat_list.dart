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
    if (next.length > oldKeys.length) _scrollToBottom();
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
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
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
    return AnimatedList(
      key: _listKey,
      controller: _scroll,
      initialItemCount: _rows.length,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemBuilder: (context, index, animation) =>
          _animated(_rows[index], animation),
    );
  }
}
