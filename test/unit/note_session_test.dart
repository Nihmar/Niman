// The open note's lifecycle as one model (#1257): each transition — opened,
// failed, re-read, adopted, closed — says what the note is and what changed.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/note_framing.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/ui/note_disk.dart';
import 'package:niman/src/ui/note_save_pipeline.dart';
import 'package:niman/src/ui/note_session.dart';
import 'package:niman/src/ui/note_text_cache.dart';

void main() {
  late Map<String, String> files;
  late Map<String, Completer<String>> slow;
  late Map<String, String> owed;
  late List<String> written;
  late NoteSavePipeline saves;
  late NoteSession session;
  late List<NoteEvent?> events;
  var alive = true;

  setUp(() {
    files = {};
    slow = {};
    owed = {};
    written = [];
    alive = true;
    late final NoteSession made;
    final text = NoteTextCache(() => made.surface?.buffer);
    final disk = NoteDisk(
      readNote: () => (path) async {
        if (slow[path] case final waiting?) return await waiting.future;
        if (files[path] case final content?) return content;
        throw const FormatException('no such note');
      },
    );
    saves = NoteSavePipeline(
      notePath: () => 'a.md',
      ready: () => made.ready,
      text: () => text.text,
      buffer: () => made.surface?.buffer,
      references: () => null,
      framing: () => NoteFraming.plain,
      saveNote: () => null,
      writeNote: () =>
          (path, content) async => written.add(content),
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
      takeOver: owed.remove,
      alive: () => alive,
    );
    session = made;
    events = [];
    session.addListener(() => events.add(session.event));
  });
  tearDown(() {
    saves.cancel();
    session.dispose();
  });

  group('open', () {
    test('a note is read, surfaced and ready, its kind known', () async {
      files['a.md'] = '---\ntype: list\n---\n- one\r\n- two';
      expect(session.loading, isTrue);
      expect(session.ready, isFalse);

      await session.open('a.md', caret: 4);

      expect(events, [NoteEvent.loading, NoteEvent.surfaced, NoteEvent.opened]);
      expect(session.loading, isFalse);
      expect(session.ready, isTrue);
      expect(session.error, isNull);
      expect(session.kind, 'list');
      expect(
        session.surface!.buffer.text,
        '---\ntype: list\n---\n- one\n- two',
      );
      expect(session.surface!.selection.extent, 4);
      expect(session.surface!.words.isCounted, isTrue);
      expect(saves.dirty, isFalse);
      expect(session.takeEdited(), isFalse);
      expect(session.event, isNull, reason: 'only while notified');
    });

    test('the caret is kept within the note', () async {
      files['a.md'] = 'abc';
      await session.open('a.md', caret: 99);
      expect(session.surface!.selection.extent, 3);
    });

    test('the note that went is no text while the next is read', () async {
      files['a.md'] = 'first';
      await session.open('a.md');
      slow['b.md'] = Completer<String>();

      final opening = session.open('b.md');
      expect(session.surface, isNull);
      expect(session.ready, isFalse);
      expect(session.kind, isNull);
      expect(session.text.text, '');

      slow['b.md']!.complete('second');
      await opening;
      expect(session.surface!.buffer.text, 'second');
    });

    test('a load the reader moved on from changes nothing', () async {
      slow['a.md'] = Completer<String>();
      files['b.md'] = 'second';
      final first = session.open('a.md');
      await session.open('b.md');
      events.clear();

      slow['a.md']!.complete('first');
      await first;
      expect(events, isEmpty);
      expect(session.surface!.buffer.text, 'second');
    });

    test('text the app still owes the file opens unsaved', () async {
      files['a.md'] = 'on disk';
      owed['a.md'] = 'owed';
      await session.open('a.md');
      expect(session.surface!.buffer.text, 'owed');
      expect(saves.dirty, isTrue);
      expect(session.takeEdited(), isTrue);
      expect(session.takeEdited(), isFalse, reason: 'taken once');
    });

    test('a view gone before the read lands is told nothing', () async {
      slow['a.md'] = Completer<String>();
      final opening = session.open('a.md');
      events.clear();
      alive = false;
      slow['a.md']!.complete('late');
      await opening;
      expect(events, isEmpty);
    });
  });

  group('failed', () {
    test('a note that cannot be read says why', () async {
      await session.open('missing.md');
      expect(events.last, NoteEvent.failed);
      expect(session.loading, isFalse);
      expect(session.ready, isFalse);
      expect(session.error, isNotNull);
      expect(session.notText, isFalse);
    });

    test('the next reload is a new try', () async {
      await session.open('a.md');
      files['a.md'] = 'there now';
      await session.reload('a.md', checkStamp: false);
      await pumpEventQueue();
      expect(session.ready, isTrue);
      expect(session.surface!.buffer.text, 'there now');
    });
  });

  group('reload', () {
    test('a clean note adopts the disk text, a new session', () async {
      files['a.md'] = 'one';
      await session.open('a.md');
      final before = saves.editSession;
      files['a.md'] = '---\ntype: kanban\n---\ntwo';
      events.clear();

      await session.reload('a.md', checkStamp: false);

      expect(events, [NoteEvent.reread]);
      expect(session.surface!.buffer.text, '---\ntype: kanban\n---\ntwo');
      expect(session.kind, 'kanban');
      expect(session.loading, isFalse);
      expect(saves.dirty, isFalse);
      expect(saves.editSession, greaterThan(before));
    });

    test('the same text read again changes nothing', () async {
      files['a.md'] = 'one';
      await session.open('a.md');
      events.clear();
      await session.reload('a.md', checkStamp: false);
      expect(events, isEmpty);
    });

    test('unsaved edits keep the user text', () async {
      files['a.md'] = 'one';
      await session.open('a.md');
      saves.edited();
      files['a.md'] = 'two';
      await session.reload('a.md', checkStamp: false);
      expect(session.surface!.buffer.text, 'one');
    });

    test('a note moved away from is not re-read under its old path', () async {
      files['a.md'] = 'one';
      await session.open('a.md');
      session.moved('b.md');
      files['a.md'] = 'two';
      await session.reload('a.md', checkStamp: false);
      expect(session.surface!.buffer.text, 'one');
    });
  });

  group('closed', () {
    test('an edit is reported once, when the note closes', () async {
      files['a.md'] = 'one';
      await session.open('a.md');
      session.markEdited();
      expect(session.takeEdited(), isTrue);
      expect(session.takeEdited(), isFalse);
    });

    test('a move keeps the editor, as a new save session', () async {
      files['a.md'] = 'one';
      await session.open('a.md');
      final before = saves.editSession;
      expect(session.holdsNote, isTrue);
      session.moved('b.md');
      expect(saves.editSession, greaterThan(before));
      expect(session.surface!.buffer.text, 'one');
    });
  });

  test('an edit of the kind says so only when the kind changed', () async {
    files['a.md'] = 'plain';
    await session.open('a.md');
    events.clear();
    session.kindEdited('---\ntype: list\n---\n');
    expect(events, [NoteEvent.kindChanged]);
    expect(session.kind, 'list');
    session.kindEdited('---\ntype: list\n---\n- one');
    expect(events.last, isNull);
  });

  test('a pane built before any load edits the text it finds', () {
    session.text.text = 'early';
    final surface = session.ensureSurface();
    expect(surface.buffer.text, 'early');
    expect(identical(session.ensureSurface(), surface), isTrue);
  });
}
