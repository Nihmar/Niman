import 'package:flutter/foundation.dart';
import 'package:niman/src/ui/settings_areas.dart';

/// One settings row as the palette lists it (#229): its title, the area
/// it lives in, and where to open.
@immutable
final class PaletteSetting {
  /// A row titled [title] of [area], at [target].
  const new({required this.title, required this.area, required this.target});

  /// The row's own title, as the settings screen reads it.
  final String title;

  /// Where it lives, for the line under it.
  final String area;

  /// The area and row the settings open at.
  final SettingsTarget target;
}
