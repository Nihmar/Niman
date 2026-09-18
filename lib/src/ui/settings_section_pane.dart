import 'package:flutter/material.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_navigation.dart';

/// The desktop's right column of Settings (issue #172): the area the
/// left column selected, shown in place rather than pushed.
///
/// The area gets a navigator of its own. What an area opens — the toolbar
/// arrangement, the trash, the transcription models — stays in this
/// column, with a way back to the area; the area itself is the
/// navigator's root, so its app bar has no back arrow, and there is
/// nothing to go back to. Selecting another area replaces the navigator
/// (its key follows the selection), so a sub-screen never outlives the
/// area it belongs to.
final class SettingsSectionPane extends StatelessWidget {
  /// Shows [navigation]'s selection among [areas].
  const new({required this.navigation, required this.areas, super.key});

  /// Which area, and which row to flash in it.
  final SettingsNavigation navigation;

  /// The areas there are, read at build: which exist can change while
  /// Settings is open (a library gains a sync engine).
  final List<SettingsArea> Function() areas;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: navigation,
      builder: (context, _) {
        final all = areas();
        final area = all.firstWhere(
          (a) => a.id == navigation.selected && a.enabled,
          orElse: () => all.first,
        );
        final highlight = navigation.highlight;
        return Navigator(
          key: ValueKey(('settings-section', area.id, navigation.token)),
          onGenerateInitialRoutes: (navigator, _) => [
            MaterialPageRoute<void>(
              builder: (context) => area.build(highlight),
            ),
          ],
        );
      },
    );
  }
}
