// The statistics remember which note their count is of, not the note
// (#1202): held strongly, the surface a view had left — its buffer, its
// undo — lived on in them while the next note loaded.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/ui/note_stats.dart';

/// Allocates until [reference]'s target is collected, or gives up: there is
/// no call that runs the collector, but filling the young space runs it.
bool _collected(WeakReference<Object> reference) {
  for (var round = 0; round < 400 && reference.target != null; round++) {
    List<List<int>>.generate(256, (_) => List<int>.filled(1024, 0));
  }
  return reference.target == null;
}

/// A surface over [text], its words counted, refreshed into [stats] and
/// then let go by the caller: only a weak reference to it comes back.
WeakReference<Object> _refreshedAndLeft(
  NoteStatsController stats,
  void Function(MarkdownSurfaceController? surface) show,
  String text,
) {
  final surface = MarkdownSurfaceController(SourceBuffer.fromText(text));
  surface.words.adopt(surface.buffer);
  show(surface);
  stats.refresh();
  show(null);
  return WeakReference<Object>(surface);
}

void main() {
  test('a surface left is not kept by the statistics', () {
    MarkdownSurfaceController? shown;
    final stats = NoteStatsController(
      surface: () => shown,
      loading: () => false,
      sourceView: () => null,
      readView: () => null,
    );
    addTearDown(stats.dispose);

    final left = _refreshedAndLeft(stats, (s) => shown = s, 'one two three');
    expect(stats.wordCount, 3);

    // Made now and held by nothing: once it is collected, the collector has
    // run, and only a holder kept the surface.
    final control = WeakReference(Object());
    if (!_collected(control)) {
      markTestSkipped('the collector did not run');
      return;
    }
    expect(left.target, isNull, reason: 'the statistics kept the surface');
  });
}
