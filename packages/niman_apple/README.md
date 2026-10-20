# niman_apple

Niman's native code for macOS and iOS, in one Swift source shared by both
(`darwin/`), as `docs/records/apple-platforms.md` plans it.

| Channel | Method | What it does |
|---|---|---|
| `niman/audio` | `decodeToWav` `{source, target}` | Decodes any audio AVFoundation reads (m4a, mp3, aac, caf, aiff, flac…) to a PCM16 WAV at the source's own rate and channels. The app's Dart resampler takes it to whisper's 16 kHz mono, as it does a recorded WAV. Replaces FFmpeg on Apple. |
