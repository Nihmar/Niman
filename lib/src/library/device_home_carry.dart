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
