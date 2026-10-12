import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/home/home_layout.dart';

/// Rewrites this device's own Home when the item at [from] is renamed or
/// moved to [to] (#535, #713).
///
/// Unlike `.niman/home.json`, which syncs as a write of its own, the
/// device-only Home lives nowhere but this device's settings store: a move
/// that arrives from another device has to carry it here the way a local
/// move does. A failure is logged and leaves the move standing — the file
/// has already moved on disk.
Future<void> carryDeviceHome(
  LibraryConfigRepo config,
  String from,
  String to, {
  required bool isDir,
}) async {
  try {
    await config.update((c) {
      final device = c.deviceHome;
      if (device == null) return c;
      final layout = HomeLayout.fromJson(device);
      if (layout == null) return c;
      final next = layout.renamed(from, to, isDir: isDir);
      return identical(next, layout)
          ? c
          : c.copyWith(deviceHome: next.toJson());
    });
  } on Object catch (error) {
    const AppLogger(
      name: 'home',
    ).warning('could not carry the device Home past "$from" -> "$to": $error');
  }
}

/// What, outside the library's own files, names a note by its path and
/// has to follow a rename or a move (#506): the home-screen note widgets,
/// kept in the app's database rather than the library's.
typedef CarryOutside = Future<void> Function(
  String from,
  String to, {
  required bool isDir,
});

/// Hands the move of [from] to [to] to [carry] (#506), when there is one.
/// The move is already done on disk: a failure there is logged and leaves
/// it standing.
Future<void> carryOutsideLibrary(
  CarryOutside? carry,
  String from,
  String to, {
  required bool isDir,
}) async {
  if (carry == null) return;
  try {
    await carry(from, to, isDir: isDir);
  } on Object catch (error) {
    const AppLogger(
      name: 'notes',
    ).warning('could not carry "$from" -> "$to" outside the library: $error');
  }
}
