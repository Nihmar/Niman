// The shell's settings value. `copyWith` is what a control that changes one
// setting on the spot hands back — typewriter, the editor switch, the tree's
// sort and width — and it rebuilt the value without the Markdown engine, so
// switching typewriter on in the unified WYSIWYG put the legacy one in its
// place: Quill decoding a 246 MB note on the UI thread, a frozen app
// (2026-09-23, sampled on the profile build).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config.dart'
    show defaultSourceFont;
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/library/library_preferences.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/shell_editor_settings.dart';

import '../fakes/fake_library_session.dart';

/// The session the read runs against, counting how many of its settings
/// reads are outstanding at once (#362).
///
/// The settings are twenty-one reads on the mount path, and a read that
/// awaits one before asking for the next has one of them outstanding at
/// its most: what the read is held to here is that they are all asked for
/// together.
final class _CountedReads implements LibrarySession, LibraryPreferences {
  new(this._inner);

  final LibrarySession _inner;

  /// Every settings read the wrapper was asked for.
  int reads = 0;

  /// The most reads outstanding at one time.
  int peak = 0;

  int _inFlight = 0;

  Future<T> _read<T>(Future<T> read) async {
    reads++;
    _inFlight++;
    if (_inFlight > peak) peak = _inFlight;
    try {
      return await read;
    } finally {
      _inFlight--;
    }
  }

  /// The wrapper counts the library's settings reads, so it is them.
  @override
  LibraryPreferences get librarySettings => this;

  @override
  Future<bool> get lineNumbersEnabled =>
      _read(_inner.librarySettings.lineNumbersEnabled);

  @override
  Future<bool> get readableLineLength =>
      _read(_inner.librarySettings.readableLineLength);

  @override
  Future<double> get noteColumnWidth =>
      _read(_inner.librarySettings.noteColumnWidth);

  @override
  Future<bool> get typewriter => _read(_inner.librarySettings.typewriter);

  @override
  Future<bool> get editorAutofocusEnabled =>
      _read(_inner.librarySettings.editorAutofocusEnabled);

  @override
  Future<LinkType> get linkType => _read(_inner.librarySettings.linkType);

  @override
  Future<NewItemLocation> get newItemLocation =>
      _read(_inner.librarySettings.newItemLocation);

  @override
  Future<int> get indentWidth => _read(_inner.librarySettings.indentWidth);

  @override
  Future<SourceFont> get sourceFont => _read(_inner.librarySettings.sourceFont);

  @override
  Future<TreeSort> get treeSort => _read(_inner.librarySettings.treeSort);

  @override
  Future<TreeView> get treeView => _read(_inner.librarySettings.treeView);

  @override
  Future<double> get treeWidth => _read(_inner.librarySettings.treeWidth);

  @override
  Future<double> get dockWidth => _read(_inner.librarySettings.dockWidth);

  @override
  Future<String> get editorToolbar =>
      _read(_inner.librarySettings.editorToolbar);

  @override
  Future<bool> get tidyOnClose => _read(_inner.librarySettings.tidyOnClose);

  @override
  Future<bool> get cascadeChecklist =>
      _read(_inner.librarySettings.cascadeChecklist);

  @override
  Future<bool> get frontmatterPanel =>
      _read(_inner.librarySettings.frontmatterPanel);

  @override
  Future<bool> get linkPreview => _read(_inner.librarySettings.linkPreview);

  @override
  Future<Set<String>> get lintRulesOff =>
      _read(_inner.librarySettings.lintRulesOff);

  @override
  Future<EditorKind> get editorKind => _read(_inner.librarySettings.editorKind);

  @override
  Future<Set<EditorKind>> get enabledEditors =>
      _read(_inner.librarySettings.enabledEditors);

  /// The two folders ride on the ops, and the fake has none open.
  @override
  NoteOperations? get ops => _inner.ops;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

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
    newItemLocation: NewItemLocation.libraryRoot,
    attachmentsFolder: 'media',
    indentWidth: 4,
    sourceFont: SourceFont.serif,
    treeSort: TreeSort.nameDesc,
    treeView: TreeView.grid,
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
      settings.copyWith(treeView: TreeView.list),
      settings.copyWith(treeWidth: 400),
    ]) {
      expect(copy.lineNumbers, isFalse);
      expect(copy.noteColumn, settings.noteColumn);
      expect(copy.autofocusEditor, isTrue);
      expect(copy.editorsEnabled, settings.editorsEnabled);
      expect(copy.linkType, LinkType.markdown);
      expect(copy.newItemLocation, NewItemLocation.libraryRoot);
      expect(copy.attachmentsFolder, 'media');
      expect(copy.indentWidth, 4);
      expect(copy.sourceFont, SourceFont.serif);
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

  test('the read picks up the source font from the library (#259)', () async {
    final session = FakeLibrarySession();
    expect(
      (await ShellEditorSettings.read(session)).sourceFont,
      defaultSourceFont,
    );
    await session.setSourceFont(SourceFont.serif);
    expect(
      (await ShellEditorSettings.read(session)).sourceFont,
      SourceFont.serif,
    );
  });

  test(
    'the read picks up the Files pane view from the device (#727)',
    () async {
      final session = FakeLibrarySession();
      expect((await ShellEditorSettings.read(session)).treeView, TreeView.list);
      await session.setTreeView(TreeView.grid);
      expect((await ShellEditorSettings.read(session)).treeView, TreeView.grid);
    },
  );

  test('the read asks for the settings together (#362)', () async {
    final session = _CountedReads(FakeLibrarySession());

    final settings = await ShellEditorSettings.read(session);

    expect(settings, ShellEditorSettings.defaults);
    expect(
      session.reads,
      21,
      reason: 'every setting the session answers; the two folders ride on ops',
    );
    expect(
      session.peak,
      greaterThan(1),
      reason: 'the reads go out together, not one awaited after another',
    );
  });
}
