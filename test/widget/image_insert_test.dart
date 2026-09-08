// T-M2-09 AC: inserting an image copies it into the library and injects a
// library-relative link at the caret; the preview renders relative images
// from the library root.
//
// Real dart:io and image decoding do not complete under FakeAsync, so every
// IO call (temp dirs, writes, the FileImage decode) runs inside
// `tester.runAsync` — that is also what proves "image visible in preview":
// the decode is awaited via precacheImage.
import 'dart:io';
import 'dart:typed_data';

import 'package:copist/src/preview/markdown_preview.dart';
import 'package:copist/src/ui/note_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:re_editor/re_editor.dart';

/// A real 1x1 PNG (so Image.file can decode it in tests).
final Uint8List _png = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  testWidgets('the preview renders a library-relative image link', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('copist_pv_');
      try {
        final assets = Directory(p.join(dir.path, 'assets'))..createSync();
        await File(p.join(assets.path, 'pic.png')).writeAsBytes(_png);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MarkdownPreview(
                data: 'before\n\n![alt](assets/pic.png)\n\nafter',
                imageDirectory: dir.path,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        final image = tester.widget<Image>(find.byType(Image));
        final fileImage = image.image as FileImage;
        expect(fileImage.file.path.endsWith('pic.png'), isTrue);

        // Prove it decodes (i.e. the image is actually visible):
        await precacheImage(fileImage, tester.element(find.byType(Image)));
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });

  testWidgets('the insert action copies and links at the caret (AC)', (
    tester,
  ) async {
    final dir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('copist_ins_'),
    ))!;
    try {
      final source = File(p.join(dir.path, 'pic.png'));
      await tester.runAsync(() => source.writeAsBytes(_png));
      final controller = CodeLineEditingController.fromText('hello');
      final writes = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteView(
              path: p.join(dir.path, 'note.md'),
              showLineNumbers: true,
              autofocusEditor: false,
              libraryRoot: dir.path,
              controller: controller,
              readNote: (_) async => 'hello',
              // Seams must not await real dart:io (it never completes under
              // FakeAsync): the copy runs sync, the save is a no-op.
              writeNote: (path, content) async => writes.add(content),
              pickImagePath: () async => source.path,
              importImage: (root, src) {
                final assets = Directory(p.join(root, 'assets'));
                if (!assets.existsSync()) assets.createSync(recursive: true);
                File(p.join(assets.path, 'xx.png'))
                    .writeAsBytesSync(File(src).readAsBytesSync());
                return Future.value('assets/xx.png');
              },
            ),
          ),
        ),
      );
      await tester.pump(); // load lands; caret at 0.
      await tester.tap(find.byKey(const Key('insert-image')));
      await tester.pump(); // pick + copy futures complete.
      await tester.pump(); // snippet lands in the editor.
      expect(tester.takeException(), isNull);
      expect(controller.text, contains('![pic](assets/xx.png)'));
      expect(File(p.join(dir.path, 'assets/xx.png')).existsSync(), isTrue);
      // The inserted link autosaves like any edit:
      await tester.pump(const Duration(milliseconds: 600));
      expect(writes.single, contains('![pic](assets/xx.png)'));
      controller.dispose();
    } finally {
      await tester.runAsync(() => dir.delete(recursive: true));
    }
  });
}
