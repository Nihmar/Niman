import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The clock the tree's clicks are timed with.
///
/// Telling a double click from two single ones is a question about real
/// time: the shell compares the gap between two clicks on a note with
/// `kDoubleTapTimeout` (300 ms). A widget test's clock is not that clock —
/// `tester.pump` moves the test binding's fake time, and the two taps
/// still cost the machine whatever they cost it — so on a loaded host the
/// two halves of a scripted double click can land further apart than the
/// window, be read as two single clicks, and redden a suite that is green
/// (#437).
///
/// The test that covers the double click replaces this with a clock it
/// steps itself, so the gap is the test's to decide and the machine's load
/// cannot decide it. The app answers [DateTime.now].
final treeClickClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
