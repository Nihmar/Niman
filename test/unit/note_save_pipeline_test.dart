// The note view's save pipeline on its own (issue #710): revisions, the
// coalesced trailing save, the outgoing note's save, the close guard's loop
// and the streaming save, with the writers faked and no widget pumped.
import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/note_save_pipeline.dart';
import 'package:path/path.dart' as p;

/// One write the pipeline asked for.
typedef Write = ({String path, String text, int session});

/// A pipeline over a buffer the test edits, with writes it holds open until
/// the test lets them go.
final class Harness {
  new({this.streaming = false, this.loaded = true}) {
    pipeline = NoteSavePipeline(
      notePath: () => path,
      ready: () => loaded,
      text: () => buffer.text,
      buffer: () => buffer,
      references: () => references,
      saveNote: () => streaming ? null : _save,
      writeNote: () => null,
      saveNoteStream: () => streaming ? _saveStream : null,
      onSaved: saved.add,
      onSettled: () => settled++,
    );
  }

  final bool streaming;
  bool loaded;
  String path = p.join('lib', 'a.md');
  SourceBuffer buffer = SourceBuffer.fromText('one\n');
  NoteReferences? references;
  late final NoteSavePipeline pipeline;

  final List<Write> writes = [];
  final List<NoteReferences?> streamedReferences = [];
  final List<String> saved = [];
  int settled = 0;

  /// Writes wait on these, in order, while [hold] is set.
  final List<Completer<void>> gates = [];
  bool hold = false;
  Error? failWith;

  /// Edits the note to [text] and tells the pipeline.
  void edit(String text) {
    buffer = SourceBuffer.fromText(text);
    pipeline.edited();
  }

  /// Lets the oldest held write finish.
  Future<void> release() async {
    gates.removeAt(0).complete();
    await pumpEventQueue();
  }

  Future<void> _gate() async {
    final error = failWith;
    if (error != null) throw error;
    if (!hold) return;
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
  }

  Future<void> _save(
    String path,
    String content, {
    required int editSession,
  }) async {
    await _gate();
    writes.add((path: path, text: content, session: editSession));
  }

  Future<void> _saveStream(
    String path,
    NoteContentProducer content, {
    required int editSession,
    NoteReferences? references,
  }) async {
    // Held before the first slice: an edit while it waits must not reach it.
    await _gate();
    final bytes = <int>[];
    for (var index = 0; ; index++) {
      final slice = await content(index);
      if (slice == null) break;
      bytes.addAll(slice);
    }
    streamedReferences.add(references);
    writes.add((path: path, text: utf8.decode(bytes), session: editSession));
  }

  void dispose() => pipeline.cancel();
}

void main() {
  late Harness harness;
  tearDown(() => harness.dispose());

  test('a save writes the text under the session and marks it saved', () async {
    harness = Harness();
    final pipeline = harness.pipeline;
    final session = pipeline.newSession();
    harness.edit('two\n');
    expect(pipeline.dirty, isTrue);

    await pipeline.save();

    expect(harness.writes, [
      (path: harness.path, text: 'two\n', session: session),
    ]);
    expect(pipeline.dirty, isFalse);
    expect(pipeline.lastSavedRevision, pipeline.revision);
    expect(harness.saved, [harness.path]);
    expect(harness.settled, 1);
  });

  test('a clean note is not written', () async {
    harness = Harness();
    await harness.pipeline.save();
    expect(harness.writes, isEmpty);
    expect(harness.settled, 0);
  });

  test('nothing is written for the note on screen until it loads', () async {
    harness = Harness(loaded: false)..edit('two\n');
    await harness.pipeline.save();
    expect(harness.writes, isEmpty);
    // A save with its own path — the outgoing note's — still writes.
    await harness.pipeline.save(path: p.join('lib', 'old.md'));
    expect(harness.writes.single.path, p.join('lib', 'old.md'));
    // Another note's path is not the one on screen: still owed.
    expect(harness.pipeline.dirty, isTrue);
    expect(harness.saved, isEmpty);
  });

  test(
    'a save asked for during one coalesces into one trailing save',
    () async {
      harness = Harness()..hold = true;
      final pipeline = harness.pipeline;
      harness.edit('two\n');
      final first = pipeline.save();
      await pumpEventQueue();
      expect(pipeline.saving, isTrue);

      harness.edit('three\n');
      final second = pipeline.save();
      harness.edit('four\n');
      final third = pipeline.save();
      expect(pipeline.busy, isTrue);

      await harness.release();
      await Future.wait([first, second, third]);
      // The trailing save is under way, with the text as it is now.
      expect(harness.gates, hasLength(1));
      await harness.release();

      expect(harness.writes.map((w) => w.text), ['two\n', 'four\n']);
      expect(pipeline.dirty, isFalse);
      expect(pipeline.busy, isFalse);
    },
  );

  test(
    'the outgoing note is saved as it stands, after the save in flight',
    () async {
      harness = Harness()..hold = true;
      final pipeline = harness.pipeline;
      final outgoing = harness.path;
      harness.edit('two\n');
      unawaited(pipeline.save());
      await pumpEventQueue();
      harness.edit('three\n');

      final saved = pipeline.saveOutgoing(outgoing);
      // The incoming note replaces the buffer before either write ends.
      harness
        ..path = p.join('lib', 'b.md')
        ..buffer = SourceBuffer.fromText('incoming\n');
      pipeline.markClean();

      await harness.release();
      await harness.release();
      await saved;

      expect(harness.writes, [
        (path: outgoing, text: 'two\n', session: 0),
        (path: outgoing, text: 'three\n', session: 0),
      ]);
    },
  );

  test('a clean outgoing note waits for the save in flight', () async {
    harness = Harness()..hold = true;
    final pipeline = harness.pipeline;
    harness.edit('two\n');
    unawaited(pipeline.save());
    await pumpEventQueue();
    // The save in flight is for the latest revision once it lands.
    var done = false;
    harness.edit('two\n');
    pipeline.markClean();
    unawaited(pipeline.saveOutgoing(harness.path).then((_) => done = true));
    await pumpEventQueue();
    expect(done, isFalse);
    await harness.release();
    expect(done, isTrue);
  });

  test('closing writes what is owed, and waits for it', () async {
    harness = Harness()..edit('two\n');
    await harness.pipeline.close();
    expect(harness.writes.single.text, 'two\n');
    expect(harness.pipeline.dirty, isFalse);
  });

  test(
    'the close guard saves until the disk holds the last revision',
    () async {
      harness = Harness()..hold = true;
      final pipeline = harness.pipeline;
      harness.edit('two\n');
      unawaited(pipeline.save());
      await pumpEventQueue();
      harness.edit('three\n');

      final closing = pipeline.saveForClose();
      await harness.release();
      await harness.release();
      await closing;

      expect(harness.writes.last.text, 'three\n');
      expect(pipeline.dirty, isFalse);
    },
  );

  test('a failed write reaches the caller and leaves the note owed', () async {
    harness = Harness()..failWith = StateError('disk full');
    final pipeline = harness.pipeline;
    harness.edit('two\n');
    await expectLater(pipeline.saveForClose(), throwsStateError);
    expect(pipeline.dirty, isTrue);
    expect(pipeline.saving, isFalse);
    expect(harness.settled, 1);
  });

  test('a long note is streamed in slices that make the same text', () async {
    harness = Harness(streaming: true);
    final pipeline = harness.pipeline;
    const lines = NoteSavePipeline.kSaveSliceLines * 2 + 5;
    final text = [for (var i = 0; i < lines; i++) 'line $i'].join('\n');
    const references = NoteReferences(tags: ['tag'], links: []);
    harness
      ..references = references
      ..edit(text);

    await pipeline.save();

    expect(harness.writes.single.text, text);
    expect(harness.streamedReferences.single, same(references));
    expect(pipeline.dirty, isFalse);
  });

  test(
    'an edit during a streamed save is not in the save it started',
    () async {
      harness = Harness(streaming: true)..hold = true;
      final pipeline = harness.pipeline;
      harness.edit('two\n');
      final first = pipeline.save();
      await pumpEventQueue();
      // The buffer object itself changes under the save.
      harness.buffer.replaceRange(0, 3, 'TWO');
      pipeline.edited();
      unawaited(pipeline.save());
      await harness.release();
      await first;
      await harness.release();
      expect(harness.writes.map((w) => w.text), ['two\n', 'TWO\n']);
    },
  );

  test('an edit schedules its own save', () {
    fakeAsync((async) {
      harness = Harness()..edit('two\n');
      async.elapse(const Duration(milliseconds: 499));
      expect(harness.writes, isEmpty);
      async
        ..elapse(const Duration(milliseconds: 1))
        ..flushMicrotasks();
      expect(harness.writes.single.text, 'two\n');
    });
  });
}
