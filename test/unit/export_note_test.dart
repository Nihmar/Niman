// One note as an exported file (#24).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/export_note.dart';

void main() {
  test('Markdown is the note as it stands, under its own name', () async {
    final payload = await exportNote(
      text: '# T\n',
      title: 'A title',
      path: 'Notes/T.md',
      root: '/lib',
      language: 'en',
      format: ExportFileFormat.markdown,
    );
    expect(payload.name, 'T.md');
    expect(payload.mimeType, 'text/markdown');
    expect(utf8.decode(payload.bytes), '# T\n');
  });

  test('HTML is a page titled by the note and in the app language', () async {
    final payload = await exportNote(
      text: '# Body\n',
      title: 'Il titolo',
      path: 'Notes/T.md',
      root: '/lib',
      language: 'it',
      format: ExportFileFormat.html,
    );
    expect(payload.name, 'T.html');
    expect(payload.mimeType, 'text/html');
    final page = utf8.decode(payload.bytes);
    expect(page, contains('<html lang="it">'));
    expect(page, contains('<title>Il titolo</title>'));
    expect(page, contains('<h1 id="body">Body</h1>'));
  });
}
