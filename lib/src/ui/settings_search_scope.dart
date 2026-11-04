import 'package:flutter/widgets.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/strings.dart';

/// What the builders of the settings search's entries (#104) share: the
/// library the values are read from, how a row is opened, and the
/// wording every area uses.
final class SettingsSearchScope {
  /// A scope over [controller]'s library, named [libraryName].
  const new({
    required this.controller,
    required this.libraryName,
    required this.push,
    required this.flashHome,
    required this.openArea,
  });

  /// The library whose settings the values read.
  final LibrarySession controller;

  /// The library's name, for the areas that belong to it.
  final String libraryName;

  /// Pushes a screen over the settings.
  final void Function(Widget screen) push;

  /// Clears the search and flashes the home's row with the key given.
  final void Function(Key rowKey) flashHome;

  /// Opens the area given with its row of the key given highlighted.
  final void Function(SettingsAreaId area, Key rowKey) openArea;

  /// [area] as a part of the library: "Library X › [area]".
  String libraryArea(String area) =>
      '${AppStrings.settingsGroupLibrary(libraryName)} › $area';

  /// The result line of a switch that is [on].
  String onOff({required bool on}) =>
      on ? AppStrings.settingsToggleOn : AppStrings.settingsToggleOff;

  /// The value of a row that shows none.
  Future<String?> noValue() async => null;
}
