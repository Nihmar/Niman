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

  test('a link to a note this export does not carry is its own text', () async {
    final payload = await exportNote(
      text: 'See [altrove](altrove.md) and [il web](https://example.com).\n',
      title: 'T',
      path: 'Notes/T.md',
      root: '/lib',
      language: 'en',
      format: ExportFileFormat.html,
    );
    final page = utf8.decode(payload.bytes);
    // One note carries one page: `altrove.md` is not in it, and a relative
    // href to a file that is not there is dead (E4). A wikilink becomes
    // highlighted text; a Markdown note link becomes the text it shows.
    expect(page, isNot(contains('href="altrove.md"')));
    expect(page, contains('<span>altrove</span>'));
    // An absolute URL is not a note link: it stays the link it was.
    expect(page, contains('href="https://example.com"'));
  });
}
