// The PDF view's document lets go of its file for an operation on it
// (#833): pdfium has closed the document — waited for, not just asked —
// before the file moves, and the view opens it anew after.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/file_holds.dart';
import 'package:niman/src/ui/pdf_held_document.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

/// A document whose closing completes when the test says so.
final class _Document extends Fake implements PdfDocument {
  final Completer<void> closing = Completer();
  int closes = 0;

  @override
  Future<void> dispose() {
    closes++;
    return closing.future;
  }
}

void main() {
  final path = p.join(p.current, 'library', 'paper.pdf');

  test('the operation runs once the document is closed', () async {
    final holds = FileHolds();
    final documents = <_Document>[];
    final held = PdfHeldDocument(
      path,
      holds: holds,
      open: (_) async {
        final document = _Document();
        documents.add(document);
        return document;
      },
    );
    addTearDown(held.dispose);
    final shown = held.ref!;
    await shown.resolveListenable().load();
    expect(documents, hasLength(1));

    var moved = false;
    final operation = holds.around([path], () async => moved = true);
    await pumpEventQueue();
    // Asked to close, not closed yet: the file has not moved, and the
    // viewer has nothing to show meanwhile.
    expect(documents.single.closes, 1);
    expect(moved, isFalse);
    expect(held.ref, isNull);

    documents.single.closing.complete();
    await operation;
    expect(moved, isTrue);
    // Opened anew, in a reference of its own.
    expect(held.ref, isNot(same(shown)));
    expect(held.ref!.key, isNot(shown.key));
  });

  test('a document still opening is closed before the operation', () async {
    final holds = FileHolds();
    final opening = Completer<PdfDocument>();
    final held = PdfHeldDocument(
      path,
      holds: holds,
      open: (_) => opening.future,
    );
    addTearDown(held.dispose);
    final load = held.ref!.resolveListenable().load();
    await pumpEventQueue();

    var moved = false;
    final operation = holds.around([path], () async => moved = true);
    await pumpEventQueue();
    expect(moved, isFalse);

    final document = _Document();
    opening.complete(document);
    await pumpEventQueue();
    expect(document.closes, greaterThan(0));
    expect(moved, isFalse);
    document.closing.complete();
    await operation;
    await load;
    expect(moved, isTrue);
  });

  test('a view gone lets go of its hold', () async {
    final holds = FileHolds();
    final held = PdfHeldDocument(
      path,
      holds: holds,
      open: (_) async {
        return _Document()..closing.complete();
      },
    );
    expect(holds.holding(path), hasLength(1));

    held.dispose();
    expect(holds.holding(path), isEmpty);
  });
}
