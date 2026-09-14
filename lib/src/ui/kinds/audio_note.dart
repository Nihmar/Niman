import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show LinkType, defaultAttachmentsFolder;
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/library/audio_import.dart';
import 'package:niman/src/ui/kinds/audio_chat.dart';
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

/// The audio-kind body as a chat: vocals on the left, written notes on
/// the right, each vocal's description as a blockquote bubble under it.
///
/// Descriptions live in the `> ` lines after the embed, written notes as
/// plain lines; edits are byte-stable (see `audio_chat.dart`): unmodified
/// lines keep their bytes. Files live in the library's attachments
/// folder (copied in on record/import), so they travel with the folder
/// as plain files.
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

  @override
  State<AudioNoteView> createState() => _AudioNoteViewState();
}

class _AudioNoteViewState extends State<AudioNoteView>
    with SingleTickerProviderStateMixin {
  // The microphone and speaker are created lazily on first use: the
  // platform players are slow to set up and the page should open
  // instantly.
  VoiceRecorder? _recorder;
  ClipPlayer? _player;
  late final TextEditingController _input;
  StreamSubscription<void>? _finished;
  int? _playingLine;
  bool _recording = false;
  bool _busy = false;
  bool _composing = false;
  List<_ChatRow> _rows = const [];
  // Re-created after a wholesale reorder, so the list rebuilds from
  // scratch instead of replaying stale insert/remove animations.
  GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final ScrollController _scroll = ScrollController();
  // One-shot swell for the record button when the microphone goes live.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _input = TextEditingController();
    _rows = _rowsOf(widget.text);
    // Open a loaded conversation at its latest message.
    if (_rows.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  VoiceRecorder _ensureRecorder() {
    return _recorder ??= widget.recorder ?? RecordVoiceRecorder();
  }

  ClipPlayer _ensurePlayer() {
    var player = _player;
    if (player == null) {
      player = widget.player ?? AudioplayersClipPlayer();
      _player = player;
      _finished = player.onFinished.listen((_) {
        if (mounted) setState(() => _playingLine = null);
      });
    }
    return player;
  }

  /// Applies the re-parsed [next] rows to the animated list: removed rows
  /// fade out and collapse, new rows fade in and expand, edited rows
  /// update in place.
  void _syncChat(List<_ChatRow> next) {
    final list = _listKey.currentState;
    if (list == null) {
      _rows = next;
      setState(() {});
      return;
    }
    final oldKeys = _keysOf(_rows);
    final newKeys = _keysOf(next);
    for (var i = _rows.length - 1; i >= 0; i--) {
      if (!newKeys.contains(oldKeys[i])) {
        final row = _rows[i];
        list.removeItem(i, (context, animation) => _rowWidget(row, animation));
        _rows.removeAt(i);
      }
    }
    for (var j = 0; j < next.length; j++) {
      if (!oldKeys.contains(newKeys[j])) {
        final row = next[j];
        // The insert animation reaches the row through itemBuilder.
        list.insertItem(j);
        _rows.insert(j, row);
      }
    }
    if (!_sameKeySequence(_keysOf(_rows), newKeys)) {
      // The rows came back reordered (an external edit): rebuild the list
      // without animation.
      _listKey = GlobalKey();
      _rows = next;
      setState(() {});
      return;
    }
    _rows = next;
    setState(() {});
    if (next.length > oldKeys.length) _scrollToBottom();
  }

  List<String> _keysOf(List<_ChatRow> rows) =>
      rows.map((row) => row.key).toList();

  bool _sameKeySequence(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// The chat rows of [text], each tagged with a key that survives line
  /// shifts: the clip's file for vocals, the note text for written notes,
  /// disambiguated by occurrence.
  static List<_ChatRow> _rowsOf(String text) {
    final items = parseAudioChat(text);
    final rows = <_ChatRow>[];
    var clips = 0;
    var notes = 0;
    for (final item in items) {
      if (item is AudioChatMessage) {
        rows.add(_ChatRow(item, 'clip:${item.clip.target}#${clips++}'));
      } else {
        final note = item as TextChatMessage;
        rows.add(_ChatRow(item, 'note:${note.text}#${notes++}'));
      }
    }
    return rows;
  }

  /// Builds one bubble plus its enter/exit animation (see [AnimatedList]).
  Widget _rowWidget(_ChatRow row, Animation<double> animation) {
    final suffix = row.key.split('#').last;
    final Widget bubble;
    if (row.item is AudioChatMessage) {
      final item = row.item as AudioChatMessage;
      bubble = _VocalBubble(
        key: ValueKey('audio-clip-$suffix'),
        item: item,
        playing: _playingLine == item.clip.line,
        playingKey: ValueKey('audio-play-$suffix'),
        deleteKey: ValueKey('audio-delete-$suffix'),
        renameKey: widget.libraryRoot == null || _busy
            ? null
            : ValueKey('audio-rename-$suffix'),
        descriptionKey: ValueKey('audio-description-$suffix'),
        onPlay: () => _togglePlay(item.clip),
        onDelete: () => _deleteClip(item.clip),
        onRename: widget.libraryRoot == null || _busy
            ? null
            : () => _renameClip(item.clip),
        onEditDescription: () => _editDescription(item),
      );
    } else {
      final note = row.item as TextChatMessage;
      bubble = _NoteBubble(
        key: ValueKey('audio-text-$suffix'),
        item: note,
        onEdit: () => _editTextNote(note),
        onDelete: () =>
            widget.onChanged(removeTextNote(widget.text, note.start, note.end)),
      );
    }
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        alignment: Alignment.topLeft,
        child: bubble,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void didUpdateWidget(AudioNoteView old) {
    super.didUpdateWidget(old);
    if (old.text == widget.text) return;
    if (_playingLine != null) {
      final lines = widget.text.split('\n');
      if (_playingLine! < 0 || _playingLine! >= lines.length) {
        _playingLine = null;
        unawaited(_player?.stop());
      }
    }
    _syncChat(_rowsOf(widget.text));
  }

  @override
  void dispose() {
    unawaited(_finished?.cancel());
    _pulse.dispose();
    _scroll.dispose();
    _input.dispose();
    if (widget.recorder == null) _recorder?.dispose();
    if (widget.player == null) _player?.dispose();
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

  Future<void> _togglePlay(AudioClip clip) async {
    if (_recording) return;
    if (_playingLine == clip.line) {
      setState(() => _playingLine = null);
      await _ensurePlayer().stop();
      return;
    }
    try {
      await _ensurePlayer().play(_absoluteOf(clip.target));
      if (mounted) setState(() => _playingLine = clip.line);
    } on Object catch (error) {
      _fail(error);
    }
  }

  Future<void> _deleteClip(AudioClip clip) async {
    if (_playingLine == clip.line) {
      await _ensurePlayer().stop();
      _playingLine = null;
    }
    widget.onChanged(removeAudioMessage(widget.text, clip));
  }

  void _sendNote() {
    final message = _input.text.trim();
    if (message.isEmpty) return;
    widget.onChanged(appendTextNote(widget.text, message));
    _input.clear();
  }

  Future<void> _editTextNote(TextChatMessage item) async {
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => _TextPromptDialog(
        title: AppStrings.audioEditNote,
        hint: AppStrings.audioMessageHint,
        initial: item.text,
      ),
    );
    if (saved == null || !mounted) return;
    widget.onChanged(editTextNote(widget.text, item.start, item.end, saved));
  }

  Future<void> _editDescription(AudioChatMessage item) async {
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => _TextPromptDialog(
        title: AppStrings.audioEditDescription,
        hint: AppStrings.audioDescriptionHint,
        initial: item.description,
      ),
    );
    if (saved == null || !mounted) return;
    widget.onChanged(setClipDescription(widget.text, item.clip, saved));
  }

  Future<void> _renameClip(AudioClip clip) async {
    final renamed = await showDialog<String>(
      context: context,
      builder: (context) => _TextPromptDialog(
        title: AppStrings.audioRename,
        initial: clip.name,
        confirm: AppStrings.actionRename,
      ),
    );
    if (renamed == null || !mounted) return;
    final wanted = renamed.trim();
    if (wanted.isEmpty || wanted == clip.name) return;
    final root = widget.libraryRoot;
    try {
      if (root == null) return;
      setState(() => _busy = true);
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
    // A live recording owns the bar: close the text input (if open) and
    // drop the keyboard focus so the record button can expand.
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _composing = false;
    });
    if (_playingLine != null) {
      await _ensurePlayer().stop();
      _playingLine = null;
    }
    try {
      if (!await _ensureRecorder().hasPermission()) {
        if (mounted) _fail(AppStrings.audioPermissionDenied);
        return;
      }
      final path = await (widget.newRecordPath?.call() ?? _tempRecordPath());
      await _ensureRecorder().start(path: path);
      if (!mounted) return;
      setState(() {
        _recording = true;
        _startPulse();
      });
    } on Object catch (error) {
      _fail(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Swells the record button once when a recording starts.
  void _startPulse() {
    _pulse
      ..stop()
      ..value = 0
      ..forward();
  }

  Future<void> _stopRecording(String root) async {
    setState(() => _busy = true);
    try {
      final path = await _ensureRecorder().stop();
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

  /// The record/stop button of the actions row: full width, red with a
  /// one-shot swell while the microphone is live.
  Widget _recordButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final button = FilledButton.icon(
      key: const Key('audio-record-button'),
      style: _recording
          ? FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            )
          : null,
      onPressed: widget.libraryRoot == null || _busy ? null : _toggleRecord,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: _recording
            ? const Icon(Icons.stop, key: ValueKey('audio-icon-stop'))
            : const Icon(Icons.mic_outlined, key: ValueKey('audio-icon-mic')),
      ),
      label: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: _recording
            ? Text(
                AppStrings.audioRecording,
                key: const ValueKey('audio-label-recording'),
              )
            : Text(
                AppStrings.audioRecord,
                key: const ValueKey('audio-label-record'),
              ),
      ),
    );
    if (!_recording) return button;
    return ScaleTransition(
      scale: TweenSequence<double>([
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1, end: 1.02),
          weight: 0.4,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.02, end: 1),
          weight: 0.6,
        ),
      ]).animate(_pulse),
      child: button,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canRecord = widget.libraryRoot != null && !_busy;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Bubbles animate in and out as the note text changes.
                Positioned.fill(
                  child: AnimatedList(
                    key: _listKey,
                    controller: _scroll,
                    initialItemCount: _rows.length,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 20,
                    ),
                    itemBuilder: (context, index, animation) =>
                        _rowWidget(_rows[index], animation),
                  ),
                ),
                // The empty hint fades away as the first bubble arrives.
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      key: const ValueKey('audio-empty'),
                      opacity: _rows.isEmpty ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Center(
                        child: Text(
                          AppStrings.audioEmpty,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // The bar height eases while the rows morph.
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _composing
                    ? Row(
                        key: const ValueKey('audio-compose-row'),
                        children: [
                          IconButton.filled(
                            key: const Key('audio-record-button'),
                            icon: const Icon(Icons.mic_outlined),
                            tooltip: AppStrings.audioRecord,
                            onPressed: canRecord ? _toggleRecord : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              key: const Key('audio-message-field'),
                              controller: _input,
                              autofocus: true,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendNote(),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: AppStrings.audioMessageHint,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            key: const Key('audio-send-button'),
                            icon: const Icon(Icons.send_outlined),
                            tooltip: AppStrings.audioSend,
                            onPressed: _input.text.trim().isEmpty
                                ? null
                                : _sendNote,
                          ),
                          IconButton(
                            key: const Key('audio-compose-close'),
                            icon: const Icon(Icons.close),
                            tooltip: AppStrings.actionCancel,
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              setState(() => _composing = false);
                            },
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('audio-actions-row'),
                        children: [
                          Expanded(child: _recordButton()),
                          const SizedBox(width: 12),
                          // The side buttons fade out while the record
                          // button owns the bar.
                          AnimatedOpacity(
                            key: const ValueKey('audio-actions-buttons'),
                            opacity: _recording ? 0 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: IgnorePointer(
                              ignoring: _recording,
                              child: Row(
                                children: [
                                  IconButton(
                                    key: const Key('audio-compose-button'),
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: AppStrings.audioMessageHint,
                                    onPressed: () =>
                                        setState(() => _composing = true),
                                  ),
                                  IconButton(
                                    key: const Key('audio-import-button'),
                                    icon: const Icon(
                                      Icons.upload_file_outlined,
                                    ),
                                    tooltip: AppStrings.audioImport,
                                    onPressed:
                                        widget.libraryRoot == null ||
                                            _busy ||
                                            _recording
                                        ? null
                                        : _import,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A vocal on the left: player row, description bubble under it, and
/// rename/describe/delete actions.
class _VocalBubble extends StatelessWidget {
  const new({
    required this.item,
    required this.playing,
    required this.onPlay,
    required this.onDelete,
    required this.playingKey,
    required this.deleteKey,
    this.renameKey,
    this.descriptionKey,
    this.onRename,
    this.onEditDescription,
    super.key,
  });

  final AudioChatMessage item;
  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final ValueKey<String> playingKey;
  final ValueKey<String> deleteKey;
  final ValueKey<String>? renameKey;
  final ValueKey<String>? descriptionKey;
  final VoidCallback? onRename;
  final VoidCallback? onEditDescription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    playing ? Icons.graphic_eq : Icons.audio_file_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.clip.name,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    key: playingKey,
                    icon: Icon(playing ? Icons.stop : Icons.play_arrow),
                    tooltip: playing
                        ? AppStrings.audioStopPlayback
                        : AppStrings.audioPlay,
                    onPressed: onPlay,
                  ),
                ],
              ),
              // The playing hint slides open under the player row.
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: playing
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            AppStrings.audioPlaying,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
              if (item.description.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    item.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onRename != null)
                    IconButton(
                      key: renameKey,
                      icon: const Icon(
                        Icons.drive_file_rename_outline,
                        size: 20,
                      ),
                      tooltip: AppStrings.audioRename,
                      onPressed: onRename,
                    ),
                  IconButton(
                    key: descriptionKey,
                    icon: const Icon(Icons.description_outlined, size: 20),
                    tooltip: AppStrings.audioEditDescription,
                    onPressed: onEditDescription,
                  ),
                  IconButton(
                    key: deleteKey,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: AppStrings.audioDelete,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A written note on the right with edit/delete actions.
class _NoteBubble extends StatelessWidget {
  const new({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final TextChatMessage item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The note reads from the left edge of the bubble, like the
              // vocal bubbles on the left.
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  item.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: AppStrings.audioEditNote,
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: AppStrings.audioDeleteNote,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One parsed chat row with a key that survives line shifts: it names
/// the content, not the position, so bubbles keep their identity (and
/// their enter/exit animations) when the note text is edited.
final class _ChatRow {
  const new(this.item, this.key);

  /// The row content.
  final AudioChatItem item;

  /// A stable identity, e.g. `clip:assets/a.wav#0` or `note:hello#1`.
  final String key;
}

/// A one-field prompt dialog that owns its controller, so popping the
/// route never disposes a controller the exit animation still reads.
class _TextPromptDialog extends StatefulWidget {
  const new({
    required this.title,
    required this.initial,
    this.hint,
    this.confirm,
  });

  final String title;
  final String initial;
  final String? hint;
  final String? confirm;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: null,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.confirm ?? AppStrings.actionSave),
        ),
      ],
    );
  }
}
