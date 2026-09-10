import 'package:copist/src/spellcheck/editor_spell_check.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's one spelling state (one hunspell engine, one dictionary).
final spellCheckProvider = Provider<EditorSpellCheck>((ref) {
  final check = EditorSpellCheck();
  ref.onDispose(check.dispose);
  return check;
});
