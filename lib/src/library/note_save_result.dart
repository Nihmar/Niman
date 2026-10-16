import 'package:niman/src/core/files.dart';

/// What a save of a note left on the disk, answered to the editor that made
/// it (#1060).
///
/// The editor remembers what the file looked like when it last read or wrote
/// it, to tell a real change from a watcher's event. The write knows exactly
/// what it left — the bytes it wrote and the time they landed — where a stat
/// taken afterwards could be of somebody else's later write.
final class NoteSaveResult {
  /// A save that left the file as [stamp] says.
  const new({this.stamp, this.keptExternal = false});

  /// The size and time of the file as the save left it, or null when the
  /// writer does not know.
  final DiskStamp? stamp;

  /// Whether the file the save replaced was not the one the editor last saw
  /// (another program, a sync client had written it since), and that version
  /// was kept in the note's history before it was overwritten (#1055).
  final bool keptExternal;
}
