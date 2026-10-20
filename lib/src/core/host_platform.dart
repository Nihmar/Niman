/// What kind of machine Niman runs on, asked of the host once.
///
/// The gates used to list operating systems — `isLinux || isWindows` where
/// they meant "a desktop" — so a Mac fell through every one of them and got
/// the phone's behaviour without a word (docs/records/apple-platforms.md).
/// A gate asks this instead, and a new platform is added here, not at every
/// call site.
library;

import 'dart:io';

/// The host's kind, as the gates ask about it.
abstract final class HostPlatform {
  /// Linux, Windows or macOS: a window among others, a keyboard and a
  /// mouse, files on a disk the user browses.
  static final bool isDesktop =
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}
