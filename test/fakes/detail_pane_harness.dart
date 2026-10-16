// A ShellDetailPane over in-memory notes, for the widget tests of what the
// pane does with its tabs (focus, places): the library is not on disk.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/shell_detail_pane.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:path/path.dart' as p;

/// The pane's root in these tests.
const String paneRoot = '/lib';

/// Each note's text, by library-relative path.
final Map<String, String> paneNotes = {};

/// The editor keys the pane's tabs keep, by path.
final Map<String, GlobalKey> paneKeys = {};

/// The pane showing [active] among [paths], all mounted.
Widget detailPane(
  String? active, {
  required UnsavedTracker tracker,
  List<String> paths = const ['a.md', 'b.md'],
  Map<String, NoteMemento> mementos = const {},
  void Function(String, NoteMemento)? onMemento,
  FocusNode? shellFocus,
  bool focused = true,
  Map<String, String> movedFrom = const {},
  bool showPreview = false,
}) => ShellDetailPane(
  root: paneRoot,
  shellFocus: shellFocus,
  tabs: [
    for (final path in paths)
      DetailTab(
        key: paneKeys.putIfAbsent(path, GlobalKey.new),
        path: path,
        active: path == active,
        focused: focused,
        movedFrom: movedFrom[path],
        memento: mementos[path] ?? const NoteMemento(),
        showWysiwyg: false,
        showPreview: showPreview,
      ),
  ],
  onMemento: onMemento,
  readNote: (path) async => paneNotes[p.relative(path, from: paneRoot)] ?? '',
  writeNote: (_, _) async {},
  showLineNumbers: true,
  noteColumn: NoteColumn.off,
  barActions: const [],
  autofocusEditor: false,
  linkType: LinkType.wikilink,
  newItemLocation: NewItemLocation.openNoteFolder,
  attachmentsFolder: 'assets',
  indentWidth: 2,
  toolbarLayout: ToolbarLayout.defaults,
  onEditorKindChanged: null,
  linkSource: null,
  wikilinkSuggester: null,
  onOpenNote: (_, _) {},
  kindMode: true,
  onNoteKindChanged: (_) {},
  unsavedTracker: tracker,
  statusActions: const [],
  spellCheck: EditorSpellCheck(createChecker: (_) => const NoSpelling()),
);

/// The editor of the note at [path], mounted or behind.
MarkdownSourceViewState paneEditorOf(WidgetTester tester, String path) {
  final view = find.byWidgetPredicate(
    (w) => w is NoteView && w.path == p.join(paneRoot, path),
    skipOffstage: false,
  );
  return tester.state<MarkdownSourceViewState>(
    find.descendant(
      of: view,
      matching: find.byType(MarkdownSourceView, skipOffstage: false),
      skipOffstage: false,
    ),
  );
}

/// The path of the note the primary focus is in, or null.
String? focusedNotePath() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  String? path;
  context.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is NoteView) path = p.relative(widget.path, from: paneRoot);
    return path == null;
  });
  return path;
}

/// A checker with nothing to say.
final class NoSpelling implements SpellChecker {
  /// Nothing to check.
  const new();

  @override
  bool get available => false;

  @override
  bool isCorrect(String word) => true;

  @override
  List<String> suggest(String word) => const [];

  @override
  void dispose() {}
}
