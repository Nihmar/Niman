// T-PP-11: the app-level unsaved registry the window's close guard reads.
import 'package:copist/src/ui/unsaved_notes.dart';
import 'package:flutter_test/flutter_test.dart';

/// A note with a settable dirty bit and a counted, controllable save.
final class _FakeNote implements UnsavedNote {
  new(this.path, {this.unsaved = false});

  @override
  final String path;

  @override
  bool unsaved;

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

  test('saveAll surfaces the first write error', () async {
    final tracker = UnsavedTracker();
    final failing = _FakeNote('/lib/a.md', unsaved: true)
      ..failWith = StateError('disk full');
    tracker.register(failing);

    await expectLater(tracker.saveAll(), throwsStateError);
    expect(failing.saveCalls, 1);
    expect(tracker.hasUnsaved, isTrue);
  });
}
