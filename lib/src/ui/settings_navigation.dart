import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/settings_areas.dart';

/// Which area the desktop's right column shows, and which row in it the
/// search landed on (issue #172).
///
/// Shared by the two columns: the list selects, the pane follows. The
/// [token] moves on every selection, so selecting the area already shown
/// with a new highlight still rebuilds it and flashes the row.
final class SettingsNavigation extends ChangeNotifier {
  SettingsAreaId _selected = SettingsAreaId.appearance;
  Key? _highlight;
  int _token = 0;

  /// The area on the right.
  SettingsAreaId get selected => _selected;

  /// The row to flash in it, once.
  Key? get highlight => _highlight;

  /// Moves on every [select].
  int get token => _token;

  /// Shows [area], flashing [highlight] when given.
  void select(SettingsAreaId area, {Key? highlight}) {
    if (area == _selected && highlight == null && _highlight == null) return;
    _selected = area;
    _highlight = highlight;
    _token++;
    notifyListeners();
  }
}
