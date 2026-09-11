import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';

/// The app's one spelling state (one hunspell engine, one dictionary).
final spellCheckProvider = Provider<EditorSpellCheck>((ref) {
  final check = EditorSpellCheck();
  ref.onDispose(check.dispose);
  return check;
});
