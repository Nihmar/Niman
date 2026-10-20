/// The check a way into the app from outside makes before it opens a
/// screen (#1109): is the feature behind it on in the open library?
///
/// A shortcut, a notification and a widget tap each lead somewhere. When
/// what is there has been switched off, a screen that is not there would be
/// a broken one: the gate says one sentence instead, and the way in is
/// spent. It keeps no flag of its own: it asks the library's features each
/// time.
library;

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';

/// Lets a way in through, or says why not.
final class ShellIntentGate {
  /// A gate over the open library's [features]; [say] tells the user that a
  /// feature is off.
  const new({required this.features, required this.say});

  /// The open library's features.
  final ValueListenable<Features> features;

  /// Says that a feature is off in this library.
  final void Function(LibraryFeature feature) say;

  /// Whether [feature] is on; a null one is core and always is. When it is
  /// off the sentence is said, so a caller only carries on when this
  /// answers true.
  bool allows(LibraryFeature? feature) {
    if (feature == null || features.value.isOn(feature)) return true;
    say(feature);
    return false;
  }
}
