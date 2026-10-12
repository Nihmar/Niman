import 'dart:async';

import 'package:flutter/gestures.dart';
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

  /// Starts or stops the recording, completing with whether the
  /// microphone is live once it is done; null disables it.
  final Future<bool> Function()? onRecord;

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
  /// running. Re-read on every move while the finger is down, so sliding
  /// back down unlocks; kept after the release, so a locked recording
  /// still says so until it ends (#766).
  bool _locked = false;

  /// The press that becomes a hold after [AudioComposer.holdDelay].
  Timer? _press;

  /// The pointer the press or hold belongs to: another finger on the
  /// button neither starts a second one nor ends this one (#766).
  int? _pointer;

  /// Where the finger went down: the slide is measured from here.
  Offset? _origin;

  /// Whether the tap that follows a hold's release is the hold's own and
  /// must be dropped. Cleared by the next press, so it cannot outlive it.
  bool _suppressTap = false;

  /// The start the hold sent, completing with whether the microphone went
  /// live: the release acts on what the start did, not on what the
  /// composer showed at that moment (#766).
  Future<bool>? _start;

  /// Whether [_start] had completed.
  bool _startLanded = false;

  /// The toggle and the discard as they were when the hold started: while
  /// the start runs the view disables both, and the release still has to
  /// reach them once it is done.
  Future<bool> Function()? _toggle;
  VoidCallback? _discard;

  @override
  void didUpdateWidget(AudioComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The lock belongs to the recording it kept going.
    if (oldWidget.recording && !widget.recording) _locked = false;
  }

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
        // A second finger joins nothing: the first one's press goes on.
        if (_pointer != null) return;
        // Every press is its own: whatever a hold left behind ends here.
        _suppressTap = false;
        if (!_mic || widget.onRecord == null || widget.saving) return;
        // The primary button only, as for the tap: a right-button hold
        // does not record (#766).
        if (event.buttons & kPrimaryButton == 0) return;
        if (_locked) setState(() => _locked = false);
        _pointer = event.pointer;
        _origin = event.position;
        _press?.cancel();
        _press = Timer(AudioComposer.holdDelay, _beginHold);
      },
      onPointerMove: (event) {
        if (!_holding || event.pointer != _pointer) return;
        final origin = _origin;
        if (origin == null) return;
        final locked =
            origin.dy - event.position.dy >= AudioComposer.lockDistance;
        if (locked != _locked) setState(() => _locked = locked);
      },
      onPointerUp: (event) => _endHold(event.pointer),
      onPointerCancel: (event) => _endHold(event.pointer),
      child: button,
    );
  }

  /// The press lasted [AudioComposer.holdDelay]: the hold starts the
  /// recording.
  void _beginHold() {
    _press = null;
    final toggle = widget.onRecord;
    if (!mounted || toggle == null) return;
    _suppressTap = true;
    setState(() => _holding = true);
    _toggle = toggle;
    _discard = widget.onDiscard;
    _startLanded = false;
    final start = _start = toggle();
    unawaited(
      start.whenComplete(() {
        if (identical(_start, start)) _startLanded = true;
      }),
    );
  }

  /// The finger went up (or the pointer was taken): a lock keeps the
  /// recording, anything else stops and saves it — the messenger's send
  /// (#737).
  ///
  /// The release acts on the start once it is done (#766). A start still
  /// running when the finger left — a recorder slow to set up on first
  /// use, the permission dialog that took the pointer — is thrown away as
  /// soon as it lands: nothing was said while the finger was down. A
  /// start that never went live (permission refused) is left alone rather
  /// than toggled into a second start.
  void _endHold(int pointer) {
    if (pointer != _pointer) return;
    _pointer = null;
    _press?.cancel();
    _press = null;
    _origin = null;
    if (!_holding) return;
    setState(() => _holding = false);
    final start = _start;
    final toggle = _toggle;
    final landed = _startLanded;
    final discard = _discard;
    _start = null;
    _toggle = null;
    _discard = null;
    if (_locked || start == null || toggle == null) return;
    unawaited(_release(start, landed ? toggle : null, discard));
  }

  /// Ends the hold's recording once [start] is done: stopped and saved by
  /// [toggle] when given (the start had landed before the release),
  /// otherwise thrown away by [discard].
  Future<void> _release(
    Future<bool> start,
    Future<bool> Function()? toggle,
    VoidCallback? discard,
  ) async {
    final live = await start;
    if (!live || !mounted) return;
    if (toggle != null) {
      await toggle();
    } else {
      discard?.call();
    }
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
        // The microphone (and the stop) is disabled whenever recording is
        // — no library, another operation running — and looks and
        // announces it (#766).
        onPressed: saving
            ? null
            : typing
            ? widget.onSend
            : widget.onRecord == null
            ? null
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
    //
    // A touch held on the microphone is the recording, not a request for
    // the tooltip: its long press fired mid-hold, with a vibration, right
    // where the thumb slides to lock (#766). A mouse still gets it on
    // hover, and the label is still announced.
    final tooltips = TooltipTheme.of(context);
    return _holdable(
      TooltipTheme(
        data: _mic
            ? tooltips.copyWith(triggerMode: TooltipTriggerMode.manual)
            : tooltips,
        child: button,
      ),
    );
  }

  /// The microphone tapped: the toggle it always had, unless this tap is
  /// the release of the hold that started the recording (#737).
  void _micPressed() {
    if (_suppressTap) {
      _suppressTap = false;
      return;
    }
    final toggle = widget.onRecord;
    if (toggle != null) unawaited(toggle());
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
