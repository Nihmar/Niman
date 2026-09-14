// The audio note's chat model: vocals on the left, written notes on
// the right, descriptions as blockquote lines under their vocal.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/ui/kinds/audio_chat.dart';
import 'package:niman/src/ui/kinds/audio_parser.dart';

void main() {
  group('parseAudioChat', () {
    test('a vocal with its description and a written note', () {
      const text =
          '---\ntype: audio\n---\n'
          '![](assets/a.wav)\n'
          '> what was said\n'
          'a written note\n';
      final items = parseAudioChat(text);
      expect(items, hasLength(2));
      final vocal = items.first as AudioChatMessage;
      expect(vocal.clip.target, 'assets/a.wav');
      expect(vocal.description, 'what was said');
      final note = items.last as TextChatMessage;
      expect(note.text, 'a written note');
    });

    test('a vocal without description and blank separators', () {
      const text =
          '---\ntype: audio\n---\n'
          '\n'
          '![](assets/a.wav)\n'
          '\n'
          'hello\n';
      final items = parseAudioChat(text);
      expect(items, hasLength(2));
      expect((items.first as AudioChatMessage).description, isEmpty);
      expect((items.last as TextChatMessage).text, 'hello');
    });

    test('multiline descriptions join with newlines', () {
      const text =
          '---\ntype: audio\n---\n'
          '![[assets/a.wav]]\n'
          '> first\n'
          '> second\n';
      final items = parseAudioChat(text);
      expect(items, hasLength(1));
      expect((items.single as AudioChatMessage).description, 'first\nsecond');
    });
  });

  group('description edits', () {
    test('setting replaces the quote run', () {
      const text =
          '---\ntype: audio\n---\n![](assets/a.wav)\n> old\n![](assets/b.wav)\n';
      final clip = parseAudioClips(text).first;
      expect(
        setClipDescription(text, clip, 'new'),
        '---\ntype: audio\n---\n![](assets/a.wav)\n> new\n![](assets/b.wav)\n',
      );
    });

    test('an empty description removes the quote run', () {
      const text = '---\ntype: audio\n---\n![](assets/a.wav)\n> old\nhello\n';
      final clip = parseAudioClips(text).first;
      expect(
        setClipDescription(text, clip, ''),
        '---\ntype: audio\n---\n![](assets/a.wav)\nhello\n',
      );
    });
  });

  group('written notes', () {
    test('append adds its own paragraph', () {
      const text = '---\ntype: audio\n---\n![](assets/a.wav)\n';
      expect(appendTextNote(text, 'hello'), '$text\nhello\n');
      expect(appendTextNote(text, '  '), text);
    });

    test('the first paragraph follows the frontmatter directly', () {
      const text = '---\ntype: audio\n---\n';
      expect(appendTextNote(text, 'hello'), '${text}hello\n');
    });

    test('remove drops the line range', () {
      const text = '---\ntype: audio\n---\nhello\nworld\n';
      final items = parseAudioChat(text);
      final note = items.single as TextChatMessage;
      expect(
        removeTextNote(text, note.start, note.end),
        '---\ntype: audio\n---\n',
      );
    });

    test('edit replaces the line range', () {
      const text = '---\ntype: audio\n---\nhello\n';
      final items = parseAudioChat(text);
      final note = items.single as TextChatMessage;
      expect(
        editTextNote(text, note.start, note.end, 'changed'),
        '---\ntype: audio\n---\nchanged\n',
      );
    });
  });

  group('rename and delete', () {
    test('rename touches only the embed target', () {
      const text = '---\ntype: audio\n---\n![](assets/a.wav)\n> kept\n';
      final clip = parseAudioClips(text).single;
      expect(
        renameAudioClipTarget(text, clip, 'assets/b.wav'),
        '---\ntype: audio\n---\n![](assets/b.wav)\n> kept\n',
      );
    });

    test('delete removes the vocal and its description', () {
      const text = '---\ntype: audio\n---\n![](assets/a.wav)\n> gone\nhello\n';
      final clip = parseAudioClips(text).single;
      expect(removeAudioMessage(text, clip), '---\ntype: audio\n---\nhello\n');
    });

    test('appendAudioClip still appends in the link format', () {
      const text = '---\ntype: audio\n---\n';
      expect(
        appendAudioClip(text, 'assets/b.wav', linkType: LinkType.wikilink),
        '$text![[assets/b.wav]]\n',
      );
    });
  });
}
