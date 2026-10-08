import 'package:flutter/foundation.dart';

// ponytail: one int per slides note opened this run, never trimmed; a map
// keyed by path is all the slide view, the presenting screens and the
// shell's ⋮ need to agree on the slide on screen.
final Map<String, ValueNotifier<int>> _places = {};

/// The slide on screen for the note at [notePath] (#534): the slide view
/// moves it, presenting starts from it and leaves it where the talk
/// stopped. Kept for the run, so a note opened again finds its slide.
ValueNotifier<int> slidePlaceOf(String notePath) =>
    _places.putIfAbsent(notePath, () => ValueNotifier(0));
