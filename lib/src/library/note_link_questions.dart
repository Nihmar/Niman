import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/note_op_seams.dart';
import 'package:niman/src/library/note_relocation.dart';

/// The rewrites of links a rename or a move left behind: asked about, or
/// under the automatic setting carried out at once, each in a turn of its
/// own after the move has returned to its caller (#848, #859, #1041).
final class NoteLinkQuestions {
  /// Creates the link questions, whose rewrites run in [serialize].
  new({required this.serialize});

  /// The op chain of the library's operations, a batch of referrers to a
  /// turn of it.
  final Serializer serialize;

  /// The question about the links a rename or a move left, still open or
  /// answered and carried out (#859); completes without error whatever
  /// became of it. What a test awaits to see the links rewritten.
  Future<void> get settled => Future.wait<void>([_linkQuestion, _linkRewrites]);
  Future<void> _linkQuestion = Future<void>.value();

  /// The automatic rewrites of links, one after the other (#1041).
  Future<void> _linkRewrites = Future<void>.value();

  /// Asks [confirm] about the link rewrite [done] left pending (#848), once
  /// the move is over and returned to its caller: the caller follows the
  /// moved note at once, whatever the user takes to answer or whatever
  /// moves the note meanwhile (#859). A dialog the user leaves open must
  /// not hold up every other op and every sync write either, so on a yes
  /// the rewrite runs in a turn of its own, and reads each note again: an
  /// edit made while the question was open is kept. [onRewritten] tells the
  /// caller the notes changed on disk. A failure here is logged, not
  /// thrown: the move is done, and nobody awaits this.
  /// Without a [confirm] to ask, the links stay as written: a note is never
  /// written unasked.
  ///
  /// Under the automatic setting there is nothing to ask: the rewrite runs
  /// at once, in the same turn of its own, a batch of referrers to a turn of
  /// the op chain (#1041), telling [onProgress] as it goes.
  void ask(
    Relocated done,
    LinkUpdateConfirm? confirm,
    void Function()? onRewritten,
    LinkRewriteProgress? onProgress,
  ) {
    final pending = done.pending;
    if (pending == null) return;
    const log = AppLogger(name: 'links');
    if (pending.automatic) {
      _linkRewrites = _linkRewrites.then((_) async {
        try {
          await pending.apply(serialize, progress: onProgress);
          onRewritten?.call();
        } on Object catch (error) {
          log.warning('could not update links to "${done.row.path}": $error');
        }
      });
      return;
    }
    if (confirm == null) {
      log.info('links to "${done.row.path}" left as written: no prompt');
      return;
    }
    _linkQuestion = () async {
      try {
        // Counted here, off the op chain (#866): a hub note's thousand
        // referrers are read without holding up any other op or sync write.
        final notes = await pending.count();
        if (notes == 0 || !await confirm(notes)) return;
        // The rewrite flushes the open notes itself, right before reading
        // each referrer (#913).
        await pending.apply(serialize, progress: onProgress);
        onRewritten?.call();
      } on Object catch (error) {
        log.warning('could not update links to "${done.row.path}": $error');
      }
    }();
  }
}
