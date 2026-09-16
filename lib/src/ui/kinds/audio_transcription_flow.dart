import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/transcription/model_state.dart';
import 'package:niman/src/transcription/transcription_job.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/transcription/transcription_queue.dart';
import 'package:niman/src/transcription/transcription_settings.dart';
import 'package:niman/src/ui/kinds/audio_chat.dart';
import 'package:niman/src/ui/kinds/audio_clip.dart';
import 'package:niman/src/ui/kinds/audio_transcript_placement.dart';
import 'package:niman/src/ui/kinds/audio_transcript_placement_dialog.dart';
import 'package:niman/src/ui/kinds/audio_transcription_strip.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/transcription/model_picker_sheet.dart';

/// The Transcribe action of one open audio note.
///
/// Starts a transcription from a clip's menu (asking for a model the
/// first time), shows each clip's progress, and writes the finished text
/// into the clip's description. The work itself runs in the app-wide
/// [TranscriptionQueue], so it survives the note closing; results wait
/// there until a view of their note takes them.
///
/// The text goes into the description (the `> ` lines after the embed):
/// an empty description is filled; over an existing one the user chooses,
/// before the job is queued, to replace it or add below it
/// ([placeTranscript] has the rules). The snackbar's Undo puts the
/// previous description back.
final class AudioTranscriptionFlow {
  /// The flow of the note at [notePath].
  new({
    required this.models,
    required this.queue,
    required this.notePath,
    required this.readText,
    required this.applyText,
    required this.absoluteOf,
    required this.contextOf,
  });

  /// The installation's models.
  final TranscriptionModels models;

  /// The app's transcription queue.
  final TranscriptionQueue queue;

  /// The note's absolute path, the key of its jobs.
  final String notePath;

  /// The note text as it is now.
  final String Function() readText;

  /// Replaces the note text (the host persists it).
  final ValueChanged<String> applyText;

  /// A clip target as an absolute file path.
  final String Function(String target) absoluteOf;

  /// The view's context while it is mounted, else null.
  final BuildContext? Function() contextOf;

  bool _collecting = false;

  /// What the bubbles rebuild on.
  Listenable get listenable => Listenable.merge([models, queue]);

  /// Starts taking this note's finished jobs, including those that
  /// finished while it was closed.
  void attach() {
    queue.addListener(_scheduleCollect);
    _scheduleCollect();
  }

  /// Stops taking results; running jobs go on in the queue.
  void detach() => queue.removeListener(_scheduleCollect);

  /// The line under "Transcribe" for [clip]: model and language, the
  /// model to choose, or why the format cannot be read.
  String menuHint(AudioClip clip) {
    if (!queue.supports(absoluteOf(clip.target))) {
      return AppStrings.audioTranscribeUnsupported;
    }
    final model = models.defaultModel;
    if (model == null) return AppStrings.transcriptionPickModelTitle;
    final language = switch (models.settings.language) {
      TranscriptionSettings.followApp => AppStrings.languageName(
        AppLanguages.resolved,
      ),
      TranscriptionSettings.detect => AppStrings.transcriptionLanguageDetect,
      final id => AppStrings.languageName(AppLanguage.fromId(id)),
    };
    return '${AppStrings.transcriptionModelName(model)} · $language';
  }

  /// Whether [clip] can be transcribed on this device.
  bool supports(AudioClip clip) => queue.supports(absoluteOf(clip.target));

  /// Queues [clip] for transcription, first asking for a model when none
  /// is downloaded or coming.
  Future<void> transcribe(AudioClip clip) async {
    final audio = absoluteOf(clip.target);
    if (!queue.supports(audio)) return;
    final description =
        vocalByTarget(readText(), clip.target)?.description ?? '';
    var placement = TranscriptPlacement.replace;
    if (description.trim().isNotEmpty) {
      final context = contextOf();
      if (context == null) return;
      final chosen = await showTranscriptPlacementDialog(context, description);
      if (chosen == null) return;
      placement = chosen;
    }
    final model = await _modelToUse();
    if (model == null) return;
    final job = queue.enqueue(
      notePath: notePath,
      clipTarget: clip.target,
      audioPath: audio,
      model: model,
      language: models.settings.whisperLanguage(AppLanguages.resolved),
      placement: placement,
      originalDescription: description,
    );
    _log.info('transcribe ${clip.target}: $job');
  }

  /// The default model; a chosen one still downloading; or the one the
  /// user picks now, whose download starts here.
  Future<TranscriptionModel?> _modelToUse() async {
    final ready = models.defaultModel;
    if (ready != null) return ready;
    final chosen = transcriptionModelById(models.settings.modelId);
    if (chosen != null) {
      switch (models.stateOf(chosen)) {
        case ModelDownloading():
          return chosen;
        case ModelFailed(resumable: true):
          unawaited(models.download(chosen));
          return chosen;
        case _:
          break;
      }
    }
    // A model on disk but not the default (the default was deleted):
    // use it rather than asking.
    if (models.installed.isNotEmpty) {
      final model = models.installed.first;
      await models.setDefault(model);
      return model;
    }
    final context = contextOf();
    if (context == null) return null;
    final picked = await showModelPickerSheet(context, models);
    if (picked == null) return null;
    _log.info('transcribe: model ${picked.id} picked, downloading');
    unawaited(models.download(picked));
    return picked;
  }

  /// The progress strip of [clip], while its job is on its way.
  Widget? stripFor(AudioClip clip) {
    final job = queue.jobFor(notePath, clip.target);
    if (job == null || job.finished) return null;
    void cancel() => queue.cancel(job);
    switch (job.phase) {
      case TranscriptionPhase.waitingForModel:
        final fraction = switch (models.stateOf(job.model)) {
          ModelDownloading(:final fraction) => fraction,
          ModelFailed(:final fraction) => fraction,
          _ => null,
        };
        return AudioTranscriptionStrip(
          key: const ValueKey('audio-transcription-download'),
          icon: Icons.download,
          label: AppStrings.transcriptionWaitingForModel(
            AppStrings.transcriptionModelName(job.model),
            ((fraction ?? 0) * 100).floor(),
          ),
          progress: fraction,
          onCancel: cancel,
        );
      case TranscriptionPhase.queued:
        return AudioTranscriptionStrip(
          key: const ValueKey('audio-transcription-queued'),
          icon: Icons.schedule,
          label: AppStrings.transcriptionQueued,
          showBar: false,
          onCancel: cancel,
        );
      case TranscriptionPhase.preparing:
        return AudioTranscriptionStrip(
          key: const ValueKey('audio-transcription-preparing'),
          icon: Icons.subtitles_outlined,
          label: AppStrings.transcriptionPreparing,
          onCancel: cancel,
        );
      case TranscriptionPhase.transcribing:
        return AudioTranscriptionStrip(
          key: const ValueKey('audio-transcription-running'),
          icon: Icons.subtitles_outlined,
          label: AppStrings.transcriptionRunning((job.progress * 100).floor()),
          progress: job.progress,
          onCancel: cancel,
        );
      case TranscriptionPhase.done || TranscriptionPhase.failed:
        return null;
    }
  }

  /// Takes finished jobs after the current notification: applying one
  /// edits the note, which must not happen inside the queue's own
  /// listener call.
  void _scheduleCollect() {
    if (_collecting) return;
    _collecting = true;
    scheduleMicrotask(() {
      _collecting = false;
      if (contextOf() == null) return;
      if (!queue.jobs.any((j) => j.notePath == notePath && j.finished)) {
        return;
      }
      queue.takeFinished(notePath).forEach(_apply);
    });
  }

  void _apply(TranscriptionJob job) {
    final clock = Stopwatch()..start();
    final context = contextOf();
    final messenger = context == null
        ? null
        : ScaffoldMessenger.maybeOf(context);
    final text = job.text ?? '';
    final failed = job.phase == TranscriptionPhase.failed;
    if (failed || text.isEmpty) {
      _log.info(
        '$job: ${failed ? 'failed (${job.error})' : 'no speech'}, '
        'nothing written',
      );
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            failed
                ? AppStrings.transcriptionFailed
                : AppStrings.transcriptionNoSpeech,
          ),
        ),
      );
      return;
    }
    final edit = placeTranscript(readText(), job);
    if (edit == null) {
      _log.warning('$job: the clip is no longer in the note, text dropped');
      return;
    }
    applyText(edit.text);
    _log.info(
      '$job: ${text.length} chars written to the description '
      '(${edit.previous.trim().isEmpty ? 'was empty' : job.placement.name}'
      '${edit.keptEdits ? ', kept the edits made meanwhile' : ''}) '
      'in ${clock.elapsedMilliseconds} ms',
    );
    messenger?.showSnackBar(
      SnackBar(
        content: Text(AppStrings.transcriptionSaved),
        action: SnackBarAction(
          label: AppStrings.actionUndo,
          onPressed: () {
            final now = readText();
            final vocal = vocalByTarget(now, job.clipTarget);
            // Only while the description is still what was written.
            if (vocal == null || vocal.description != edit.written) return;
            applyText(setClipDescription(now, vocal.clip, edit.previous));
            _log.info('$job: transcription undone');
          },
        ),
      ),
    );
  }

}

const _log = AppLogger(name: 'transcription');
