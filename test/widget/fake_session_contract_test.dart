import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';

/// The widget suite drives the shell through the fake's `events` stream, so
/// the fake and the real `LibraryController` must move the revision at the
/// same moments (T-M1.5-04): after successful mutations, never on reads,
/// never on no-op moves/renames, and never for trash maintenance, which
/// touches only `.trash/` — outside the index — on the real implementation.
/// This pins that contract explicitly.
void main() {
  test('the revision moves exactly on successful mutations', () async {
    final session = FakeLibrarySession();
    final seen = <int>[];
    session.events.listen(seen.add);
    Future<void> flush() => Future<void>.delayed(Duration.zero);

    await session.open('/fake/library', create: false);
    await flush();
    expect(session.revision, greaterThan(0));
    expect(seen, isNotEmpty);
    expect(seen.last, session.revision);

    // Reads never move it.
    final atOpen = session.revision;
    await session.children(0);
    await session.folders();
    await session.trashItems();
    expect(session.revision, atOpen);

    // Every successful mutation moves it once and emits the new value.
    for (var i = 0; i < 3; i++) {
      final before = session.revision;
      await session.ops!.createNote(parentPath: '', name: 'note $i');
      await flush();
      expect(session.revision, before + 1);
      expect(seen.last, session.revision);
    }

    await session.ops!.createFolder(parentPath: '', name: 'folder');
    await session.ops!.rename('note 0.md', 'renamed');
    await session.ops!.move('note 1.md', 'folder');
    await flush();
    expect(seen.last, session.revision);

    // A no-op rename and move leave it where it is...
    final quiet = session.revision;
    await session.ops!.rename('renamed.md', 'renamed');
    await session.ops!.move('renamed.md', '');
    expect(session.revision, quiet);

    // ...and a delete-into-trash plus restore each move it once.
    await session.ops!.delete('note 2.md');
    await flush();
    expect(session.revision, quiet + 1);
    await session.ops!.restoreTrash('note 2.md');
    await flush();
    expect(session.revision, quiet + 2);

    // Trash maintenance is outside the index, as in the real ops: no move.
    final beforeMaintenance = session.revision;
    await session.ops!.delete('note 2.md');
    await flush();
    await session.ops!.deleteTrashPermanently('note 2.md');
    await session.ops!.emptyTrash();
    await flush();
    expect(session.revision, beforeMaintenance + 1);

    // notify() is a manual move, on both implementations.
    final beforeNotify = session.revision;
    session.notify();
    await flush();
    expect(session.revision, beforeNotify + 1);
    expect(seen.last, session.revision);

    // close() moves it, like the real controller's phase change.
    final beforeClose = session.revision;
    await session.close();
    await flush();
    expect(session.revision, greaterThan(beforeClose));

    await session.dispose();
  });
}
