/// A request for the Search tab from elsewhere in the app (#535).
library;

import 'package:flutter/foundation.dart';

/// What another part of the app asks Search to show (#535): a query typed
/// into the box, or a tag's notes in Tags. A new request is a new object,
/// so asking for the same thing twice is heard twice.
@immutable
final class SearchRequest {
  /// The words (or `key = value`) [text], typed in.
  const new forText(this.text) : tag = null;

  /// The notes of [tag].
  const new forTag(String this.tag) : text = '';

  /// The query, when it is one.
  final String text;

  /// The tag, when it is one.
  final String? tag;
}

/// What the shell asks the search screen to do, besides showing something
/// (#712): give the query field the focus, or step through the hits.
///
/// A channel like [SearchRequest] because the screen's state is its own —
/// the sidebar builds it — so the shell says what to do and the screen,
/// which owns the hits and the field, does it.
final class SearchCommands extends ChangeNotifier {
  /// Asks for the query field's focus (`Ctrl+Shift+F`).
  void focus() {
    _focusPending = true;
    notifyListeners();
  }

  /// Asks to open the next hit ([direction] 1) or the previous (-1)
  /// (`F4` / `Shift+F4`), from the current one.
  void stepBy(int direction) {
    _step = direction;
    notifyListeners();
  }

  /// Whether a focus ask is waiting, clearing it (#768): an ask is an
  /// event, answered once — a screen mounted later does not take the
  /// focus for a `Ctrl+Shift+F` pressed long before.
  bool takeFocus() {
    final pending = _focusPending;
    _focusPending = false;
    return pending;
  }

  bool _focusPending = false;

  /// The step waiting to be taken — 1 for the next hit, -1 for the
  /// previous, 0 for none — clearing it (#768): a step is an event, so a
  /// later notification (a focus ask) does not repeat it.
  int takeStep() {
    final step = _step;
    _step = 0;
    return step;
  }

  int _step = 0;
}
