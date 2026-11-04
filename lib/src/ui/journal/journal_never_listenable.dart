/// A listenable that never fires, for the journal browser's sections when
/// the shell gives nothing to follow.
library;

import 'package:flutter/foundation.dart';

/// A listenable that never fires, for a browser with no tasks to follow.
final class NeverListenable implements Listenable {
  /// The listenable; it holds nothing, so one serves every browser.
  const new();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
