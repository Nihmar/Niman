// The shell's settings value. `copyWith` is what a control that changes one
// setting on the spot hands back — typewriter, the editor switch, the tree's
// sort and width — and it rebuilt the value without the Markdown engine, so
// switching typewriter on in the unified WYSIWYG put the legacy one in its
// place: Quill decoding a 246 MB note on the UI thread, a frozen app
// (2026-09-23, sampled on the profile build).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/ui/shell_editor_settings.dart';

import '../fakes/fake_library_session.dart';

/// The session the read runs against, counting how many of its settings
/// reads are outstanding at once (#362).
///
/// The settings are nineteen reads on the mount path, and a read that
/// awaits one before asking for the next has one of them outstanding at
/// its most: what the read is held to here is that they are all asked for
/// together.
final class _CountedReads implements LibrarySession {
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

  @override
  Future<bool> get lineNumbersEnabled => _read(_inner.lineNumbersEnabled);

  @override
  Future<bool> get readableLineLength => _read(_inner.readableLineLength);

  @override
  Future<double> get noteColumnWidth => _read(_inner.noteColumnWidth);

  @override
  Future<bool> get typewriter => _read(_inner.typewriter);

  @override
  Future<bool> get editorAutofocusEnabled =>
      _read(_inner.editorAutofocusEnabled);

  @override
  Future<LinkType> get linkType => _read(_inner.linkType);

  @override
  Future<MissingNoteLocation> get missingNoteLocation =>
      _read(_inner.missingNoteLocation);

  @override
  Future<int> get indentWidth => _read(_inner.indentWidth);

  @override
  Future<TreeSort> get treeSort => _read(_inner.treeSort);

  @override
  Future<double> get treeWidth => _read(_inner.treeWidth);

  @override
  Future<double> get dockWidth => _read(_inner.dockWidth);

  @override
  Future<String> get editorToolbar => _read(_inner.editorToolbar);

  @override
  Future<bool> get tidyOnClose => _read(_inner.tidyOnClose);

  @override
  Future<bool> get cascadeChecklist => _read(_inner.cascadeChecklist);

  @override
  Future<Set<String>> get lintRulesOff => _read(_inner.lintRulesOff);

  @override
  Future<EditorKind> get editorKind => _read(_inner.editorKind);

  @override
  Future<Set<EditorKind>> get enabledEditors => _read(_inner.enabledEditors);

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

  test('the read asks for the settings together (#362)', () async {
    final session = _CountedReads(FakeLibrarySession());

    final settings = await ShellEditorSettings.read(session);

    expect(settings, ShellEditorSettings.defaults);
    expect(
      session.reads,
      17,
      reason: 'every setting the session answers; the two folders ride on ops',
    );
    expect(
      session.peak,
      greaterThan(1),
      reason: 'the reads go out together, not one awaited after another',
    );
  });
}
