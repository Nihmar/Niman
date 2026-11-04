import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/home/home_file.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/library/note_op_seams.dart';
import 'package:niman/src/sync/sync_store.dart';

/// The library's layouts, each kept for the library or for this device
/// alone: the navigation in the library settings, the Home in its own file
/// beside them (the library's) or in the settings (the device's).
///
/// The library's choice, once made, drops the device's, so every device
/// shows the one the library now holds.
final class LibraryLayouts {
  /// Creates the layouts of the library at [root].
  new({required this.root, required this.config, required this.hint});

  /// Absolute path of the library root.
  final String root;

  /// The library settings, holding the navigation and the device's Home.
  final LibraryConfigRepo config;

  /// Where the layouts report the Home file when they write it.
  final SyncHintSink hint;

  /// The navigation the library keeps, and the one this device keeps.
  Future<({NavigationLayout? library, NavigationLayout? device})>
  get navigation async {
    final c = await config.config;
    return (library: c.navigation, device: c.deviceNavigation);
  }

  /// Keeps [layout] as the navigation, for this device alone when
  /// [onDevice].
  Future<void> setNavigation(
    NavigationLayout layout, {
    required bool onDevice,
  }) => config.update(
    (c) => onDevice
        ? c.copyWith(deviceNavigation: layout)
        : c.copyWith(navigation: layout, clearDeviceNavigation: true),
  );

  /// The Home the library keeps, and the one this device keeps.
  Future<({HomeLayout? library, HomeLayout? device})> get home async {
    final device = (await config.config).deviceHome;
    return (
      library: await HomeFile(root).read(),
      device: device == null ? null : HomeLayout.fromJson(device),
    );
  }

  /// Keeps [layout] as the Home, for this device alone when [onDevice].
  Future<void> setHome(HomeLayout layout, {required bool onDevice}) async {
    if (onDevice) {
      await config.update((c) => c.copyWith(deviceHome: layout.toJson()));
      return;
    }
    await HomeFile(root).write(layout);
    hint(HomeFile.filePath, SyncOpKind.changed);
    await clearDeviceHome();
  }

  /// Applies the edit from [from] to [to] to the Home held now, for this
  /// device alone when [onDevice]; returns the Home it kept.
  Future<HomeLayout> editHome({
    required HomeLayout from,
    required HomeLayout to,
    required bool onDevice,
  }) async {
    if (onDevice) {
      var edited = to;
      await config.update((c) {
        final current = switch (c.deviceHome) {
          final json? => HomeLayout.fromJson(json),
          null => null,
        };
        edited = (current ?? from).withEdit(from: from, to: to);
        return c.copyWith(deviceHome: edited.toJson());
      });
      return edited;
    }
    final edited = await HomeFile(root)
        .update((current) => current.withEdit(from: from, to: to));
    hint(HomeFile.filePath, SyncOpKind.changed);
    await clearDeviceHome();
    return edited;
  }

  /// Drops this device's own Home, so the library's shows.
  Future<void> clearDeviceHome() =>
      config.update((c) => c.copyWith(clearDeviceHome: true));
}
