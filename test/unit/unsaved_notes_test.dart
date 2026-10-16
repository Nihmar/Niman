// T-PP-11: the app-level unsaved registry the window's close guard reads.
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

/// A note with a settable dirty bit, buffer text and a counted,
/// controllable save.
final class _FakeNote implements UnsavedNote {
  new(this.path, {this.unsaved = false});

  @override
  final String path;

  @override
  bool unsaved;

  @override
  String text = '';

  int saveCalls = 0;
  Error? failWith;

  @override
  Future<void> save() async {
    saveCalls++;
    final error = failWith;
    if (error != null) throw error;
    unsaved = false;
  }
}

/// A note that gives the front of its buffer, and counts the whole reads.
final class _HeadNote extends _FakeNote implements UnsavedNoteHead {
  new(super.path) : super(unsaved: true);

  int wholeReads = 0;

  @override
  String get text {
    wholeReads++;
    return 'abcdef';
  }

  @override
  String textHead(int maxChars) => 'abcdef'.substring(0, maxChars);
}

void main() {
  test('hasUnsaved and unsavedPaths follow the tracked notes', () {
    final tracker = UnsavedTracker();
    final clean = _FakeNote('/lib/a.md');
    final dirty = _FakeNote('/lib/b.md', unsaved: true);

    expect(tracker.hasUnsaved, isFalse);
    tracker.register(clean);
    expect(tracker.hasUnsaved, isFalse);
    tracker.register(dirty);
    expect(tracker.hasUnsaved, isTrue);
    expect(tracker.unsavedPaths, ['/lib/b.md']);

    dirty.unsaved = false;
    tracker.noteChanged();
    expect(tracker.hasUnsaved, isFalse);
    expect(tracker.unsavedPaths, isEmpty);

    tracker
      ..unregister(dirty)
      ..unregister(clean);
    expect(tracker.unsavedPaths, isEmpty);
  });

  test('a note registers once and notifies on the first time only', () {
    final tracker = UnsavedTracker();
    final note = _FakeNote('/lib/a.md', unsaved: true);
    var notifications = 0;
    tracker
      ..addListener(() => notifications++)
      ..register(note)
      ..register(note);
    expect(notifications, 1);
    expect(tracker.unsavedPaths, ['/lib/a.md']);

    tracker
      ..unregister(note)
      ..unregister(note);
    expect(notifications, 2);
    expect(tracker.hasUnsaved, isFalse);
  });

  test('saveAll writes every unsaved note and skips the clean ones', () async {
    final tracker = UnsavedTracker();
    final clean = _FakeNote('/lib/a.md');
    final dirty = _FakeNote('/lib/b.md', unsaved: true);
    tracker
      ..register(clean)
      ..register(dirty);

    await tracker.saveAll();

    expect(dirty.saveCalls, 1);
    expect(clean.saveCalls, 0);
    expect(tracker.hasUnsaved, isFalse);
  });

  test('unsavedTextOf reads a dirty note’s buffer, and only a dirty one’s', () {
    final tracker = UnsavedTracker();
    final dirty = _FakeNote('/lib/a.md', unsaved: true)..text = 'edited';
    final clean = _FakeNote('/lib/b.md')..text = 'saved';
    tracker
      ..register(dirty)
      ..register(clean);

    expect(tracker.unsavedTextOf('/lib/a.md'), 'edited');
    expect(tracker.unsavedTextOf('/lib/b.md'), isNull);
    expect(tracker.unsavedTextOf('/lib/c.md'), isNull);

    dirty.unsaved = false;
    tracker.noteChanged();

    expect(
      tracker.unsavedTextOf('/lib/a.md'),
      isNull,
      reason: 'the disk holds it now',
    );
  });

  test(
    'unsavedTextOf with maxChars asks a note for its head, not its text',
    () {
      final tracker = UnsavedTracker();
      final head = _HeadNote('/lib/a.md');
      final plain = _FakeNote('/lib/b.md', unsaved: true)..text = 'abcdef';
      tracker
        ..register(head)
        ..register(plain);

      expect(tracker.unsavedTextOf('/lib/a.md', maxChars: 3), 'abc');
      expect(head.wholeReads, 0, reason: 'the note was not joined whole');
      expect(tracker.unsavedTextOf('/lib/a.md'), 'abcdef');
      expect(
        tracker.unsavedTextOf('/lib/b.md', maxChars: 3),
        'abcdef',
        reason: 'a note with no head to give is read whole',
      );
    },
  );

  test('saveAll surfaces the first write error', () async {
    final tracker = UnsavedTracker();
    final failing = _FakeNote('/lib/a.md', unsaved: true)
      ..failWith = StateError('disk full');
    tracker.register(failing);

    await expectLater(tracker.saveAll(), throwsStateError);
    expect(failing.saveCalls, 1);
    expect(tracker.hasUnsaved, isTrue);
  });

  group('writes held for notes that left the editor (#1054)', () {
    test('a newer hold of the note replaces an older one, which never '
        'writes again', () {
      fakeAsync((async) {
        final tracker = UnsavedTracker();
        final writes = <String>[];
        var failing = true;
        Future<void> write(String text) async {
          if (failing) throw StateError('disk full');
          writes.add(text);
        }

        unawaited(
          tracker
              .hold('/lib/a.md', () => 'old', () => write('old'))
              .then((_) {}, onError: (_) {}),
        );
        async.flushMicrotasks();
        unawaited(
          tracker
              .hold('/lib/a.md', () => 'new', () => write('new'))
              .then((_) {}, onError: (_) {}),
        );
        async.flushMicrotasks();
        expect(tracker.unsavedTextOf('/lib/a.md'), 'new');
        expect(tracker.unsavedPaths, ['/lib/a.md']);

        failing = false;
        async
          ..elapse(const Duration(minutes: 1))
          ..flushMicrotasks();
        // The older text's retries are gone; the newer one's landed.
        expect(writes, ['new']);
        expect(tracker.hasUnsaved, isFalse);
      });
    });

    test('takeOver hands the held text to an editor and drops the hold', () {
      fakeAsync((async) {
        final tracker = UnsavedTracker();
        var failing = true;
        final writes = <String>[];
        unawaited(
          tracker
              .hold('/lib/a.md', () => 'held text', () async {
                if (failing) throw StateError('disk full');
                writes.add('held text');
              })
              .then((_) {}, onError: (_) {}),
        );
        async.flushMicrotasks();
        expect(tracker.takeOver('/lib/b.md'), isNull);
        expect(tracker.takeOver('/lib/a.md'), 'held text');
        expect(tracker.hasUnsaved, isFalse, reason: 'the editor owns it now');
        expect(tracker.takeOver('/lib/a.md'), isNull);

        failing = false;
        async
          ..elapse(const Duration(minutes: 1))
          ..flushMicrotasks();
        expect(writes, isEmpty, reason: 'no retry of text that moved on');
        // And the close guard has nothing of it to wait for.
        unawaited(tracker.saveAll());
        async.flushMicrotasks();
        expect(writes, isEmpty);
      });
    });
  });
}
