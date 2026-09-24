// The shell's settings value. `copyWith` is what a control that changes one
// setting on the spot hands back — typewriter, the editor switch, the tree's
// sort and width — and it rebuilt the value without the Markdown engine, so
// switching typewriter on in the unified WYSIWYG put the legacy one in its
// place: Quill decoding a 246 MB note on the UI thread, a frozen app
// (2026-09-23, sampled on the profile build).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/ui/shell_editor_settings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  // Every field away from its default, so a field `copyWith` forgets comes
  // back as the default and the comparison sees it.
  const settings = ShellEditorSettings(
    lineNumbers: false,
    noteColumn: NoteColumn(enabled: false, width: 612),
    typewriter: true,
    autofocusEditor: true,
    editorKind: EditorKind.wysiwyg,
    editorsEnabled: {EditorKind.wysiwyg},
    linkType: LinkType.markdown,
    missingNoteLocation: MissingNoteLocation.libraryRoot,
    attachmentsFolder: 'media',
    indentWidth: 4,
    treeSort: TreeSort.nameDesc,
    treeWidth: 321,
    tidyOnClose: false,
  );

  test('a copy that changes nothing is the same settings', () {
    expect(settings.copyWith(), settings);
    expect(settings.copyWith().hashCode, settings.hashCode);
  });

  test('a copy that changes one setting keeps every other one', () {
    for (final copy in [
      settings.copyWith(typewriter: false),
      settings.copyWith(editorKind: EditorKind.source),
      settings.copyWith(treeSort: TreeSort.nameAsc),
      settings.copyWith(treeWidth: 400),
    ]) {
      expect(copy.lineNumbers, isFalse);
      expect(copy.noteColumn, settings.noteColumn);
      expect(copy.autofocusEditor, isTrue);
      expect(copy.editorsEnabled, settings.editorsEnabled);
      expect(copy.linkType, LinkType.markdown);
      expect(copy.missingNoteLocation, MissingNoteLocation.libraryRoot);
      expect(copy.attachmentsFolder, 'media');
      expect(copy.indentWidth, 4);
      expect(copy.tidyOnClose, isFalse);
    }
  });

  test('tidyOnClose tells two settings apart', () {
    expect(settings.copyWith(tidyOnClose: true), isNot(settings));
    expect(ShellEditorSettings.defaults.tidyOnClose, isTrue);
  });

  test('the read picks up tidyOnClose from the library', () async {
    final session = FakeLibrarySession();
    expect((await ShellEditorSettings.read(session)).tidyOnClose, isTrue);
    await session.setTidyOnClose(enabled: false);
    expect((await ShellEditorSettings.read(session)).tidyOnClose, isFalse);
  });
}
