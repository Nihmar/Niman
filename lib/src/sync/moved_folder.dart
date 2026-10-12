import 'package:niman/src/sync/sync_run_context.dart';

/// The folder a remote move of the file [from] to [to] took with it, when
/// the run's scan shows that folder emptied out: null when the move says
/// nothing about a folder (#774).
///
/// The planner pairs single files, so a folder renamed on another device
/// arrives as one move per file under it, and nothing in those moves
/// names the folder. A device-only setting that names it — a Home action
/// that makes its notes there — would then outlive the folder and make it
/// again. The folder is read off the two paths: the same file name, under
/// the same subfolders, with a different folder above them — `Work/a.md`
/// to `Projects/a.md` is `Work` to `Projects`, `A/Work/a.md` to
/// `B/Work/a.md` is `A` to `B`.
///
/// Two paths alone cannot tell a folder renamed from one note moved out of
/// it, so the scan must also show the folder left with nothing in it: no
/// file under it on the server, and no file under it here that would go
/// back up — each is one the server last agreed on, unchanged since, which
/// this run moves or trashes like the server did. A folder still holding
/// anything stays put, and so does what names it. A folder whose only
/// note moved elsewhere reads the same as its rename, and is carried as
/// one.
({String from, String to})? movedFolder(
  SyncRunContext c,
  String from,
  String to,
) {
  final source = from.split('/');
  final target = to.split('/');
  if (source.last != target.last) return null;
  var shared = 0;
  while (shared < source.length - 1 &&
      shared < target.length - 1 &&
      source[source.length - 1 - shared] ==
          target[target.length - 1 - shared]) {
    shared++;
  }
  if (shared == 0) return null;
  final folder = source.sublist(0, source.length - shared).join('/');
  final renamed = target.sublist(0, target.length - shared).join('/');
  if (folder == renamed ||
      renamed.startsWith('$folder/') ||
      folder.startsWith('$renamed/')) {
    return null;
  }
  final under = '$folder/';
  if (c.remote.keys.any((path) => path.startsWith(under))) return null;
  for (final MapEntry(key: path, value: state) in c.local.entries) {
    if (!path.startsWith(under)) continue;
    final row = c.rows[path];
    if (row == null) return null;
    final sha = state.sha256 ?? c.localSha[path];
    final unchanged =
        (state.size == row.localSize && state.mtimeMs == row.localMtimeMs) ||
        sha == row.localSha256;
    if (!unchanged) return null;
  }
  return (from: folder, to: renamed);
}
