# niman_apple

Niman's native code for macOS and iOS, in one Swift source shared by both
(`darwin/`), as `docs/records/apple-platforms.md` plans it.

| Channel | Method | What it does |
|---|---|---|
| `niman/audio` | `decodeToWav` `{source, target}` | Decodes any audio AVFoundation reads (m4a, mp3, aac, caf, aiff, flac…) to a PCM16 WAV at the source's own rate and channels. The app's Dart resampler takes it to whisper's 16 kHz mono, as it does a recorded WAV. Replaces FFmpeg on Apple. |
| `niman/pdf` | `print` `{htmlPath, pdfPath, paper}`, `cancel` | macOS: WebKit lays the export's HTML out off screen and its print operation saves a paginated PDF with real text — A4 with an 18 mm margin, or a 16:9 sheet a slide. As Android's `PdfBridge.kt`. |
| `niman/clipboard` | `readHtml` | macOS: the pasteboard's HTML and the page it came from — `public.html` and `org.chromium.source-url` from Chrome and Edge, `public.html` from Firefox, a web archive's main resource from Safari — for Paste as Markdown. As Linux's `clipboard_html.cc`. |
| `niman/page_reader` | `read` `{url, timeoutMs, maxCharacters}`, `cancel` | macOS: an offscreen WebKit view runs the page, waits for its text to stop growing, and answers its `outerHTML`. As Android's `PageReaderBridge.kt`. |
