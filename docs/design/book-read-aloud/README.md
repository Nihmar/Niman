# Book read aloud — the screens, and the decisions

The mockups #1276 was agreed against (2026-11-13), before any code: a book
read aloud on an Android phone, in `html/`. The player's page works: the
sentence spoken is marked and moves on by itself, and pause, the previous
and next paragraph and the speed answer as they would. They are drawn in a
plain light palette, not one of `lib/src/ui/theme/niman.dart`'s, with
Literata for the book; where a mockup and the app disagree, the app is what
ships. How the reader works is
[docs/records/epub-reader.md](../../records/epub-reader.md).

| Screen | Mockup |
|---|---|
| Starting: the speaker on the book's row reads from the paragraph at the top of the view; a long-press on a paragraph offers *Read aloud from here* | [1-Start](html/1-Start.html) |
| Reading: the player's bar in the book's row's place, the sentence spoken marked and followed | [2-Playing](html/2-Playing.html) |
| Scrolled away by hand: the voice goes on, *Back to the voice* brings the view to it | [3-Away](html/3-Away.html) |
| The voice and the speed, in a sheet | [4-Voice](html/4-Voice.html) |
| The screen off: the media notification and the lock screen's controls | [5-Lock](html/5-Lock.html) |
| No voice for the book's language | [6-NoVoice](html/6-NoVoice.html) |

## Decided with them

- **Android only, for now**, as a decision: iOS and macOS
  (AVSpeechSynthesizer), Windows (the system's speech API) and Linux
  (speech-dispatcher) all have an engine, and may get read aloud
  **later**. Until then the control does not show there, and
  `docs/user/platforms.md` says so.
- **The system's engine, not TalkBack**: `android.speech.tts.TextToSpeech`,
  the engine TalkBack speaks with. TalkBack stays the user's own, on or
  off; with it on, the player's controls are labelled like any other. No
  library is added and Niman downloads no voice.
- **Two ways in**: the speaker on the book's row, from the paragraph at the
  top of the view, and a long-press on a paragraph, from that one.
- **The player takes the book's row's place** while it speaks: stop,
  previous and next **paragraph**, play and pause, the speed (0.5×–2×) and
  the voice. Stop closes it and brings the row back.
- **The sentence spoken is marked and followed.** Scrolling by hand stops
  the following, not the voice; *Back to the voice* brings the view back.
- **The voice follows the book's language** (`dc:language`), the device's
  default without one. The sheet lists the language's voices with a sample
  of each, and leads to Android's text-to-speech settings; with no voice
  for the language, a dialog says so and offers to install one or to read
  with the default voice.
- **What is spoken is the chapter's text**: headings, paragraphs, list
  items, quotes. Images, rules and footnote marks are skipped, a link reads
  as its text. It goes to the engine a sentence at a time, which is what a
  pause, a skip and the mark work by.
- **Pause is a stop that keeps the sentence**: Android's engine has no
  pause, so play says that sentence again.
- **A chapter's end goes on into the next**; the book's end stops.
- **The reading position saved is the one spoken.**
- **It goes on with the screen off and in the background**, under a media
  notification and the lock screen's controls (a `mediaPlayback`
  foreground service). A call, another app's audio and unplugged
  headphones pause it, and after a call it does not resume by itself.
