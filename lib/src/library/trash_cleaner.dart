import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/session.dart';

const _log = AppLogger(name: 'trash');

/// Permanently deletes the trash items that have waited longer than
/// [maxAgeDays], and answers how many went (issue #79).
///
/// Only the items the manifest knows: something dropped into `.trash/`
/// by hand carries no deletion date, and a date guessed from the file
/// would be a guess about what to destroy. Nothing is asked and nothing
/// is announced — the setting is the permission, which is why it is off
/// until someone turns it on and why a [maxAgeDays] of zero returns
/// before reading anything.
///
/// An item that will not go is logged and stepped over: one locked file
/// is no reason to leave the rest of the trash standing.
Future<int> autoEmptyTrash(
  NoteOperations ops, {
  required int maxAgeDays,
  DateTime? now,
}) async {
  if (maxAgeDays <= 0) return 0;
  final cutoff = (now ?? DateTime.now()).subtract(Duration(days: maxAgeDays));
  final items = await ops.trashItems();
  var deleted = 0;
  for (final item in items) {
    if (!item.deletedAt.isBefore(cutoff)) continue;
    try {
      await ops.deleteTrashPermanently(item.name);
      deleted++;
    } on Object catch (error) {
      _log.error('auto-empty kept "${item.name}": $error');
    }
  }
  if (deleted > 0) {
    _log.info('auto-empty: $deleted item(s) past $maxAgeDays days deleted');
  }
  return deleted;
}
