// A → B → A while A's outgoing write is slow (#1360): the editor that opens A
// again reads the file after the held write, or around it, never the text from
// before it.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/note_framing.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/ui/note_disk.dart';
import 'package:niman/src/ui/note_save_pipeline.dart';
import 'package:niman/src/ui/note_session.dart';
import 'package:niman/src/ui/note_text_cache.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

void main() {
  const path = '/lib/a.md';
  late Map<String, String> files;
  late UnsavedTracker tracker;
  late NoteSavePipeline saves;
  late NoteSession session;

  /// Completes the reads of the file, which take the file's content when they
  /// are asked and answer when this does.
  Completer<void>? readGate;

  setUp(() {
    files = {path: 'old'};
    readGate = null;
    tracker = UnsavedTracker();
    late final NoteSession made;
    final text = NoteTextCache(() => made.surface?.buffer);
    final disk = NoteDisk(
      readNote: () => (at) async {
        // The content is the file's when the read starts, as the OS gives it.
        final content = files[at]!;
        await readGate?.future;
        return content;
      },
    );
    saves = NoteSavePipeline(
      notePath: () => path,
      ready: () => made.ready,
      text: () => text.text,
      buffer: () => made.surface?.buffer,
      references: () => null,
      framing: () => NoteFraming.plain,
      saveNote: () => null,
      writeNote: () => (at, content) async {},
      saveNoteStream: () => null,
      onSaved: (_, _) {},
      onSettled: () {},
    );
    made = NoteSession(
      disk: disk,
      saves: saves,
      text: text,
      newSurface: (buffer, caret) =>
          MarkdownSurfaceController(buffer, caret: caret),
      takeOver: tracker.takeOver,
      writesSettled: tracker.writesSettled,
      landings: tracker.landings,
      restored: tracker.takeRestored,
      alive: () => true,
    );
    session = made;
  });

  tearDown(() {
    saves.cancel();
    session.dispose();
    tracker.dispose();
  });

  test('a write that lands while the note is read is not missed', () async {
    // A's outgoing write is running, slowly.
    final write = Completer<void>();
    unawaited(
      tracker.hold(path, () => 'new', () async {
        await write.future;
        files[path] = 'new';
      }),
    );
    readGate = Completer<void>();

    final opening = session.open(path);
    await pumpEventQueue();
    // The write lands while the opening is under way.
    write.complete();
    await pumpEventQueue();
    readGate!.complete();
    await opening;

    expect(session.surface!.buffer.text, 'new');
    expect(saves.dirty, isFalse, reason: 'the disk has this text');
    expect(tracker.hasUnsaved, isFalse);
  });

  test('a write held while the note opens is its text', () async {
    final write = Completer<void>();
    unawaited(
      tracker.hold(path, () => 'new', () async {
        await write.future;
        files[path] = 'new';
      }),
    );
    // The first read is already under way when the write is let go.
    final opening = session.open(path);
    await pumpEventQueue();
    write.complete();
    await opening;

    expect(session.surface!.buffer.text, 'new');
  });

  test('a write that failed is the text of the editor, as before', () async {
    unawaited(
      tracker
          .hold(path, () => 'new', () async => throw StateError('disk full'))
          .then((_) {}, onError: (_) {}),
    );
    await pumpEventQueue();

    await session.open(path);

    expect(session.surface!.buffer.text, 'new');
    expect(saves.dirty, isTrue, reason: 'the text is still owed to the disk');
    expect(tracker.hasUnsaved, isFalse, reason: 'the editor owns it now');
  });

  test('a note with nothing held reads once', () async {
    await session.open(path);
    expect(session.surface!.buffer.text, 'old');
    expect(saves.dirty, isFalse);
  });

  group('a version restored into an edited note (#1361)', () {
    /// The note open with 'old' and the reader's edit on top of it.
    Future<void> openEdited() async {
      await session.open(path);
      session.surface!.replaceRange(3, 3, ' and mine');
      saves.edited();
      expect(saves.dirty, isTrue);
    }

    test('is what the editor shows, and the next save keeps it', () async {
      await openEdited();
      files[path] = 'restored';

      tracker.restored(path);
      await session.reload(path, checkStamp: false);

      expect(session.surface!.buffer.text, 'restored');
      expect(saves.dirty, isFalse, reason: 'the disk holds this text');
    });

    test('is one undo step, so the edits can come back', () async {
      await openEdited();
      files[path] = 'restored';
      tracker.restored(path);
      await session.reload(path, checkStamp: false);

      final surface = session.surface!;
      expect(surface.history.undo(surface.buffer), isNotNull);
      expect(surface.buffer.text, 'old and mine');
    });

    test('a reload that is not a restore still keeps the edits', () async {
      await openEdited();
      files[path] = 'changed outside';

      await session.reload(path, checkStamp: false);

      expect(session.surface!.buffer.text, 'old and mine');
      expect(saves.dirty, isTrue);
    });

    test('an announcement of no use is not kept for a later reload', () async {
      await session.open(path);
      tracker.restored(path);
      // The note was clean: the ordinary reload adopted it.
      files[path] = 'restored';
      await session.reload(path, checkStamp: false);
      expect(session.surface!.buffer.text, 'restored');

      session.surface!.replaceRange(8, 8, '!');
      saves.edited();
      files[path] = 'changed outside';
      await session.reload(path, checkStamp: false);
      expect(session.surface!.buffer.text, 'restored!');
    });
  });
}
