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
