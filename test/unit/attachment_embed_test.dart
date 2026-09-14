// The attachments folder's embed link: a wikilink embed by default, a
// Markdown image link when the library writes Markdown links.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/links/attachment_embed.dart';

void main() {
  test('wikilink libraries embed with double brackets', () {
    expect(
      attachmentEmbed(
        relativePath: 'assets/a1b2.wav',
        label: '',
        linkType: LinkType.wikilink,
      ),
      '![[assets/a1b2.wav]]',
    );
  });

  test('Markdown libraries embed an image link with the label', () {
    expect(
      attachmentEmbed(
        relativePath: 'assets/a1b2.png',
        label: 'photo',
        linkType: LinkType.markdown,
      ),
      '![photo](assets/a1b2.png)',
    );
  });
}
