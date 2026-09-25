/// The look the open library's books wear (#280), where the book's pane
/// reads it.
///
/// A small global for the reason `core/text_scale.dart` is one: the value
/// is the library's, published when it opens and put back when it closes,
/// and read far below anything that could carry it.
library;

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/epub/epub_look.dart';

/// The books' look, and the theme it names.
final class EpubLooks {
  const new _();

  /// Bumped whenever the look changes; an open book listens to it, so a
  /// pick in the sheet or in Settings reaches it at once.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static EpubLook _look = const EpubLook();
  static AppTheme? _theme;

  /// How the books look.
  static EpubLook get look => _look;

  /// The theme [look] names, or null for the app's: when it names none,
  /// and when it names a custom theme this device no longer holds.
  static AppTheme? get theme => _theme;

  /// Publishes [look], and [theme], the theme it names.
  static void apply(EpubLook look, {AppTheme? theme}) {
    if (_look == look && _theme == theme) return;
    _look = look;
    _theme = theme;
    revision.value++;
  }

  /// Puts back a fresh library's look: no library is open.
  static void reset() => apply(const EpubLook());
}
