// Issue #56: the audio note's body format — clips are audio embeds, one
// per line, in the library's link format (Markdown or wikilink).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/ui/kinds/audio_clip.dart';
import 'package:niman/src/ui/kinds/audio_note.dart';
import 'package:niman/src/ui/kinds/audio_parser.dart';

void main() {
  group('isAudioTarget', () {
    test('audio extensions count, images do not', () {
      expect(isAudioTarget('assets/a.wav'), isTrue);
      expect(isAudioTarget('assets/A.MP3'), isTrue);
      expect(isAudioTarget('clips/b.m4a'), isTrue);
      expect(isAudioTarget('clips/c.ogg'), isTrue);
      expect(isAudioTarget('clips/d.opus'), isTrue);
      expect(isAudioTarget('assets/pic.png'), isFalse);
      expect(isAudioTarget('note.md'), isFalse);
      expect(isAudioTarget('no-extension'), isFalse);
    });
  });

  group('parseAudioClips', () {
    test('reads Markdown audio embeds in order, skipping images', () {
      const text =
          '---\ntype: audio\n---\n'
          '![](assets/a.wav)\n'
          '![](assets/pic.png)\n'
          '![](clips/b.mp3)\n';
      final clips = parseAudioClips(text);
      expect(clips.map((c) => c.target), ['assets/a.wav', 'clips/b.mp3']);
      expect(clips.first, isA<AudioClip>());
      expect(clips.first.name, 'a.wav');
    });

    test('reads wikilink embeds, skipping plain links and images', () {
      const text =
          '---\ntype: audio\n---\n'
          '![[assets/a.wav]]\n'
          '[[assets/b.wav]]\n'
          '![[assets/pic.png]]\n';
      final clips = parseAudioClips(text);
      expect(clips.map((c) => c.target), ['assets/a.wav']);
    });

    test('frontmatter and code fences hold no clips', () {
      const text =
          '---\ntype: audio\n---\n'
          '```\n![](assets/a.wav)\n```\n';
      expect(parseAudioClips(text), isEmpty);
    });

    test('a plain note parses to no clips', () {
      expect(parseAudioClips('just text\n'), isEmpty);
    });
  });

  group('appendAudioClip', () {
    test('appends in the library link format, keeping bytes', () {
      const text = '---\ntype: audio\n---\n';
      expect(
        appendAudioClip(text, 'assets/b.wav', linkType: LinkType.wikilink),
        '$text![[assets/b.wav]]\n',
      );
      expect(
        appendAudioClip(text, 'assets/b.wav', linkType: LinkType.markdown),
        '$text![](assets/b.wav)\n',
      );
    });

    test('every bubble is its own blank-line separated paragraph', () {
      const text = '---\ntype: audio\n---\n![[assets/a.wav]]\n';
      expect(
        appendAudioClip(text, 'assets/b.wav', linkType: LinkType.wikilink),
        '$text\n![[assets/b.wav]]\n',
      );
    });
  });

  group('removeAudioClip', () {
    test('removes a Markdown embed line', () {
      const text =
          '---\ntype: audio\n---\n![](assets/a.wav)\n![](assets/b.wav)\n';
      final clips = parseAudioClips(text);
      expect(
        removeAudioClip(text, clips.first),
        '---\ntype: audio\n---\n![](assets/b.wav)\n',
      );
    });

    test('removes a wikilink embed line', () {
      const text = '---\ntype: audio\n---\n![[assets/a.wav]]\n';
      final clips = parseAudioClips(text);
      expect(removeAudioClip(text, clips.single), '---\ntype: audio\n---\n');
    });
  });

  group('audio note frontmatter', () {
    test('type: audio reads as the audio kind', () {
      expect(frontmatterTypeOf('---\ntype: audio\n---\n'), 'audio');
      expect(audioNoteContent(), '---\ntype: audio\n---\n');
    });
  });
}
