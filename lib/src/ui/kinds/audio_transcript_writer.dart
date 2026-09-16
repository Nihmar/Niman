import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/transcription/open_audio_notes.dart';
import 'package:niman/src/transcription/transcription_job.dart';
import 'package:niman/src/transcription/transcription_queue.dart';
import 'package:niman/src/ui/kinds/audio_transcript_placement.dart';
import 'package:path/path.dart' as p;

/// Reads a note's text by absolute path, or null when it cannot be read
/// through the open library.
typedef TranscriptNoteReader = Future<String?> Function(String notePath);

/// Saves a note's text by absolute path through the library.
typedef TranscriptNoteSaver = Future<void> Function(
  String notePath,
  String text,
);

/// Writes finished transcripts into notes nobody has on screen.
///
/// A transcription can outlive its note's view: the user leaves the note,
/// or the app goes to the background and the note is closed. Without this
/// the text would wait in memory for the note to reopen and be lost with
/// the app. Here it is written into the file through the library's save
/// path (history snapshot, index update), with the same placement rules
/// as a view uses. A note that is open again by the time the file has
/// been read gets the job back, for its view to apply with an Undo.
final class AudioTranscriptWriter {
  /// A writer taking [queue]'s finished jobs whose note is not in [open].
  new({
    required this.queue,
    required this.open,
    required this.read,
    required this.save,
  });

  /// The app's transcription queue.
  final TranscriptionQueue queue;

  /// The notes currently on screen.
  final OpenAudioNotes open;

  /// Reads a closed note.
  final TranscriptNoteReader read;

  /// Saves a closed note.
  final TranscriptNoteSaver save;

  bool _scheduled = false;
  Future<void> _writing = Future<void>.value();

  /// Starts watching the queue and the open notes.
  void start() {
    queue.addListener(_schedule);
    open.addListener(_schedule);
    _schedule();
  }

  /// Stops watching.
  void stop() {
    queue.removeListener(_schedule);
    open.removeListener(_schedule);
  }

  /// Completes once every write started so far has finished (tests).
  Future<void> get idle => _writing;

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      final closed = [
        for (final job in queue.jobs)
          if (job.finished && !open.isOpen(job.notePath)) job,
      ];
      if (closed.isEmpty) return;
      for (final job in closed) {
        queue.takeFinished(job.notePath);
      }
      _writing = _writing.then((_) async {
        for (final job in closed) {
          await _write(job);
        }
      });
    });
  }

  Future<void> _write(TranscriptionJob job) async {
    final clock = Stopwatch()..start();
    final transcript = job.text ?? '';
    final failed = job.phase == TranscriptionPhase.failed;
    if (failed || transcript.isEmpty) {
      _log.info(
        '$job: note closed, '
        '${failed ? 'failed (${job.error})' : 'no speech'}; nothing written',
      );
      return;
    }
    try {
      final text = await read(job.notePath);
      if (text == null) {
        _log.warning('$job: note not in the open library, text dropped');
        return;
      }
      if (open.isOpen(job.notePath)) {
        // Reopened meanwhile: its view applies it, with an Undo.
        queue.putBack(job);
        return;
      }
      final edit = placeTranscript(text, job);
      if (edit == null) {
        _log.warning('$job: the clip is no longer in the note, text dropped');
        return;
      }
      await save(job.notePath, edit.text);
      _log.info(
        '$job: note closed, ${transcript.length} chars written to '
        '${p.basename(job.notePath)}'
        '${edit.keptEdits ? ' below the description edited meanwhile' : ''} '
        'in ${clock.elapsedMilliseconds} ms',
      );
    } on Object catch (error) {
      _log.warning('$job: writing to the closed note failed ($error)');
    }
  }
}

const _log = AppLogger(name: 'transcription');

/// The writer for the open library; read once by the shell to start it.
final audioTranscriptWriterProvider = Provider<AudioTranscriptWriter>((ref) {
  final session = ref.watch(librarySessionProvider);
  bool inLibrary(String path) {
    final root = session.root;
    return root != null && session.ops != null && p.isWithin(root, path);
  }

  final writer = AudioTranscriptWriter(
    queue: ref.watch(transcriptionQueueProvider),
    open: ref.watch(openAudioNotesProvider),
    read: (path) async => inLibrary(path)
        ? await session.ops!.readNote(relPath(path, session.root!))
        : null,
    save: (path, text) =>
        session.ops!.saveNote(relPath(path, session.root!), text),
  )..start();
  ref.onDispose(writer.stop);
  return writer;
});
