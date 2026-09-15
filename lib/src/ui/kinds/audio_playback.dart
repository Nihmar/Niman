import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/ui/kinds/audio_player.dart';

/// The playback state of an audio note: which clip is loaded, whether it
/// is paused, where it is, and how long each clip lasts.
///
/// Clips are named by their chat-row key (stable across edits that shift
/// lines) and resolved to files by the view. The player is created on
/// first use: the platform players are slow to set up and the page
/// should open instantly.
final class AudioPlayback extends ChangeNotifier {
  /// Creates the state over the player the factory makes on first use;
  /// [ownsPlayer] disposes it with this object.
  new(this._create, {required this.ownsPlayer});

  final ClipPlayer Function() _create;

  /// Whether [dispose] releases the player (false for an injected one).
  final bool ownsPlayer;

  ClipPlayer? _player;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Map<String, Duration> _lengths = {};
  String? _activeKey;
  String? _activePath;
  bool _paused = false;
  Duration _position = Duration.zero;

  /// The key of the loaded clip (playing or paused), or null.
  String? get activeKey => _activeKey;

  /// Whether the loaded clip is paused.
  bool get paused => _paused;

  /// The position of the loaded clip.
  Duration get position => _position;

  /// The known length of the file at [absolutePath], or null.
  Duration? lengthOf(String absolutePath) => _lengths[absolutePath];

  /// Whether the length of [absolutePath] is already known.
  bool knowsLength(String absolutePath) => _lengths.containsKey(absolutePath);

  /// Records clip lengths read from the files themselves.
  void learnLengths(Map<String, Duration> lengths) {
    if (lengths.isEmpty) return;
    _lengths.addAll(lengths);
    notifyListeners();
  }

  ClipPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = _create();
    _player = player;
    _subscriptions
      ..add(player.onFinished.listen((_) => _unload()))
      ..add(
        player.onPosition.listen((position) {
          if (_activeKey == null) return;
          _position = position;
          notifyListeners();
        }),
      )
      ..add(
        player.onDuration.listen((length) {
          final path = _activePath;
          if (path == null || length <= Duration.zero) return;
          _lengths[path] = length;
          notifyListeners();
        }),
      );
    return player;
  }

  /// Plays, pauses or resumes the clip [key] backed by [absolutePath]:
  /// a new clip starts from the beginning, the loaded one toggles pause.
  Future<void> toggle(String key, String absolutePath) async {
    final player = _ensurePlayer();
    if (_activeKey == key) {
      if (_paused) {
        await player.resume();
      } else {
        await player.pause();
      }
      _paused = !_paused;
      notifyListeners();
      return;
    }
    await player.play(absolutePath);
    _activeKey = key;
    _activePath = absolutePath;
    _paused = false;
    _position = Duration.zero;
    notifyListeners();
  }

  /// Moves the loaded clip to [fraction] (0..1) of its length.
  Future<void> seekTo(double fraction) async {
    final path = _activePath;
    final length = path == null ? null : _lengths[path];
    if (_activeKey == null || length == null) return;
    final target = length * fraction.clamp(0.0, 1.0);
    _position = target;
    notifyListeners();
    await _ensurePlayer().seek(target);
  }

  /// Stops and unloads the playback (no-op when nothing is loaded).
  Future<void> stop() async {
    if (_activeKey == null) return;
    _unload();
    await _player?.stop();
  }

  void _unload() {
    _activeKey = null;
    _activePath = null;
    _paused = false;
    _position = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    if (ownsPlayer) _player?.dispose();
    super.dispose();
  }
}
