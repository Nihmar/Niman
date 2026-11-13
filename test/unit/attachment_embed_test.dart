// The attachments folder's embed link: a wikilink embed by default, a
// Markdown image link when the library writes Markdown links, written from
// the note's folder (#1282).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/links/attachment_embed.dart';

void main() {
  String markdown(String path, String note) => attachmentEmbed(
    relativePath: path,
    label: 'photo',
    linkType: LinkType.markdown,
    note: note,
  );

  test('wikilink libraries embed with double brackets, by library path', () {
    expect(
      attachmentEmbed(
        relativePath: 'assets/a1b2.wav',
        label: '',
        linkType: LinkType.wikilink,
        note: 'Projects/2026/plan.md',
      ),
      '![[assets/a1b2.wav]]',
    );
  });

  test('Markdown libraries embed an image link with the label', () {
    expect(markdown('assets/a1b2.png', 'plan.md'), '![photo](assets/a1b2.png)');
  });

  test("a Markdown link is written from the note's folder (#1282)", () {
    expect(
      markdown('assets/a1b2.png', 'Projects/2026/plan.md'),
      '![photo](../../assets/a1b2.png)',
    );
    expect(
      markdown('Projects/assets/a1b2.png', 'Projects/plan.md'),
      '![photo](assets/a1b2.png)',
      reason: 'a folder the two share is not climbed out of',
    );
  });

  test('a space in the path is percent-encoded', () {
    expect(
      markdown('My pictures/a1b2.png', 'Notes/plan.md'),
      '![photo](../My%20pictures/a1b2.png)',
    );
  });
}
