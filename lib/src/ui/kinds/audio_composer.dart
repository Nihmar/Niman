import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/audio_recording_bar.dart';
import 'package:niman/src/ui/strings.dart';

/// The bottom bar of an audio note: one rounded field to write a note,
/// with the attach button inside it, and one round button beside it.
///
/// The round button is the microphone while the field is empty and
/// becomes send as soon as there is text; while recording it is a red
/// stop and the field gives way to [AudioRecordingBar].
///
/// The microphone is the messenger's too (#737): **hold** it and the
/// recording starts under the finger, **release** and it stops and saves,
/// **slide up** past [lockDistance] and it locks — letting go then leaves
/// it running, hands-free. A tap keeps the start/stop toggle it always
/// had, and nothing is committed before the finger goes up.
class AudioComposer extends StatefulWidget {
  /// Creates the composer.
  const new({
    required this.controller,
    required this.recording,
    required this.onRecord,
    required this.onSend,
    required this.onImport,
    required this.onDiscard,
    required this.stopSwell,
    this.paused = false,
    this.saving = false,
    this.onPause,
    super.key,
  });

  /// The written-note field's text.
  final TextEditingController controller;

  /// Whether the microphone is live.
  final bool recording;

  /// Starts or stops the recording; null disables it.
  final VoidCallback? onRecord;

  /// Sends the typed note.
  final VoidCallback onSend;

  /// Picks an audio file to attach; null disables it.
  final VoidCallback? onImport;

  /// Throws the live recording away; null disables it.
  final VoidCallback? onDiscard;

  /// The one-shot swell of the stop button when recording starts.
  final Animation<double> stopSwell;

  /// Whether the live recording is paused.
  final bool paused;

  /// Whether the stopped recording is still being saved: the bar stays,
  /// and the stop button spins instead of going grey.
  final bool saving;

  /// Pauses or resumes the recording; null disables it.
  final VoidCallback? onPause;

  /// How far up a held finger slides to lock the recording (#737).
  static const double lockDistance = 40;

  /// How long a press must last to become a hold: under it the press is
  /// the tap it always was.
  static const Duration holdDelay = Duration(milliseconds: 150);

  @override
  State<AudioComposer> createState() => _AudioComposerState();
}

class _AudioComposerState extends State<AudioComposer> {
  /// Whether a press has become the hold: the recording was started by it
  /// and the finger is still down (#737).
  bool _holding = false;

  /// Whether the hold is locked: the release then leaves the recording
  /// running. Re-read on every move, so sliding back down unlocks.
  bool _locked = false;

  /// The press that becomes a hold after [AudioComposer.holdDelay].
  Timer? _press;

  /// Where the finger went down: the slide is measured from here.
  Offset? _origin;

  /// Whether the tap that follows a hold's release is the hold's own and
  /// must be dropped. Cleared by the next press, so it cannot outlive it.
  bool _suppressTap = false;

  @override
  void dispose() {
    _press?.cancel();
    super.dispose();
  }

  /// Whether the round button is the microphone now.
  bool get _mic => !widget.recording && widget.controller.text.trim().isEmpty;

  /// Wraps the round button with the hold's raw events (#737): a
  /// [Listener], not a gesture detector, so the button's own tap stays in
  /// charge of the quick press and nothing fights in the arena.
  Widget _holdable(Widget button) {
    return Listener(
      onPointerDown: (event) {
        // Every press is its own: whatever a hold left behind ends here.
        _suppressTap = false;
        if (!_mic || widget.onRecord == null || widget.saving) return;
        _origin = event.position;
        _press?.cancel();
        _press = Timer(AudioComposer.holdDelay, () {
          if (!mounted) return;
          _press = null;
          _suppressTap = true;
          setState(() => _holding = true);
          widget.onRecord?.call();
        });
      },
      onPointerMove: (event) {
        if (!_holding) return;
        final origin = _origin;
        if (origin == null) return;
        final locked =
            origin.dy - event.position.dy >= AudioComposer.lockDistance;
        if (locked != _locked) setState(() => _locked = locked);
      },
      onPointerUp: (_) => _endHold(),
      onPointerCancel: (_) => _endHold(),
      child: button,
    );
  }

  /// The finger went up (or the pointer was taken): a lock keeps the
  /// recording, anything else stops and saves it — the messenger's send
  /// (#737).
  void _endHold() {
    _press?.cancel();
    _press = null;
    _origin = null;
    if (!_holding) return;
    final locked = _locked;
    setState(() {
      _holding = false;
      _locked = false;
    });
    if (!locked) widget.onRecord?.call();
  }

  Widget _field(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      key: const ValueKey('audio-compose-field'),
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: 4, right: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            key: const Key('audio-import-button'),
            icon: const Icon(Icons.attach_file),
            color: colorScheme.onSurfaceVariant,
            tooltip: AppStrings.audioImport,
            onPressed: widget.onImport,
          ),
          Expanded(
            child: TextField(
              key: const Key('audio-message-field'),
              controller: widget.controller,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => widget.onSend(),
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: AppStrings.audioMessageHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One round button in three roles (mic, send, stop): only its icon
  /// and color change, so the control never doubles up mid-animation.
  ///
  /// The microphone carries the hold (#737): the tap stays the button's
  /// own, the raw events around it only measure and release it.
  Widget _roundButton(BuildContext context, bool typing) {
    final colorScheme = Theme.of(context).colorScheme;
    final recording = widget.recording;
    final saving = widget.saving;
    final Icon icon;
    if (saving) {
      icon = Icon(
        Icons.stop,
        key: const ValueKey('audio-icon-saving'),
        color: colorScheme.onError.withValues(alpha: 0),
      );
    } else if (recording) {
      icon = const Icon(Icons.stop, key: ValueKey('audio-icon-stop'));
    } else if (typing) {
      icon = const Icon(Icons.send, key: ValueKey('audio-icon-send'));
    } else {
      icon = const Icon(Icons.mic_outlined, key: ValueKey('audio-icon-mic'));
    }
    final button = ScaleTransition(
      scale: TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1, end: 1.12), weight: 0.4),
        TweenSequenceItem(tween: Tween(begin: 1.12, end: 1), weight: 0.6),
      ]).animate(widget.stopSwell),
      child: IconButton.filled(
        key: Key(typing ? 'audio-send-button' : 'audio-record-button'),
        style: IconButton.styleFrom(
          fixedSize: const Size(48, 48),
          backgroundColor: recording ? colorScheme.error : null,
          foregroundColor: recording ? colorScheme.onError : null,
          // Saving keeps the red: a disabled grey flash between stop and
          // the clip landing read as a stutter.
          disabledBackgroundColor: recording ? colorScheme.error : null,
          disabledForegroundColor: recording ? colorScheme.onError : null,
        ),
        tooltip: recording
            ? AppStrings.audioStop
            : typing
            ? AppStrings.audioSend
            : AppStrings.audioRecord,
        onPressed: saving
            ? null
            : typing
            ? widget.onSend
            : _micPressed,
        icon: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: icon,
            ),
            if (saving)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onError,
                ),
              ),
          ],
        ),
      ),
    );
    // Wrapped in every role (#720's lesson): the render object a press
    // went down on must not be swapped out under the finger, or the
    // release that follows never arrives.
    return _holdable(button);
  }

  /// The microphone tapped: the toggle it always had, unless this tap is
  /// the release of the hold that started the recording (#737).
  void _micPressed() {
    if (_suppressTap) {
      _suppressTap = false;
      return;
    }
    widget.onRecord?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final typing = !widget.recording && value.text.trim().isNotEmpty;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: widget.recording
                    ? AudioRecordingBar(
                        key: const ValueKey('audio-recording-bar'),
                        onDiscard: widget.onDiscard,
                        onPause: widget.onPause,
                        paused: widget.paused,
                        saving: widget.saving,
                        holding: _holding,
                        locked: _locked,
                      )
                    : _field(context),
              ),
            ),
            const SizedBox(width: 8),
            _roundButton(context, typing),
          ],
        );
      },
    );
  }
}
