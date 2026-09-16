import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show LinkType, defaultAttachmentsFolder;
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/library/audio_import.dart';
import 'package:niman/src/library/wav_duration.dart';
import 'package:niman/src/transcription/open_audio_notes.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/transcription/transcription_queue.dart';
import 'package:niman/src/ui/kinds/audio_capture.dart';
import 'package:niman/src/ui/kinds/audio_chat.dart';
import 'package:niman/src/ui/kinds/audio_chat_list.dart';
import 'package:niman/src/ui/kinds/audio_chat_row.dart';
import 'package:niman/src/ui/kinds/audio_clip.dart';
import 'package:niman/src/ui/kinds/audio_clip_bubble.dart';
import 'package:niman/src/ui/kinds/audio_composer.dart';
import 'package:niman/src/ui/kinds/audio_parser.dart';
import 'package:niman/src/ui/kinds/audio_playback.dart';
import 'package:niman/src/ui/kinds/audio_player.dart';
import 'package:niman/src/ui/kinds/audio_prompt_dialog.dart';
import 'package:niman/src/ui/kinds/audio_recorder.dart';
import 'package:niman/src/ui/kinds/audio_text_bubble.dart';
import 'package:niman/src/ui/kinds/audio_transcription_flow.dart';
import 'package:niman/src/ui/kinds/audioplayers_clip_player.dart';
import 'package:niman/src/ui/kinds/record_audio_recorder.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The frontmatter a new audio note is created with.
String audioNoteContent() => '---\ntype: audio\n---\n';

/// The `audio` note kind (issue #56): a sequence of voice recordings.
final class AudioKindGui implements NoteKindGUI {
  @override
  String get type => 'audio';

  @override
  Widget buildBody(BuildContext context, NoteKindHost host) {
    final container = _containerOf(context);
    return AudioNoteView(
      text: host.text,
      onChanged: host.applyEdit,
      libraryRoot: host.libraryRoot,
      notePath: host.notePath,
      attachmentsFolder: host.attachmentsFolder,
      linkType: host.linkType,
      transcriptionModels: container?.read(transcriptionModelsProvider),
      transcriptionQueue: container?.read(transcriptionQueueProvider),
      openAudioNotes: container?.read(openAudioNotesProvider),
    );
  }

  /// The app's providers, or null where the note is shown without a
  /// `ProviderScope` (widget tests): the view then has no Transcribe.
  static ProviderContainer? _containerOf(BuildContext context) {
    try {
      return ProviderScope.containerOf(context, listen: false);
      // Riverpod reports a missing scope only by throwing; its scope
      // widget is private, so there is nothing to look up first.
      // ignore: avoid_catching_errors
    } on StateError {
      return null;
    }
  }
}

/// The audio-kind body as a chat: vocals on the left, written notes on
/// the right, and one composer at the bottom.
///
/// Titles and descriptions live in the `> ` lines around each embed,
/// written notes as plain lines; edits are byte-stable (see
/// `audio_chat.dart`): unmodified lines keep their bytes. Files live in
/// the library's attachments folder (copied in on record/import), so
/// they travel with the folder as plain files.
class AudioNoteView extends StatefulWidget {
  /// Creates the view; [onChanged] receives the new full note text.
  const new({
    required this.text,
    required this.onChanged,
    required this.notePath,
    this.libraryRoot,
    this.attachmentsFolder = defaultAttachmentsFolder,
    this.linkType = LinkType.wikilink,
    this.recorder,
    this.player,
    this.pickAudioPath,
    this.importAudio,
    this.renameAudio,
    this.newRecordPath,
    this.readLengths,
    this.transcriptionModels,
    this.transcriptionQueue,
    this.openAudioNotes,
    super.key,
  });

  /// The full note text.
  final String text;

  /// Called with the new full note text after an edit; the host persists
  /// it.
  final ValueChanged<String> onChanged;

  /// The note's absolute file path (resolves note-relative clip links).
  final String notePath;

  /// The library root (resolves library-relative links and receives
  /// imports); null disables record/import/rename of files.
  final String? libraryRoot;

  /// The folder (library-relative) recorded and picked files are copied
  /// into.
  final String attachmentsFolder;

  /// What new clip links look like (wikilink or Markdown).
  final LinkType linkType;

  /// The microphone (a test seam; one is created by default).
  final VoiceRecorder? recorder;

  /// The speaker (a test seam; one is created by default).
  final ClipPlayer? player;

  /// Picks an audio file (default: the platform picker).
  final Future<String?> Function()? pickAudioPath;

  /// Imports the picked/recorded file into the library (default
  /// [importAudioToLibrary]); tests inject a seam (it runs an isolate).
  final Future<String> Function(String libraryRoot, String sourcePath)?
  importAudio;

  /// Renames a recording file (default [renameAudioInLibrary]); tests
  /// inject a seam (it runs an isolate).
  final Future<String> Function(String oldRelative, String newFileName)?
  renameAudio;

  /// Where the next recording goes (default: a temp `.wav`); tests inject
  /// a seam to avoid touching the filesystem.
  final Future<String> Function()? newRecordPath;

  /// Reads clip lengths from their files (default [readWavDurations]);
  /// tests inject a seam (it runs an isolate).
  final Future<Map<String, Duration>> Function(List<String> absolutePaths)?
  readLengths;

  /// The installation's transcription models; with [transcriptionQueue],
  /// enables the clips' Transcribe action (null for both hides it).
  final TranscriptionModels? transcriptionModels;

  /// The app's transcription queue.
  final TranscriptionQueue? transcriptionQueue;

  /// The registry this view marks its note open in, so transcripts that
  /// finish meanwhile come to the view instead of the file.
  final OpenAudioNotes? openAudioNotes;

  @override
  State<AudioNoteView> createState() => _AudioNoteViewState();
}

class _AudioNoteViewState extends State<AudioNoteView>
    with SingleTickerProviderStateMixin {
  static const _log = AppLogger(name: 'audio');

  late final AudioPlayback _playback = AudioPlayback(
    () => widget.player ?? AudioplayersClipPlayer(),
    ownsPlayer: widget.player == null,
  );
  late final AudioCapture _capture = AudioCapture(
    () => widget.recorder ?? RecordVoiceRecorder(),
    ownsRecorder: widget.recorder == null,
    onError: _fail,
  );
  final TextEditingController _input = TextEditingController();
  late List<AudioChatRow> _rows = AudioChatRow.rowsOf(widget.text);
  // Clip files whose length was already asked for.
  final Set<String> _probed = {};
  // One-shot swell for the stop button when the microphone goes live.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  AudioTranscriptionFlow? _transcription;

  @override
  void initState() {
    super.initState();
    final models = widget.transcriptionModels;
    final queue = widget.transcriptionQueue;
    if (models != null && queue != null) {
      _transcription = AudioTranscriptionFlow(
        models: models,
        queue: queue,
        notePath: widget.notePath,
        readText: () => widget.text,
        applyText: widget.onChanged,
        absoluteOf: _absoluteOf,
        contextOf: () => mounted ? context : null,
        open: widget.openAudioNotes,
      )..attach();
    }
    var wasRecording = false;
    _capture.addListener(() {
      // Swell the stop button once when the microphone goes live.
      if (_capture.recording && !wasRecording) {
        _pulse
          ..stop()
          ..value = 0
          ..forward();
      }
      wasRecording = _capture.recording;
      if (mounted) setState(() {});
    });
    _probeLengths();
  }

  @override
  void didUpdateWidget(AudioNoteView old) {
    super.didUpdateWidget(old);
    if (old.text == widget.text) return;
    _rows = AudioChatRow.rowsOf(widget.text);
    final active = _playback.activeKey;
    if (active != null && !_rows.any((row) => row.key == active)) {
      unawaited(_playback.stop());
    }
    _probeLengths();
  }

  @override
  void dispose() {
    _transcription?.detach();
    _pulse.dispose();
    _input.dispose();
    _playback.dispose();
    _capture.dispose();
    super.dispose();
  }

  /// The clip at [target] (a Markdown link, always `/`-separated) as a
  /// file path in the host's own spelling: on Windows a bare join would
  /// hand the player `C:\lib\assets/a.wav`.
  String _absoluteOf(String target) {
    final root = widget.libraryRoot;
    final base = root ?? p.dirname(widget.notePath);
    return p.normalize(p.join(base, target));
  }

  /// Reads the lengths of the clips not asked for yet, off the UI isolate.
  void _probeLengths() {
    final paths = [
      for (final row in _rows)
        if (row.item case AudioChatMessage(:final clip))
          if (_probed.add(_absoluteOf(clip.target))) _absoluteOf(clip.target),
    ];
    if (paths.isEmpty) return;
    final read = widget.readLengths ?? readWavDurations;
    unawaited(
      read(paths).then(
        (lengths) {
          if (mounted) _playback.learnLengths(lengths);
        },
        // A length that cannot be read just stays unknown.
        onError: (Object _) {},
      ),
    );
  }

  void _fail(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$error')));
  }

  Future<void> _togglePlay(AudioChatRow row, AudioClip clip) async {
    if (_capture.recording) return;
    try {
      await _playback.toggle(row.key, _absoluteOf(clip.target));
    } on Object catch (error) {
      _fail(error);
    }
  }

  Future<void> _deleteClip(AudioChatRow row, AudioClip clip) async {
    if (_playback.activeKey == row.key) await _playback.stop();
    widget.onChanged(removeAudioMessage(widget.text, clip));
  }

  void _sendNote() {
    final message = _input.text.trim();
    if (message.isEmpty) return;
    widget.onChanged(appendTextNote(widget.text, message));
    _input.clear();
  }

  Future<void> _editTextNote(TextChatMessage item) async {
    final saved = await AudioPromptDialog.show(
      context,
      title: AppStrings.audioEditNote,
      hint: AppStrings.audioMessageHint,
      initial: item.text,
    );
    if (saved == null || !mounted) return;
    widget.onChanged(editTextNote(widget.text, item.start, item.end, saved));
  }

  Future<void> _editTitle(AudioChatMessage item) async {
    final saved = await AudioPromptDialog.show(
      context,
      title: AppStrings.audioEditTitle,
      hint: AppStrings.audioTitleHint,
      initial: item.title,
      singleLine: true,
    );
    if (saved == null || !mounted) return;
    widget.onChanged(setClipTitle(widget.text, item.clip, saved));
  }

  Future<void> _editDescription(AudioChatMessage item) async {
    final saved = await AudioPromptDialog.show(
      context,
      title: AppStrings.audioEditDescription,
      hint: AppStrings.audioDescriptionHint,
      initial: item.description,
    );
    if (saved == null || !mounted) return;
    widget.onChanged(setClipDescription(widget.text, item.clip, saved));
  }

  Future<void> _renameClip(AudioClip clip) async {
    final renamed = await AudioPromptDialog.show(
      context,
      title: AppStrings.audioRename,
      initial: clip.name,
      confirm: AppStrings.actionRename,
      singleLine: true,
    );
    if (renamed == null || !mounted) return;
    final wanted = renamed.trim();
    if (wanted.isEmpty || wanted == clip.name) return;
    if (widget.libraryRoot == null) return;
    await _capture.guard(() async {
      final rename = widget.renameAudio ?? _renameInLibrary;
      final next = await rename(clip.target, wanted);
      if (!mounted) return;
      widget.onChanged(renameAudioClipTarget(widget.text, clip, next));
    });
  }

  Future<String> _renameInLibrary(String oldRelative, String wanted) {
    return renameAudioInLibrary(
      libraryRoot: widget.libraryRoot!,
      oldRelative: oldRelative,
      newFileName: wanted,
    );
  }

  /// Copies [source] into the library and appends it as a new vocal.
  Future<void> _attach(String source) async {
    final root = widget.libraryRoot;
    if (root == null || !mounted) return;
    final clock = Stopwatch()..start();
    final relative =
        await (widget.importAudio?.call(root, source) ??
            importAudioToLibrary(
              libraryRoot: root,
              sourcePath: source,
              attachmentsFolder: widget.attachmentsFolder,
            ));
    _log.info(
      'clip imported: $source -> $relative '
      '(${clock.elapsedMilliseconds} ms)',
    );
    if (!mounted) return;
    final append = Stopwatch()..start();
    widget.onChanged(
      appendAudioClip(widget.text, relative, linkType: widget.linkType),
    );
    _log.debug('clip appended to the note (${append.elapsedMilliseconds} ms)');
  }

  Future<void> _import() {
    return _capture.guard(() async {
      final source = await (widget.pickAudioPath?.call() ?? _pickAudioFile());
      if (source != null) await _attach(source);
    });
  }

  Future<String?> _pickAudioFile() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    final file = result.isEmpty ? null : result.first;
    return file?.path;
  }

  Future<void> _toggleRecord() {
    return _capture.toggle(
      beforeStart: _playback.stop,
      onRecorded: _attach,
      newPath: widget.newRecordPath,
    );
  }

  Widget _buildRow(AudioChatRow row) {
    final item = row.item;
    if (item is TextChatMessage) {
      return AudioTextBubble(
        key: ValueKey('audio-text-${row.suffix}'),
        suffix: row.suffix,
        text: item.text,
        onEdit: () => _editTextNote(item),
        onDelete: () =>
            widget.onChanged(removeTextNote(widget.text, item.start, item.end)),
      );
    }
    final vocal = item as AudioChatMessage;
    final canRename = widget.libraryRoot != null && !_capture.busy;
    final transcription = _transcription;
    return ListenableBuilder(
      key: ValueKey('audio-clip-${row.suffix}'),
      listenable: transcription == null
          ? _playback
          : Listenable.merge([_playback, transcription.listenable]),
      builder: (context, _) {
        final active = _playback.activeKey == row.key;
        final clip = vocal.clip;
        return AudioClipBubble(
          suffix: row.suffix,
          title: vocal.title,
          fallbackTitle: AppStrings.audioUntitled(int.parse(row.suffix) + 1),
          description: vocal.description,
          fileName: vocal.clip.name,
          active: active,
          playing: active && !_playback.paused,
          position: _playback.position,
          length: _playback.lengthOf(_absoluteOf(vocal.clip.target)),
          onPlay: () => _togglePlay(row, vocal.clip),
          onSeek: _playback.seekTo,
          onEditTitle: () => _editTitle(vocal),
          onEditDescription: () => _editDescription(vocal),
          onRename: canRename ? () => _renameClip(vocal.clip) : null,
          onDelete: () => _deleteClip(row, vocal.clip),
          transcribeHint: transcription?.menuHint(clip),
          onTranscribe:
              transcription != null &&
                  transcription.supports(clip) &&
                  transcription.stripFor(clip) == null
              ? () => unawaited(transcription.transcribe(clip))
              : null,
          transcription: transcription?.stripFor(clip),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canRecord = widget.libraryRoot != null && !_capture.busy;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AudioChatList(rows: _rows, buildRow: _buildRow),
                ),
                // The empty hint fades away as the first bubble arrives.
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      key: const ValueKey('audio-empty'),
                      opacity: _rows.isEmpty ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mic_none,
                              size: 40,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.audioEmpty,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AudioComposer(
              controller: _input,
              recording: _capture.recording,
              paused: _capture.paused,
              saving: _capture.saving,
              onPause: _capture.busy ? null : _capture.togglePause,
              stopSwell: _pulse,
              onRecord: canRecord ? _toggleRecord : null,
              onSend: _sendNote,
              onImport:
                  widget.libraryRoot == null ||
                      _capture.busy ||
                      _capture.recording
                  ? null
                  : _import,
              onDiscard: _capture.busy ? null : _capture.discard,
            ),
          ),
        ],
      ),
    );
  }
}
