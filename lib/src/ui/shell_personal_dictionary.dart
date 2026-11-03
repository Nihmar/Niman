import 'dart:async';

import 'package:niman/src/library/session.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/personal_dictionary.dart';
import 'package:path/path.dart' as p;

/// The open library's personal dictionary (issue #60), attached to the
/// spell state: loaded once per root, the old one disposed and swapped
/// when the library changes, detached on close.
final class ShellPersonalDictionary {
  /// The dictionary [spellCheck] reads, for as long as [mounted] says the
  /// shell is up.
  new({required this.spellCheck, required this.mounted});

  /// The editor's spelling state the words attach to.
  final EditorSpellCheck spellCheck;

  /// Whether the shell is still up: an open that finishes after it is gone
  /// disposes the words instead.
  final bool Function() mounted;

  /// Where the dictionary lives, library-relative: the path a sync names
  /// when it brought words from another device.
  static const path = '.niman/dictionary.txt';

  PersonalDictionary? _dictionary;

  /// The root an open is in flight for: the repeated settings refreshes
  /// must not open the same file again.
  String? _opening;

  /// Attaches [controller]'s dictionary to the spell state: loaded once per
  /// root; a library switch disposes the old one and loads the new root's
  /// words; a closed library detaches.
  void follow(LibrarySession controller) {
    final root = controller.root;
    final expected = root == null
        ? null
        : p.join(root, '.niman', 'dictionary.txt');
    if (_dictionary?.path == expected) return;
    if (root == null) {
      _opening = null;
      _dictionary?.dispose();
      _dictionary = null;
      spellCheck.setPersonalDictionary(null);
      return;
    }
    if (_opening == root) return;
    _opening = root;
    unawaited(_open(controller, root));
  }

  /// Words added on another device count as soon as a sync brings them:
  /// [paths] are the library-relative paths it changed.
  void synced(Set<String> paths) {
    if (paths.contains(path)) unawaited(_dictionary?.reload());
  }

  /// Lets go of the words.
  void dispose() => _dictionary?.dispose();

  /// Opens [root]'s dictionary file; on completion the words attach, the
  /// old dictionary disposes, and the spell state re-scans the open note.
  /// A library switched away before completion disposes the words instead.
  Future<void> _open(LibrarySession controller, String root) async {
    final dictionary = await PersonalDictionary.open(root);
    if (!mounted() || controller.root != root) {
      dictionary.dispose();
      return;
    }
    _opening = null;
    _dictionary?.dispose();
    _dictionary = dictionary;
    spellCheck.setPersonalDictionary(dictionary);
  }
}
