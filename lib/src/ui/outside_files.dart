/// The files open outside any library (#77), and the ways in.
///
/// They have a screen of their own, over whatever was showing — the
/// library, or the screen that opens one — with a tab each. Going back
/// closes them all and lands where the user came from; closing the last
/// tab does the same.
library;

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/editor/editor_only.dart';
import 'package:niman/src/ui/outside_file_screen.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The files open outside the library, in tab order.
final class OutsideFiles extends ChangeNotifier {
  final List<EditorOnlyDocument> _documents = [];
  int _active = 0;

  /// The open files, in tab order.
  List<EditorOnlyDocument> get documents => List.unmodifiable(_documents);

  /// Whether none is open.
  bool get isEmpty => _documents.isEmpty;

  /// The one showing, or null when none is open.
  EditorOnlyDocument? get active =>
      _documents.isEmpty ? null : _documents[_active];

  /// Opens [document] in a tab of its own and shows it; a file already
  /// open is shown instead of opened twice.
  void open(EditorOnlyDocument document) {
    final at = _indexOf(document.filePath);
    if (at >= 0) {
      _active = at;
    } else {
      _documents.add(document);
      _active = _documents.length - 1;
    }
    notifyListeners();
  }

  /// Shows the file at [path].
  void show(String path) {
    final at = _indexOf(path);
    if (at < 0 || at == _active) return;
    _active = at;
    notifyListeners();
  }

  /// Shows the next file, or the previous one for a negative [step].
  void cycle(int step) {
    if (_documents.length < 2) return;
    _active = (_active + step) % _documents.length;
    notifyListeners();
  }

  /// Closes the file at [path]; the one after it shows, or before it
  /// when it was the last.
  void close(String path) {
    final at = _indexOf(path);
    if (at < 0) return;
    _documents.removeAt(at);
    if (_active > at || _active >= _documents.length) {
      _active = (_active - 1).clamp(0, _documents.length);
    }
    notifyListeners();
  }

  /// Closes them all.
  void closeAll() {
    if (_documents.isEmpty) return;
    _documents.clear();
    _active = 0;
    notifyListeners();
  }

  int _indexOf(String path) =>
      _documents.indexWhere((d) => p.equals(d.filePath, path));
}

/// The app's one set of outside files.
final outsideFilesProvider = Provider<OutsideFiles>((ref) {
  final files = OutsideFiles();
  ref.onDispose(files.dispose);
  return files;
});

/// Asks for a Markdown file to open on its own; null when none was
/// chosen.
Future<String?> pickOutsideFile() async {
  final file = await FilePicker.pickFile(
    dialogTitle: AppStrings.openFileTitle,
    type: FileType.custom,
    allowedExtensions: editorOnlyExtensions.toList(),
  );
  return file?.path;
}

/// Opens [document] among [files]: in a tab of the outside-files screen
/// when it is already showing, or in that screen, pushed over whatever
/// [context] shows, when it is the first.
///
/// [documentFor] opens the next file the screen is asked for (the tests
/// hand in files that are not on disk).
///
/// [unifiedMarkdown] is the caller's engine setting: a file outside a library
/// belongs to no library, so there is no setting of its own to read, and the
/// shell hands down the one the user has been looking at. The welcome screen,
/// with no library open at all, leaves it at the default.
Future<void> openOutsideFile(
  BuildContext context,
  OutsideFiles files,
  EditorOnlyDocument document, {
  EditorOnlyDocument Function(String path) documentFor = EditorOnlyDocument.new,
  bool unifiedMarkdown = false,
}) async {
  final first = files.isEmpty;
  files.open(document);
  if (!first) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OutsideFileScreen(
        files: files,
        documentFor: documentFor,
        unifiedMarkdown: unifiedMarkdown,
      ),
    ),
  );
  // Back, or the last tab closed: either way nothing stays open behind
  // a screen that is gone.
  files.closeAll();
}
