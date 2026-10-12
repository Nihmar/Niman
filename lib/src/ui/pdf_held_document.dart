/// The PDF a `PdfDocumentView` shows, open in pdfium, and let go of when
/// the file is renamed, moved or deleted (#833).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/file_holds.dart';
import 'package:pdfrx/pdfrx.dart';

/// Opens the PDF at an absolute path.
typedef PdfOpener = Future<PdfDocument> Function(String path);

/// Opens [path] the way pdfrx's own file reference does.
Future<PdfDocument> openPdfFile(String path) async {
  await pdfrxFlutterInitialize();
  return await PdfDocument.openFile(path, useProgressiveLoading: true);
}

/// The document of the PDF at [path], held in a [FileHolds].
///
/// pdfrx's own file reference closes the document when its viewer goes,
/// without waiting for it: the file stays open for a while after. Here
/// the document is this object's: [ref] gives it to the viewer, and an
/// operation on the file closes it, waited for, before the file moves,
/// then a fresh [ref] opens it again. Listeners hear [ref] change.
final class PdfHeldDocument extends ChangeNotifier {
  /// Holds the PDF at [path] (absolute) in [holds].
  new(this.path, {FileHolds? holds, PdfOpener? open})
    : _open = open ?? openPdfFile {
    _hold = (holds ?? FileHolds.instance).hold(
      path,
      release: _release,
      resume: _resume,
    );
    _ref = _newRef();
  }

  /// The PDF's absolute path.
  final String path;

  final PdfOpener _open;
  late final FileHold _hold;

  /// Counts the references handed out, so each opens a document of its
  /// own: two views of one PDF never share one, nor does a view share
  /// one with the reference it had before the file moved.
  int _generation = 0;

  PdfDocumentRef? _ref;

  /// The documents opened, still to be closed: each is closed when the
  /// file is let go of, or when the view goes.
  final List<Future<PdfDocument?>> _opened = [];

  bool _disposed = false;

  /// The reference the viewer shows, null while the file is let go of.
  PdfDocumentRef? get ref => _ref;

  PdfDocumentRef _newRef() {
    final generation = ++_generation;
    return PdfDocumentRefByLoader(
      (_) => _load(generation),
      key: PdfDocumentRefKey(path, [identityHashCode(this), generation]),
      // The document is closed here, waited for, not by the viewer.
      autoDispose: false,
    );
  }

  Future<PdfDocument> _load(int generation) async {
    if (!_current(generation)) throw StateError('$path was let go of');
    final opening = _open(path);
    _opened.add(opening.then<PdfDocument?>((doc) => doc, onError: (_) => null));
    final document = await opening;
    // Opened for a reference that has gone meanwhile: closed at once.
    if (!_current(generation)) unawaited(_close(document));
    return document;
  }

  /// Whether [generation] is the reference the viewer is showing.
  bool _current(int generation) =>
      !_disposed && _ref != null && generation == _generation;

  /// Each document's closing, so a second close waits for the first
  /// rather than returning while pdfium still holds the file.
  final Expando<Future<void>> _closing = Expando();

  Future<void> _close(PdfDocument document) =>
      _closing[document] ??= document.dispose();

  /// Closes every document opened, waiting for pdfium to have let go.
  Future<void> _closeAll() async {
    final opened = [..._opened];
    _opened.clear();
    for (final opening in opened) {
      if (await opening case final document?) await _close(document);
    }
  }

  Future<void> _release() async {
    _ref = null;
    _generation++;
    if (!_disposed) notifyListeners();
    await _closeAll();
  }

  void _resume() {
    if (_disposed) return;
    _ref = _newRef();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _hold.drop();
    unawaited(_closeAll());
    super.dispose();
  }
}
