import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_check_sheet.dart';
import 'package:niman/src/spellcheck/spell_issue.dart';
import 'package:niman/src/ui/note_view_handle.dart';

/// The open note's spelling review (T-PP-09, #712): the pass over the note,
/// the issue a click selects, the fix it applies, and the sheet a phone opens
/// it in.
///
/// Every fix goes through the editor surface's own door, as one undoable
/// edit; the note view owns this and hands it the surface and the spell
/// check, each through a callback read when the review runs.
final class NoteSpelling {
  /// A review of the note [surface] holds.
  ///
  /// [context] is the note view's, for the sheet; [spellCheck] the editor's
  /// spelling state, or null when there is none, and [onSpellChecked] says
  /// the sheet closed and the pane is to be drawn again.
  new({
    required this.surface,
    required this.context,
    required this.spellCheck,
    required this.onSpellChecked,
  });

  /// The note on the editor surface, or null before one is open.
  final MarkdownSurfaceController? Function() surface;

  /// The note view's context.
  final BuildContext Function() context;

  /// The editor's spelling state, or null when there is none.
  final EditorSpellCheck? Function() spellCheck;

  /// The spelling review closed: the pane is drawn again.
  final VoidCallback onSpellChecked;

  /// The words the review's Ignore was pressed on (#907), for as long as
  /// the note is open in this view: closing the pane or editing does not
  /// bring them back. Not stored: a new session starts clean, and the
  /// library's dictionary is for words to keep.
  final Set<String> _ignored = <String>{};

  /// The note's spelling, for the review in the dock (#712); null without
  /// a spell check. [edited] tells of an edit, a pause after it.
  SpellReview? spellReview({required Listenable edited}) {
    final spell = spellCheck();
    if (spell == null) return null;
    return (
      start: _scan,
      suggest: spell.suggestionsFor,
      apply: _apply,
      reveal: _reveal,
      addWord: spell.addToDictionary,
      ignored: _ignored,
      edited: edited,
      available: spell.available,
    );
  }

  /// Opens the spelling review (T-PP-09) as a sheet over the note: the
  /// phone's way to it. The row's button is left out wherever the panel
  /// holds the review (#1002), so a sheet is all this opens.
  Future<void> openSpellCheck() async {
    final spell = spellCheck();
    if (spell == null) return;
    await showModalBottomSheet<void>(
      context: context(),
      isScrollControlled: true,
      builder: (context) => SpellCheckSheet(
        start: _scan,
        suggest: spell.suggestionsFor,
        apply: _apply,
        available: spell.available,
      ),
    );
    onSpellChecked();
  }

  /// A pass over the whole note, in reading order (the panel's), reading
  /// each line — and tokenizing it for what to skip — only as the pass
  /// gets to it (#61).
  SpellScan _scan() {
    final spell = spellCheck()!;
    final surface = this.surface();
    if (surface == null) {
      return spell.startScan(lineCount: 0, lineAt: (_) => (text: '', skip: []));
    }
    // The surface's own lines, and its own tokenizer's runs: code, maths,
    // links and markers are skipped as they are in the underline.
    final buffer = surface.buffer;
    // The review in the dock leaves the note editable, and the pass hands
    // the frame back between slices: it is bound to the revision it was
    // started on, and stops at the first line after an edit (#958).
    final revision = buffer.revision;
    return spell.startScan(
      lineCount: buffer.lineCount,
      lineAt: (i) =>
          (text: buffer.lineAt(i), skip: spellSkipRanges(surface.tokensOf(i))),
      current: () =>
          identical(surface.buffer, buffer) && buffer.revision == revision,
    );
  }

  /// Where [issue]'s line starts in the buffer, or null when the note no
  /// longer holds the issue's word at the range the pass found (#908): the
  /// docked review is not modal, so the note can change between the pass
  /// and the click, and the range is then another text's.
  int? _lineStart(SourceBuffer buffer, SpellIssue issue) {
    if (issue.line >= buffer.lineCount) return null;
    if (issue.end > buffer.lineLengthAt(issue.line)) return null;
    final start = buffer.offsetOfLine(issue.line);
    final held = buffer.substring(start + issue.start, start + issue.end);
    return held == issue.word ? start : null;
  }

  /// Selects one issue's word in the editor and brings it into view;
  /// false, and nothing selected, when the word is no longer there.
  bool _reveal(SpellIssue issue) {
    final surface = this.surface();
    if (surface == null) return false;
    final start = _lineStart(surface.buffer, issue);
    if (start == null) return false;
    surface.select(
      SelectionModel(anchor: start + issue.start, extent: start + issue.end),
    );
    return true;
  }

  /// Replaces one issue's word in the controller (the panel's fix); false,
  /// and the text untouched, when the word is no longer there.
  bool _apply(SpellIssue issue, String replacement) {
    final surface = this.surface();
    if (surface == null) return false;
    final start = _lineStart(surface.buffer, issue);
    if (start == null) return false;
    surface.replaceRange(start + issue.start, start + issue.end, replacement);
    return true;
  }
}
