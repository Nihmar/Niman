import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show LinkType, defaultAttachmentsFolder;
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/library/audio_import.dart';
import 'package:niman/src/library/wav_duration.dart';
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

  @override
  State<AudioNoteView> createState() => _AudioNoteViewState();
}

class _AudioNoteViewState extends State<AudioNoteView>
    with SingleTickerProviderStateMixin {
  // The microphone is created lazily on first use, like the player inside
  // [AudioPlayback]: the page should open instantly.
  VoiceRecorder? _recorder;
  late final AudioPlayback _playback = AudioPlayback(
    () => widget.player ?? AudioplayersClipPlayer(),
    ownsPlayer: widget.player == null,
  );
  final TextEditingController _input = TextEditingController();
  bool _recording = false;
  bool _busy = false;
  late List<AudioChatRow> _rows = AudioChatRow.rowsOf(widget.text);
  // Clip files whose length was already asked for.
  final Set<String> _probed = {};
  // One-shot swell for the stop button when the microphone goes live.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _probeLengths();
  }

  VoiceRecorder _ensureRecorder() {
    return _recorder ??= widget.recorder ?? RecordVoiceRecorder();
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
    _pulse.dispose();
    _input.dispose();
    _playback.dispose();
    if (widget.recorder == null) _recorder?.dispose();
    super.dispose();
  }

  String _absoluteOf(String target) {
    final root = widget.libraryRoot;
    if (root != null) return p.join(root, target);
    return p.join(p.dirname(widget.notePath), target);
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

  Future<String?> _prompt({
    required String title,
    required String initial,
    String? hint,
    String? confirm,
    bool singleLine = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => AudioPromptDialog(
        title: title,
        initial: initial,
        hint: hint,
        confirm: confirm,
        singleLine: singleLine,
      ),
    );
  }

  Future<void> _togglePlay(AudioChatRow row, AudioClip clip) async {
    if (_recording) return;
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
    final saved = await _prompt(
      title: AppStrings.audioEditNote,
      hint: AppStrings.audioMessageHint,
      initial: item.text,
    );
    if (saved == null || !mounted) return;
    widget.onChanged(editTextNote(widget.text, item.start, item.end, saved));
  }

  Future<void> _editTitle(AudioChatMessage item) async {
    final saved = await _prompt(
      title: AppStrings.audioEditTitle,
      hint: AppStrings.audioTitleHint,
      initial: item.title,
      singleLine: true,
    );
    if (saved == null || !mounted) return;
    widget.onChanged(setClipTitle(widget.text, item.clip, saved));
  }

  Future<void> _editDescription(AudioChatMessage item) async {
    final saved = await _prompt(
      title: AppStrings.audioEditDescription,
      hint: AppStrings.audioDescriptionHint,
      initial: item.description,
    );
    if (saved == null || !mounted) return;
    widget.onChanged(setClipDescription(widget.text, item.clip, saved));
  }

  Future<void> _renameClip(AudioClip clip) async {
    final renamed = await _prompt(
      title: AppStrings.audioRename,
      initial: clip.name,
      confirm: AppStrings.actionRename,
      singleLine: true,
    );
    if (renamed == null || !mounted) return;
    final wanted = renamed.trim();
    final root = widget.libraryRoot;
    if (wanted.isEmpty || wanted == clip.name || root == null) return;
    setState(() => _busy = true);
    try {
      final rename = widget.renameAudio ?? _renameInLibrary;
      final next = await rename(clip.target, wanted);
      if (!mounted) return;
      widget.onChanged(renameAudioClipTarget(widget.text, clip, next));
    } on Object catch (error) {
      _fail(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _renameInLibrary(String oldRelative, String wanted) {
    return renameAudioInLibrary(
      libraryRoot: widget.libraryRoot!,
      oldRelative: oldRelative,
      newFileName: wanted,
    );
  }

  /// Copies [source] into the library and appends it as a new vocal.
  Future<void> _attach(String root, String source) async {
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
  }

  Future<void> _import() async {
    final root = widget.libraryRoot;
    if (root == null || _busy || _recording) return;
    setState(() => _busy = true);
    try {
      final source = await (widget.pickAudioPath?.call() ?? _pickAudioFile());
      if (source == null || !mounted) return;
      await _attach(root, source);
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
    setState(() => _busy = true);
    await _playback.stop();
    try {
      if (!await _ensureRecorder().hasPermission()) {
        if (mounted) _fail(AppStrings.audioPermissionDenied);
        return;
      }
      final path = await (widget.newRecordPath?.call() ?? _tempRecordPath());
      await _ensureRecorder().start(path: path);
      if (!mounted) return;
      setState(() => _recording = true);
      _pulse
        ..stop()
        ..value = 0
        ..forward();
    } on Object catch (error) {
      _fail(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopRecording(String root) async {
    setState(() => _busy = true);
    try {
      final path = await _ensureRecorder().stop();
      if (!mounted) return;
      setState(() => _recording = false);
      if (path == null) return;
      await _attach(root, path);
    } on Object catch (error) {
      if (mounted) setState(() => _recording = false);
      _fail(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Throws the live recording away: nothing reaches the note.
  Future<void> _discardRecording() async {
    if (!_recording || _busy) return;
    setState(() => _busy = true);
    try {
      await _ensureRecorder().cancel();
    } on Object catch (error) {
      _fail(error);
    } finally {
      if (mounted) {
        setState(() {
          _recording = false;
          _busy = false;
        });
      }
    }
  }

  Future<String> _tempRecordPath() async {
    final dir = await Directory.systemTemp.createTemp('niman_rec_');
    return p.join(
      dir.path,
      'clip-${DateTime.now().millisecondsSinceEpoch}.wav',
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
    final canRename = widget.libraryRoot != null && !_busy;
    return ListenableBuilder(
      key: ValueKey('audio-clip-${row.suffix}'),
      listenable: _playback,
      builder: (context, _) {
        final active = _playback.activeKey == row.key;
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canRecord = widget.libraryRoot != null && !_busy;
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
              recording: _recording,
              stopSwell: _pulse,
              onRecord: canRecord ? _toggleRecord : null,
              onSend: _sendNote,
              onImport: widget.libraryRoot == null || _busy || _recording
                  ? null
                  : _import,
              onDiscard: _busy ? null : _discardRecording,
            ),
          ),
        ],
      ),
    );
  }
}
