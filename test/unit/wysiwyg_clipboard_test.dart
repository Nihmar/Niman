// #165: the WYSIWYG clipboard carries Markdown, not stripped text.
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/wysiwyg/markdown_document_codec.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_clipboard.dart';

const MarkdownDocumentCodec _codec = MarkdownDocumentCodec();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? copied;
  String? onClipboard;

  setUp(() {
    copied = null;
    onClipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          switch (call.method) {
            case 'Clipboard.setData':
              copied = (call.arguments as Map)['text'] as String?;
            case 'Clipboard.getData':
              // An empty clipboard answers with nothing at all, not with
              // a map holding a null.
              return onClipboard == null
                  ? null
                  : <String, Object?>{'text': onClipboard};
          }
          return null;
        });
  });

  /// A clipboard over a note, with [selection] selected.
  ({WysiwygClipboard clipboard, quill.QuillController controller}) over(
    String note, {
    int? start,
    int? end,
  }) {
    final controller = quill.QuillController(
      document: _codec.decode(note).document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);
    if (start != null && end != null) {
      controller.updateSelection(
        TextSelection(baseOffset: start, extentOffset: end),
        quill.ChangeSource.local,
      );
    }
    return (
      clipboard: WysiwygClipboard(controller: () => controller),
      controller: controller,
    );
  }

  group('copy', () {
    const list = '- Bolla originale: 425259\n- Bolla clonata: 441372\n';

    test('the last item keeps its bullet', () async {
      // The device report: a selection to the end of the last item stops
      // before the newline that carries `list: bullet`, so that item used
      // to arrive as a plain paragraph.
      final text = over(list).controller.document.toPlainText();
      final editor = over(list, start: 0, end: text.length - 1);

      expect(await editor.clipboard.copy(), isTrue);
      expect(copied, '- Bolla originale: 425259\n- Bolla clonata: 441372');
    });

    test('one item copies as one item', () async {
      final editor = over(
        list,
        start: 0,
        end: 'Bolla originale: 425259'.length,
      );
      expect(await editor.clipboard.copy(), isTrue);
      expect(copied, '- Bolla originale: 425259');
    });

    test('headings and emphasis travel too', () async {
      const note = '# Titolo\n\nUn **grassetto** e un *corsivo*.\n';
      final text = over(note).controller.document.toPlainText();
      final editor = over(note, start: 0, end: text.length - 1);

      expect(await editor.clipboard.copy(), isTrue);
      expect(copied, contains('# Titolo'));
      expect(copied, contains('**grassetto**'));
      expect(copied, contains('*corsivo*'));
    });

    test('nothing selected copies nothing', () async {
      final editor = over(list);
      expect(await editor.clipboard.copy(), isFalse);
      expect(copied, isNull);
    });

    test('cut removes what was selected, not the borrowed newline', () async {
      const note = 'prima\nseconda\n';
      final editor = over(note, start: 0, end: 'prima'.length);

      expect(await editor.clipboard.copy(cut: true), isTrue);
      expect(copied, 'prima');
      expect(editor.controller.document.toPlainText(), '\nseconda\n');
    });
  });

  group('paste', () {
    test('Markdown comes back as structure, not as characters', () async {
      final editor = over('\n', start: 0, end: 0);
      onClipboard = '- uno\n- due';

      expect(await editor.clipboard.paste(), isTrue);
      final ops = editor.controller.document.toDelta().toJson();
      final bullets = ops
          .where((op) => (op['attributes'] as Map?)?['list'] == 'bullet')
          .length;
      expect(bullets, 2, reason: 'both items should be list lines');
      expect(editor.controller.document.toPlainText(), contains('uno'));
    });

    test('a round trip through the clipboard keeps the note', () async {
      const note = '- uno\n- due\n';
      final text = over(note).controller.document.toPlainText();
      final source = over(note, start: 0, end: text.length - 1);
      await source.clipboard.copy();

      onClipboard = copied;
      final target = over('\n', start: 0, end: 0);
      expect(await target.clipboard.paste(), isTrue);
      expect(
        _codec.encode(target.controller.document).trimRight(),
        '- uno\n- due',
      );
    });

    test('a word keeps its line', () async {
      final editor = over('prima\n', start: 5, end: 5);
      onClipboard = ' e poi';

      expect(await editor.clipboard.paste(), isTrue);
      expect(editor.controller.document.toPlainText(), 'prima e poi\n');
    });

    test('an empty clipboard is handed back to the package', () async {
      final editor = over('prima\n', start: 0, end: 5);
      onClipboard = null;
      expect(await editor.clipboard.paste(), isFalse);
    });
  });
}
