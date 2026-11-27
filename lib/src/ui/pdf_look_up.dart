/// *Look up* on a PDF's selection (#1383): its menu entry, its key, and the
/// language kept for the file.
///
/// A PDF says no language the app can read (pdfrx exposes neither its
/// metadata nor its `/Lang`), so the look-up starts from the library's
/// spelling language, and the panel's chip changes it: the choice is kept
/// for that file in its reading entry (`ReadingPositions.setLanguage`), and
/// for the session where the file is not in a library.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/ui/dictionary_look_up_action.dart';
import 'package:niman/src/ui/dictionary_lookup_flow.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:pdfrx/pdfrx.dart';

/// Looks up what a PDF has selected.
final class PdfLookUp {
  /// The look-up of the PDF at `path` shown by `owner`, kept among
  /// `positions` (null: nowhere). `passage` gives the annotation of a
  /// selection, null where the file cannot be annotated; `annotate` writes
  /// it.
  new({
    required this._owner,
    required this._path,
    required this._positions,
    required this._passage,
    required this._annotate,
  });

  final State _owner;
  final String _path;
  final ReadingPositions? _positions;
  final Future<Annotation?> Function(PdfTextSelection selection) _passage;
  final void Function(Annotation annotation) _annotate;

  /// The language chosen for the file, or null while none was.
  String? _language;

  /// The key the file's entry is kept under; null outside a library.
  String? get _key => _positions?.keyOf(_path);

  /// Reads the language kept for the file.
  Future<void> load() async {
    final key = _key;
    if (key == null) return;
    final kept = await _positions?.language(key);
    if (kept != null && _owner.mounted) _language ??= kept;
  }

  /// Where the pointer last was over the viewer, in the window's
  /// coordinates: where the panel hangs from when a key, not a menu, asks.
  Offset? pointer;

  /// The keys that look the selection up, bound to [selection]'s current
  /// value; empty where the reader has the keys for a command of its own.
  Map<ShortcutActivator, VoidCallback> bindings(
    PdfTextSelection? Function() selection,
  ) {
    final keys = lookUpShortcut();
    if (keys == null) return const {};
    return {
      keys: () {
        final selected = selection();
        if (selected == null || !selected.hasSelectedText) return;
        final at = pointer;
        unawaited(
          _run(
            selected,
            at == null
                ? null
                : Rect.fromCenter(center: at, width: 0, height: 20),
          ),
        );
      },
    };
  }

  /// The menu's entry, to be added after Annotate: looks up the selection
  /// of [params]' delegate, under the anchor the menu was placed by.
  ContextMenuButtonItem menuItem(PdfViewerContextMenuBuilderParams params) =>
      ContextMenuButtonItem(
        label: AppStrings.lookUpAction,
        onPressed: () {
          params.dismissContextMenu();
          unawaited(_run(params.textSelectionDelegate, _anchorOf(params)));
        },
      );

  /// The menu's anchors, which are local to the viewer, in the window's
  /// coordinates.
  Rect? _anchorOf(PdfViewerContextMenuBuilderParams params) {
    final box = _owner.context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final from = box.localToGlobal(params.anchorA);
    final to = box.localToGlobal(params.anchorB ?? params.anchorA);
    final anchor = Rect.fromPoints(from, to);
    return anchor.height >= 4
        ? anchor
        : Rect.fromCenter(center: anchor.center, width: 0, height: 20);
  }

  Future<void> _run(PdfTextSelection selection, Rect? anchor) async {
    final text = await selection.getSelectedText();
    // The passage is read now: another may be selected by the time the
    // reader annotates.
    final annotation = await _passage(selection);
    if (text.trim().isEmpty || !_owner.mounted) return;
    await showDictionaryLookup(
      _owner.context,
      selection: text,
      surface: DictionarySurface.pdf,
      language: _language,
      anchor: anchor,
      annotate: annotation == null
          ? null
          : (definition) async => _annotate(annotation.withComment(definition)),
      onLanguage: _keep,
    );
  }

  /// The language the reader chose: for the session, and for the file when
  /// it is in a library.
  void _keep(String language) {
    _language = language;
    if (_key case final key?) {
      unawaited(_positions?.setLanguage(key, language));
    }
  }
}
