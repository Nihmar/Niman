// #1249: files copied in a file manager and pasted into a note are copied
// into the library's attachments folder, under their content's hash, and
// linked at the caret in the library's format — a picture embedded, the
// rest linked, each reading as the name it came with. A file already in the
// library is linked where it is; a note with no library pastes text.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory sandbox;
  late String library;
  late String outside;
  late List<String> copied;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('niman_paste_files_');
    library = p.join(sandbox.path, 'library');
    outside = p.join(sandbox.path, 'Downloads');
    Directory(p.join(library, 'Notes')).createSync(recursive: true);
    Directory(outside).createSync();
    File(p.join(outside, 'Report 2026.pdf')).writeAsStringSync('%PDF-1.7');
    File(p.join(outside, 'photo.png')).writeAsBytesSync([137, 80, 78, 71]);
    copied = [];
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  String hashed(String name) {
    final bytes = File(p.join(outside, name)).readAsBytesSync();
    return '${sha256.convert(bytes)}${p.extension(name)}';
  }

  Future<void> open(
    WidgetTester tester, {
    String note = 'See: \nEnd.',
    LinkType linkType = LinkType.markdown,
    String? root,
    String clipboardText = 'plain text',
  }) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? <String, dynamic>{'text': clipboardText}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            path: p.join(library, 'Notes', 'trip.md'),
            libraryRoot: root ?? library,
            linkType: linkType,
            showLineNumbers: false,
            autofocusEditor: true,
            toolbarTop: true,
            readNote: (_) async => note,
            writeNote: (_, _) async {},
            readClipboardFiles: () async => copied,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  MarkdownSourceViewState editor(WidgetTester tester) =>
      tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

  String text(WidgetTester tester) => editor(tester).widget.buffer.text;

  /// Pastes at [offset]: the copy into the library is real file I/O in an
  /// isolate, which only a real event loop drives.
  Future<void> pasteAt(WidgetTester tester, int offset) async {
    editor(tester).placeCaret(offset);
    await tester.pump();
    await tester.runAsync(() => editor(tester).paste());
    await tester.pumpAndSettle();
  }

  testWidgets('each file is copied in and linked at the caret, by its name', (
    tester,
  ) async {
    copied = [p.join(outside, 'Report 2026.pdf'), p.join(outside, 'photo.png')];
    await open(tester);
    await pasteAt(tester, 'See: '.length);

    final pdf = hashed('Report 2026.pdf');
    final png = hashed('photo.png');
    expect(
      text(tester),
      'See: [Report 2026.pdf](../assets/$pdf)\n'
      '![photo.png](../assets/$png)\nEnd.',
    );
    expect(File(p.join(library, 'assets', pdf)).existsSync(), isTrue);
    expect(File(p.join(library, 'assets', png)).existsSync(), isTrue);
    expect(
      File(p.join(outside, 'photo.png')).existsSync(),
      isTrue,
      reason: 'a copy, never a move',
    );
  });

  testWidgets('a wikilink reads as the name, a picture embeds bare', (
    tester,
  ) async {
    copied = [p.join(outside, 'Report 2026.pdf'), p.join(outside, 'photo.png')];
    await open(tester, note: '', linkType: LinkType.wikilink);
    await pasteAt(tester, 0);
    expect(
      text(tester),
      '[[${hashed('Report 2026.pdf')}|Report 2026.pdf]]\n'
      '![[${hashed('photo.png')}]]',
    );
  });

  testWidgets('a file already in the library is linked where it is', (
    tester,
  ) async {
    final held = p.join(library, 'Notes', 'map.pdf');
    File(held).writeAsStringSync('%PDF');
    copied = [held];
    await open(tester, note: '');
    await pasteAt(tester, 0);
    expect(text(tester), '[map.pdf](map.pdf)');
    expect(Directory(p.join(library, 'assets')).existsSync(), isFalse);
  });

  testWidgets('a folder is not attached, and text pastes when that is all', (
    tester,
  ) async {
    copied = [outside];
    await open(tester, note: '');
    await pasteAt(tester, 0);
    expect(text(tester), 'plain text');
  });

  testWidgets('a note outside a library pastes text, not files', (
    tester,
  ) async {
    copied = [p.join(outside, 'photo.png')];
    await open(tester, note: '', root: p.join(sandbox.path, 'elsewhere'));
    await pasteAt(tester, 0);
    expect(text(tester), 'plain text');
  });

  testWidgets('a file that cannot be copied in is said, and nothing pasted', (
    tester,
  ) async {
    copied = [p.join(outside, 'photo.png')];
    // The attachments folder's place is a file: no folder can be made there.
    File(p.join(library, 'assets')).writeAsStringSync('');
    await open(tester, note: '');
    await pasteAt(tester, 0);
    expect(text(tester), '');
    expect(find.text(AppStrings.attachFailed('photo.png')), findsOne);
  });
}
