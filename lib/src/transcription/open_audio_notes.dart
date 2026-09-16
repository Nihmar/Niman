import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The audio notes shown on screen right now, by absolute path.
///
/// A finished transcription goes to its note's view when there is one
/// (which applies it with an Undo); only when there is none is it written
/// straight into the file. Views register while mounted; a count, because
/// the same note can be open twice (a pushed route over the tab).
/// Listeners hear when a note stops being shown, so a result that waited
/// for its view is written as soon as the view goes.
final class OpenAudioNotes extends ChangeNotifier {
  final Map<String, int> _counts = {};

  /// Marks [notePath] as shown by one more view.
  void open(String notePath) =>
      _counts[notePath] = (_counts[notePath] ?? 0) + 1;

  /// Marks one view of [notePath] as gone.
  void close(String notePath) {
    final left = (_counts[notePath] ?? 0) - 1;
    if (left > 0) {
      _counts[notePath] = left;
      return;
    }
    _counts.remove(notePath);
    notifyListeners();
  }

  /// Whether a view of [notePath] is on screen.
  bool isOpen(String notePath) => _counts.containsKey(notePath);
}

/// The app's registry of on-screen audio notes.
final openAudioNotesProvider = Provider<OpenAudioNotes>((ref) {
  final notes = OpenAudioNotes();
  ref.onDispose(notes.dispose);
  return notes;
});
