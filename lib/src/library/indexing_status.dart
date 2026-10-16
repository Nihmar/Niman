import 'package:flutter/foundation.dart';

/// Whether the open library's notes are still being read into the index
/// (#1068).
///
/// A library indexed for the first time opens on its tree and reads its
/// notes behind it, so for a while Search, Tags and the links of a note
/// answer from a partial index. The screens that read those say so while this
/// is true. One library is open at a time, so one flag serves; the session
/// sets it for the length of the content pass and clears it when the pass
/// ends, fails or the library closes.
abstract final class IndexingStatus {
  /// True while a content pass is reading the library's notes.
  static final ValueNotifier<bool> contentOwed = ValueNotifier<bool>(false);
}
