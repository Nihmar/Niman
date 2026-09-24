// An attachment picked in the tree is shown in the note pane: a picture
// zoomed and panned, a PDF page by page. (The PDF is drawn by PDFium, a
// native library a widget test cannot load: its viewer is left to the
// device, and only which files it takes is held here.)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/attachment_view.dart';
import 'package:path/path.dart' as p;

void main() {
  test('the files the pane shows itself', () {
    for (final name in ['a.png', 'b.JPG', 'c.jpeg', 'd.gif', 'e.webp']) {
      expect(isShownAttachment(name), isTrue, reason: name);
    }
    expect(isShownAttachment('Docs/Paper.PDF'), isTrue);
    for (final name in ['a.md', 'todo.txt', 'b.epub', 'c.zip', 'noext']) {
      expect(isShownAttachment(name), isFalse, reason: name);
    }
  });

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('niman_attach_'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pump(WidgetTester tester, String path) async {
    // Mounted with real time: the picture's read is real I/O, and started
    // in the test's fake time it never ends — the file stays open, which
    // Windows will not delete, and a bad picture never reports.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AttachmentView(path: path)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    imageCache.clear();
  }

  testWidgets('a picture is shown, zoomable, with its name', (tester) async {
    final png = await tester.runAsync(() async {
      final image = await createTestImage(width: 4, height: 3);
      return (await image.toByteData(format: ui.ImageByteFormat.png))!;
    });
    final file = File(p.join(dir.path, 'photo.png'))
      ..writeAsBytesSync(png!.buffer.asUint8List());
    await pump(tester, file.path);
    expect(find.byKey(const Key('attachment-picture')), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('photo.png'), findsOneWidget);
    expect(find.byKey(const Key('attachment-unreadable')), findsNothing);
    await unmount(tester);
  });

  testWidgets('a picture that does not decode says so', (tester) async {
    final file = File(p.join(dir.path, 'broken.png'))
      ..writeAsStringSync('not a picture');
    await pump(tester, file.path);
    expect(find.byKey(const Key('attachment-unreadable')), findsOneWidget);
    await unmount(tester);
  });
}
