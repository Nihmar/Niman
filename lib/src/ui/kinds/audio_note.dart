import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show LinkType, defaultAttachmentsFolder;
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/library/audio_import.dart';
import 'package:niman/src/ui/kinds/audio_clip.dart';
import 'package:niman/src/ui/kinds/audio_parser.dart';
import 'package:niman/src/ui/kinds/audio_player.dart';
import 'package:niman/src/ui/kinds/audio_recorder.dart';
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
    return AudioNoteView(
      text: host.text,
      onChanged: host.applyEdit,
      libraryRoot: host.libraryRoot,
      notePath: host.notePath,
      attachmentsFolder: host.attachmentsFolder,
      linkType: host.linkType,
    );
  }
}

/// The audio-kind body: the note's clips as rows with play/stop and
/// delete, plus record and import actions.
///
/// Clips are audio embeds (Markdown or wikilink, per the library's link
/// setting); edits are byte-stable ([appendAudioClip], [removeAudioClip]):
/// unmodified lines keep their bytes. Files live in the library's
/// attachments folder (copied in on record/import), so they travel with
/// the folder as plain files.
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
    this.newRecordPath,
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
  /// imports); null disables record/import.
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

  /// Where the next recording goes (default: a temp `.wav`); tests inject
  /// a seam to avoid touching the filesystem.
  final Future<String> Function()? newRecordPath;

  @override
  State<AudioNoteView> createState() => _AudioNoteViewState();
}

class _AudioNoteViewState extends State<AudioNoteView> {
  late List<AudioClip> _clips;
  late final VoiceRecorder _recorder;
  late final ClipPlayer _player;
  late final bool _ownsRecorder;
  late final bool _ownsPlayer;
  StreamSubscription<void>? _finished;
  int? _playing;
  bool _recording = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _clips = parseAudioClips(widget.text);
    _ownsRecorder = widget.recorder == null;
    _ownsPlayer = widget.player == null;
    _recorder = widget.recorder ?? RecordVoiceRecorder();
    _player = widget.player ?? AudioplayersClipPlayer();
    _finished = _player.onFinished.listen((_) {
      if (mounted) setState(() => _playing = null);
    });
  }

  @override
  void didUpdateWidget(AudioNoteView old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _clips = parseAudioClips(widget.text);
      if (_playing != null && _playing! >= _clips.length) {
        _playing = null;
        unawaited(_player.stop());
      }
    }
  }

  @override
  void dispose() {
    unawaited(_finished?.cancel());
    if (_ownsRecorder) _recorder.dispose();
    if (_ownsPlayer) _player.dispose();
    super.dispose();
  }

  String _absoluteOf(String target) {
    final root = widget.libraryRoot;
    if (root != null) return p.join(root, target);
    return p.join(p.dirname(widget.notePath), target);
  }

  void _fail(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$error')));
  }

  Future<void> _togglePlay(int index) async {
    if (_recording) return;
    if (_playing == index) {
      setState(() => _playing = null);
      await _player.stop();
      return;
    }
    try {
      await _player.play(_absoluteOf(_clips[index].target));
      if (mounted) setState(() => _playing = index);
    } on Object catch (error) {
      _fail(error);
    }
  }

  Future<void> _delete(int index) async {
    if (_playing == index) {
      await _player.stop();
      _playing = null;
    }
    widget.onChanged(removeAudioClip(widget.text, _clips[index]));
  }

  Future<void> _import() async {
    final root = widget.libraryRoot;
    if (root == null || _busy || _recording) return;
    setState(() => _busy = true);
    try {
      final source = await (widget.pickAudioPath?.call() ?? _pickAudioFile());
      if (source == null || !mounted) return;
      final relative =
          await (widget.importAudio?.call(root, source) ??
              importAudioToLibrary(
                libraryRoot: root,
                sourcePath: source,
                attachmentsFolder: widget.attachmentsFolder,
              ));
      if (!mounted) return;
      widget.onChanged(
        appendAudioClip(widget.text, relative, linkType: widget.linkType),
      );
    } on Object catch (error) {
      _fail(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _pickAudioFile() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    final file = result.isEmpty ? null : result.first;
    return file?.path;
  }

  Future<void> _toggleRecord() async {
    final root = widget.libraryRoot;
    if (root == null || _busy) return;
    if (_recording) {
      await _stopRecording(root);
      return;
    }
    if (_playing != null) {
      await _player.stop();
      _playing = null;
    }
    setState(() => _busy = true);
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) _fail(AppStrings.audioPermissionDenied);
        return;
      }
      final path = await (widget.newRecordPath?.call() ?? _tempRecordPath());
      await _recorder.start(path: path);
      if (mounted) setState(() => _recording = true);
    } on Object catch (error) {
      _fail(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopRecording(String root) async {
    setState(() => _busy = true);
    try {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() => _recording = false);
      if (path == null) return;
      final relative =
          await (widget.importAudio?.call(root, path) ??
              importAudioToLibrary(
                libraryRoot: root,
                sourcePath: path,
                attachmentsFolder: widget.attachmentsFolder,
              ));
      if (!mounted) return;
      widget.onChanged(
        appendAudioClip(widget.text, relative, linkType: widget.linkType),
      );
    } on Object catch (error) {
      if (mounted) setState(() => _recording = false);
      _fail(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _tempRecordPath() async {
    final dir = await Directory.systemTemp.createTemp('niman_rec_');
    return p.join(
      dir.path,
      'clip-${DateTime.now().millisecondsSinceEpoch}.wav',
    );
  }

  @override
  Widget build(BuildContext context) {
    final clips = _clips;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        children: [
          Expanded(
            child: clips.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.audioEmpty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: clips.length,
                    itemBuilder: (context, index) {
                      final clip = clips[index];
                      final playing = _playing == index;
                      return ListTile(
                        key: ValueKey('audio-clip-$index'),
                        leading: Icon(
                          playing
                              ? Icons.graphic_eq
                              : Icons.audio_file_outlined,
                        ),
                        title: Text(clip.name),
                        subtitle: playing && _recording
                            ? null
                            : playing
                            ? Text(AppStrings.audioPlaying)
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: ValueKey('audio-play-$index'),
                              icon: Icon(
                                playing ? Icons.stop : Icons.play_arrow,
                              ),
                              tooltip: playing
                                  ? AppStrings.audioStopPlayback
                                  : AppStrings.audioPlay,
                              onPressed: () => _togglePlay(index),
                            ),
                            IconButton(
                              key: ValueKey('audio-delete-$index'),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: AppStrings.audioDelete,
                              onPressed: () => _delete(index),
                            ),
                          ],
                        ),
                        onTap: () => _togglePlay(index),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('audio-record-button'),
                    icon: Icon(_recording ? Icons.stop : Icons.mic_outlined),
                    label: Text(
                      _recording
                          ? AppStrings.audioStop
                          : AppStrings.audioRecord,
                    ),
                    onPressed: widget.libraryRoot == null || _busy
                        ? null
                        : _toggleRecord,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  key: const Key('audio-import-button'),
                  icon: const Icon(Icons.upload_file_outlined),
                  tooltip: AppStrings.audioImport,
                  onPressed: widget.libraryRoot == null || _busy || _recording
                      ? null
                      : _import,
                ),
              ],
            ),
          ),
          if (_recording)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                AppStrings.audioRecording,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
