import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/context_menu_items.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/editor_tool.dart';
import 'package:niman/src/editor/list_tally.dart';
import 'package:niman/src/editor/list_tally_edit.dart';
import 'package:niman/src/editor/list_to_mindmap.dart' as mindmap;
import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/links/attachment_embed.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_check_sheet.dart';
import 'package:niman/src/spellcheck/spell_issue.dart';
import 'package:niman/src/ui/editor_menu.dart';
import 'package:niman/src/ui/editor_tools_sheet.dart';
import 'package:niman/src/ui/heading_level_sheet.dart';
import 'package:niman/src/ui/list_tally_sheet.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The open note's editing commands: what the formatting toolbar, the
/// format keys and the editor's context menu run (T-UI-08, #174, #205,
/// #260), the Tools sheet's (#136), the image picker's (T-M2-09) and the
/// spelling review's (T-PP-09).
///
/// Every one goes through the editor surface's own door, as one undoable
/// edit; the note view owns this and hands it the surface, its panes and
/// the settings the commands read, each through a callback read when a
/// command runs.
final class NoteEditCommands {
  /// Commands over the note [surface] holds.
  ///
  /// [focus] gives the editor the keyboard back after a command; [context]
  /// and [mounted] are the note view's, for the sheets and dialogs a
  /// command opens. [canInsert] says whether the note takes an edit at all
  /// (it is loaded, and no kind GUI stands in front of it).
  new({
    required this.surface,
    required this.focus,
    required this.context,
    required this.mounted,
    required this.canInsert,
    required this.text,
    required this.sourceView,
    required this.readView,
    required this.activeFormats,
    required this.linkType,
    required this.indentWidth,
    required this.toolbarLayout,
    required this.pasteAsMarkdown,
    required this.libraryRoot,
    required this.pickImage,
    required this.importImage,
    required this.onInserted,
    required this.spellCheck,
    required this.onSpellChecked,
  });

  /// The note on the editor surface, or null before one is open.
  final MarkdownSurfaceController? Function() surface;

  /// Gives the editor the focus back.
  final VoidCallback focus;

  /// The note view's context.
  final BuildContext Function() context;

  /// Whether the note view is still mounted.
  final bool Function() mounted;

  /// Whether the note takes an edit from outside the editor.
  final bool Function() canInsert;

  /// The note's text, joined.
  final String Function() text;

  /// The source pane's state, when it is built.
  final MarkdownSourceViewState? Function() sourceView;

  /// The read pane's state, when it is built.
  final MarkdownReadViewState? Function() readView;

  /// The formats on at the caret: the toolbar's pressed state.
  final ValueListenable<Set<ToolbarItem>> activeFormats;

  /// The link format the link button inserts (settings).
  final LinkType Function() linkType;

  /// The indent/outdent width in spaces (settings).
  final int Function() indentWidth;

  /// The toolbar the user arranged (settings).
  final ToolbarLayout Function() toolbarLayout;

  /// Paste as Markdown, for the context menu (#531); null leaves it out.
  final VoidCallback? Function() pasteAsMarkdown;

  /// The library root images are imported into; null disables insert.
  final String? Function() libraryRoot;

  /// Picks an image file, or null when the pick was cancelled.
  final Future<String?> Function() pickImage;

  /// Imports the picked file at `source` into the library at `root`, and
  /// returns its library-relative path.
  final Future<String> Function(String root, String source) importImage;

  /// Text was inserted from outside the editor (an image): the statistics
  /// and the preview are brought up to date.
  final VoidCallback onInserted;

  /// The editor's spelling state, or null when there is none.
  final EditorSpellCheck? Function() spellCheck;

  /// The spelling review closed: the pane is drawn again.
  final VoidCallback onSpellChecked;

  /// What each toolbar button does. The catalogue and the order live in
  /// `editor/toolbar_item.dart`; the commands stay here, with the
  /// controller they act on.
  Map<ToolbarItem, VoidCallback> toolbarActions() {
    return {
      ToolbarItem.bold: () => _wrapSelection(left: '**', right: '**'),
      ToolbarItem.italic: () => _wrapSelection(left: '*', right: '*'),
      ToolbarItem.strikethrough: () => _wrapSelection(left: '~~', right: '~~'),
      ToolbarItem.highlight: () => _wrapSelection(left: '==', right: '=='),
      ToolbarItem.superscript: () =>
          _wrapSelection(left: '<sup>', right: '</sup>'),
      ToolbarItem.underline: () => _wrapSelection(left: '<u>', right: '</u>'),
      ToolbarItem.link: _insertLink,
      ToolbarItem.code: _insertCodeBlock,
      ToolbarItem.image: insertImage,
      ToolbarItem.table: () => run(
        (text, selection) => insertTable(text: text, selection: selection),
        // The lines either side: the table keeps a blank line from them.
        context: 1,
      ),
      ToolbarItem.heading: _showHeadingDialog,
      ToolbarItem.list: () => _prefixLines(prefix: '- '),
      ToolbarItem.orderedList: _insertOrderedList,
      ToolbarItem.checklist: () => run(
        (text, selection) => toggleTaskList(text: text, selection: selection),
      ),
      ToolbarItem.quote: () => _prefixLines(prefix: '> '),
      ToolbarItem.outdent: () => _indentLines(outdent: true),
      ToolbarItem.indent: () => _indentLines(outdent: false),
      ToolbarItem.tools: () => unawaited(_openTools()),
    };
  }

  /// The toolbar's buttons as context-menu entries (#174): the same
  /// visible items in the same order, the same actions, and the same
  /// pressed state — read when the menu opens, so it is the caret's now.
  List<FormatMenuEntry> formatMenu() {
    final actions = toolbarActions();
    final active = activeFormats.value;
    return [
      for (final item in toolbarLayout().visible)
        if (actions[item] case final action?)
          FormatMenuEntry(
            item: item,
            onPressed: action,
            active: active.contains(item),
          ),
    ];
  }

  /// The unified surface's context menu, grouped (#260): read as it
  /// opens, so its lit entries are the caret's now.
  ContextMenuPart contextMenu() {
    final surface = this.surface();
    var level = 0;
    if (surface != null) {
      final buffer = surface.buffer;
      final line = buffer.lineOf(surface.selection.extent);
      final text = buffer.lineAt(line);
      while (level < text.length && level < 7 && text[level] == '#') {
        level++;
      }
      if (level > 6 || (level < text.length && text[level] != ' ')) level = 0;
    }
    return editorMenu(
      active: activeFormats.value,
      headingLevel: level,
      run: run,
      onImage: insertImage,
      onFootnote: _insertFootnote,
      onPasteMarkdown: pasteAsMarkdown(),
    );
  }

  /// Runs a Markdown [command] on the source pane on screen.
  ///
  /// It is handed the lines the selection touches, not the note
  /// ([MarkdownSurfaceController.applyLineCommand]).
  void run(
    MarkdownEdit Function(String text, TextSelection selection) command, {
    int context = 0,
  }) {
    surface()?.applyLineCommand(command, context: context);
    focus();
  }

  /// Converts the list at the caret into a mind map, or says why it could
  /// not: the palette offers the command anywhere.
  void convertListToMindMap() {
    if (!canInsert()) return;
    final surface = this.surface();
    if (surface == null) return;
    final map = _mindMapAtCaret();
    if (map == null) {
      // The palette offers the command anywhere: say why it did nothing.
      final messenger = ScaffoldMessenger.maybeOf(context());
      final reason = SnackBar(content: Text(AppStrings.toolMindMapNeedsList));
      messenger?.showSnackBar(reason);
      return;
    }
    // Only the list's lines are replaced: one undo step, and the note is
    // never copied whole to make it.
    final buffer = surface.buffer;
    final last = map.endLine - 1;
    final terminator = buffer.terminatorAt(map.startLine);
    surface.applyEdit(
      map.fence.join(terminator.isEmpty ? '\n' : terminator),
      const TextSelection.collapsed(offset: 0),
      start: buffer.offsetOfLine(map.startLine),
      end: buffer.offsetOfLine(last) + buffer.lineLengthAt(last),
    );
    focus();
  }

  /// The mind map the list at the caret becomes, or null when the caret is
  /// not in one — what the palette command converts and the Tools sheet
  /// offers, read the same way for both.
  mindmap.ListMindMap? _mindMapAtCaret() =>
      _caretList<mindmap.ListMindMap?>(mindmap.listToMindMap);

  /// [read] of the list at the caret, or null without a note: the caret's
  /// line, and the pane's own scan when it draws this buffer — a scan as far
  /// as the list otherwise.
  T? _caretList<T>(
    T Function({
      required SourceBuffer buffer,
      required int line,
      Block? Function(int line)? blockAt,
    })
    read,
  ) {
    final surface = this.surface();
    if (surface == null) return null;
    final buffer = surface.buffer;
    final view = sourceView();
    return read(
      buffer: buffer,
      line: buffer.lineOf(surface.selection.extent),
      blockAt: identical(view?.widget.buffer, buffer) ? view?.blockAt : null,
    );
  }

  /// T-M2-09: pick an image, copy it into the library's attachments
  /// folder, insert a library-relative link at the caret — in the
  /// library's link format (wikilink embed or Markdown image).
  Future<void> insertImage() async {
    final root = libraryRoot();
    if (root == null) return;
    final source = await pickImage();
    if (source == null || !mounted()) return;
    final relative = await importImage(root, source);
    if (!mounted()) return;
    // Alt text comes from the picked file's name; the link itself is the
    // content-addressed library path, so `photo.png` keeps a readable label.
    final label = p.basenameWithoutExtension(source);
    final snippet = attachmentEmbed(
      relativePath: relative,
      label: label,
      linkType: linkType(),
    );
    surface()?.replaceSelection(snippet);
    focus();
    onInserted();
  }

  /// The platform's image picker (file_picker).
  static Future<String?> pickImageFile() async {
    // Picker returns [] when canceled: static API (v12).
    final result = await FilePicker.pickFiles(type: FileType.image);
    final file = result.isEmpty ? null : result.first;
    return file?.path;
  }

  /// A footnote cited at the caret, defined under its paragraph, numbered
  /// one past the note's highest (#260).
  void _insertFootnote() {
    final surface = this.surface();
    if (surface != null) {
      final labels = sourceView()?.footnoteLabels;
      final label = nextFootnoteLabel(labels ?? const <String>[]);
      // The caret's paragraph, as far as its first blank line: the lines
      // the definition goes under.
      final buffer = surface.buffer;
      final start = buffer.lineOf(surface.selection.extent);
      var last = start;
      while (last + 1 < buffer.lineCount &&
          last - start < _footnoteReach &&
          buffer.lineAt(last + 1).trim().isNotEmpty) {
        last++;
      }
      surface.applyLineCommand(
        (text, selection) =>
            insertFootnote(text: text, selection: selection, label: label),
        through: last + 1,
      );
      focus();
    }
  }

  /// How far down a paragraph the footnote's definition is looked for a
  /// place under it: a paragraph longer than that has it here.
  static const int _footnoteReach = 2000;

  /// Opens the editor's Tools sheet (#136) and runs whatever was picked.
  ///
  /// The availability is worked out here rather than in the sheet: only
  /// this side knows which surface is showing, and each one finds its
  /// lists its own way.
  Future<void> _openTools() async {
    final tool = await showEditorToolsSheet(
      context(),
      available: <EditorTool>{
        if (_hasListToCount) EditorTool.countList,
        if (_hasListAtCaret) EditorTool.mindMap,
      },
    );
    if (!mounted() || tool == null) return;
    switch (tool) {
      case EditorTool.countList:
        await _countList();
      case EditorTool.mindMap:
        convertListToMindMap();
    }
  }

  /// Whether the caret stands in a list, so the mind-map tool can run.
  /// One block read, not the conversion: the sheet only asks.
  bool get _hasListAtCaret => _caretList(mindmap.hasListAt) ?? false;

  /// Whether the note has a list the count could run on.
  ///
  /// Asks the pane's own scan rather than reading the note: the tool sheet
  /// lists every tool and greys the ones that cannot run, so this used to
  /// join a 246 MB note and tokenize it every time the sheet opened
  /// (`tallyTargetsIn` builds a whole `HighlightDocument`). The scan is what
  /// the colours are drawn from, and it already knows a list item when it
  /// makes one (see `blockList`).
  bool get _hasListToCount {
    // The pane on screen has the note scanned; a hidden one does not, and
    // then the source pane's own copy is asked for its blocks rather than
    // the text being read again.
    final scanned = sourceView()?.blocks ?? readView()?.blocks;
    final buffer = surface()?.buffer;
    if (scanned != null) return blockList(scanned);
    if (buffer != null) return blockList(BlockScanner(buffer).index.blocks);
    return blockList(scannedBlocksOf(text()));
  }

  /// Counts a list into a checklist.
  Future<void> _countList() async {
    final text = this.text();
    final targets = tallyTargetsIn(text);
    if (targets.isEmpty) return;
    final here = tallyTargetAt(text, _caretLine);
    final choice = await showListTallySheet(
      context(),
      candidates: <TallyCandidate>[
        for (final target in targets)
          TallyCandidate(
            rows: target.rows,
            checks: tallyChecksAt(text, target),
            replaces: target.replaces,
          ),
      ],
      initialIndex: here == null
          ? 0
          : targets.indexWhere((t) => t.sourceStart == here.sourceStart),
    );
    if (!mounted() || choice == null) return;
    final target = targets[choice.index];
    _applyMarkdownEdit(
      applyTally(
        text: text,
        target: target,
        rows: tallyList(
          rows: target.rows,
          cut: choice.cut,
          sort: choice.sort,
          checked: tallyChecksAt(text, target),
        ),
      ),
    );
  }

  /// Applies a pure markdown command's result: the whole text is set
  /// (undoable) and the selection lands where the command put it — inside
  /// the markers for wraps, the same lines for line edits. The editor
  /// keeps its focus (the IME stays up); focus is re-requested
  /// defensively.
  void _applyMarkdownEdit(MarkdownEdit edit) {
    // Through the surface: one undoable edit, the platform told, the save
    // scheduled.
    surface()?.applyEdit(edit.text, edit.selection);
    focus();
  }

  /// The line the command's caret is on (0-based).
  int get _caretLine {
    final surface = this.surface();
    if (surface == null) return 0;
    return surface.buffer.lineOf(surface.selection.anchor);
  }

  void _wrapSelection({required String left, required String right}) {
    run(
      (text, selection) => wrapSelection(
        text: text,
        selection: selection,
        left: left,
        right: right,
      ),
    );
  }

  void _insertCodeBlock() {
    run((text, selection) => codeBlock(text: text, selection: selection));
  }

  void _prefixLines({required String prefix}) {
    run(
      (text, selection) =>
          prefixLines(text: text, selection: selection, prefix: prefix),
    );
  }

  /// Inserts a link in the format chosen in settings (wikilink `[[…]]`
  /// or markdown `[…](…)`).
  void _insertLink() {
    final markdown = linkType() == LinkType.markdown;
    run(
      (text, selection) => wrapSelection(
        text: text,
        selection: selection,
        left: markdown ? '[' : '[[',
        right: markdown ? '](...)' : ']]',
      ),
    );
  }

  /// Numbers the selected line(s) as an ordered list.
  void _insertOrderedList() {
    run((text, selection) => orderedList(text: text, selection: selection));
  }

  /// Indents (or outdents, [outdent] true) the selected line(s) by the
  /// width chosen in settings.
  void _indentLines({required bool outdent}) {
    run(
      (text, selection) => indentLines(
        text: text,
        selection: selection,
        width: indentWidth(),
        outdent: outdent,
      ),
    );
  }

  /// Shows the heading-level picker (H1..H6) and applies the chosen level
  /// to the selected line(s).
  Future<void> _showHeadingDialog() async {
    final level = await showHeadingLevelDialog(context());
    if (level == null) return;
    run(
      (text, selection) =>
          setHeading(text: text, selection: selection, level: level),
    );
  }

  /// Opens the spelling review panel (T-PP-09).
  Future<void> openSpellCheck() async {
    final spell = spellCheck();
    if (spell == null) return;
    await showModalBottomSheet<void>(
      context: context(),
      isScrollControlled: true,
      builder: (context) => SpellCheckSheet(
        start: _scanSpelling,
        suggest: spell.suggestionsFor,
        apply: _applySpelling,
        available: spell.available,
      ),
    );
    onSpellChecked();
  }

  /// A pass over the whole note, in reading order (the panel's), reading
  /// each line — and tokenizing it for what to skip — only as the pass
  /// gets to it (#61).
  SpellScan _scanSpelling() {
    final spell = spellCheck()!;
    final surface = this.surface();
    if (surface == null) {
      return spell.startScan(lineCount: 0, lineAt: (_) => (text: '', skip: []));
    }
    // The surface's own lines, and its own tokenizer's runs: code, maths,
    // links and markers are skipped as they are in the underline.
    final buffer = surface.buffer;
    return spell.startScan(
      lineCount: buffer.lineCount,
      lineAt: (i) =>
          (text: buffer.lineAt(i), skip: spellSkipRanges(surface.tokensOf(i))),
    );
  }

  /// Replaces one issue's word in the controller (the panel's fix).
  void _applySpelling(SpellIssue issue, String replacement) {
    final surface = this.surface();
    if (surface == null) return;
    final buffer = surface.buffer;
    if (issue.line >= buffer.lineCount) return;
    final start = buffer.offsetOfLine(issue.line);
    surface.replaceRange(start + issue.start, start + issue.end, replacement);
  }
}
