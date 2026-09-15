# Audio transcription (whisper_ggml)

On-device speech-to-text for audio notes: the clip menu's "Transcribe"
action runs [whisper_ggml](https://pub.dev/packages/whisper_ggml)
(whisper.cpp 1.9.1, CPU backend) and writes the text into the clip's
description (the `> ` lines after the embed, see
`lib/src/ui/kinds/audio_chat.dart`). Work in progress on
`feat/whisper-transcription`.

## Models and settings (phase 1)

Code: `lib/src/transcription/` (logic) and `lib/src/ui/transcription/`
(settings section, models page).

| File | Role |
|------|------|
| `transcription_model.dart` | The catalog: multilingual tiny, base, small, medium, large-v3 with their published sizes. Android hides large-v3 and flags medium as slow. |
| `model_files.dart` | Disk state. A model is installed when `<model dir>/ggml-<name>.bin` exists; a `<file>.part` is an interrupted download, kept for resuming. |
| `model_download.dart` | One download attempt in a spawned isolate: HTTP stream to `<file>.part` (resumed with `Range: bytes=<size>-` when the file exists), progress every 250 ms, rename only when the byte count matches the full size, 30 s stall timeout. A failure keeps the partial file and says whether it is transient; cancel kills the isolate and removes it. |
| `model_downloader.dart` | Attempts, retries and resumes: transient failures (network, timeout, 5xx, a cut-off body) retry after 2, 5, 10, 20, 30 s from the bytes on disk; when those run out the model is paused with its bytes kept. |
| `transcription_settings.dart`, `transcription_settings_store.dart` | Default model and language, stored as `transcription.json` in the model directory (temp write + rename, off the UI isolate). |
| `transcription_models.dart` | `TranscriptionModels` (ChangeNotifier) behind `transcriptionModelsProvider`: per-model state, downloads that outlive the page, default and language. |

- **Model directory:** `WhisperController.getModelDir()`, the app support
  directory (`%APPDATA%\dev.niman\niman` on Windows). `whisper_ggml` loads
  `ggml-<name>.bin` from there by enum, so downloads must land there.
- **Settings live next to the models, not in `AppDatabase`.** They
  describe the files on this device, and the schema's next migration
  (v22) belongs to the sync work; a JSON file keeps the two independent.
- **Leaving the app mid-download (Android):** a process that is not in
  the foreground is frozen within seconds (and some vendors cut its
  network), so the connection drops. The download does not start over:
  the retry resumes from the `.part` once the app runs again, and
  `AppLifecycleListener.onResume` restarts paused downloads. It does not
  continue *while* the app is in the background; that needs a foreground
  service. Hugging Face honors `Range` through its CDN redirect (`206`
  with `Content-Range`, checked 2026-09-15).
- **Default model:** the first model to finish downloading becomes the
  default when none is set; deleting the default hands it to the smallest
  model left, or none.
- **Language:** `app` (the app's language, the default), `auto` (whisper
  detects it) or an app language id. Whisper gets ISO 639-1 codes;
  Norwegian Bokmål `nb` becomes `no`.
- **UI:** Settings → Transcription has *Model* (opens the models page)
  and *Language* (a choice dialog). The page groups Downloaded /
  Downloading / Available; tapping a downloaded row makes it the default,
  delete asks first, a failed download offers Retry, a paused one shows
  the bytes kept with Resume (and a discard button), and a download
  waiting to retry reads "Connection lost, trying again…".
- **Logs** (`[transcription]`): settings load/save time, directory scan
  (time, installed and partial sizes), download start with bytes on disk,
  headers latency and resume offset, every 10 %, each failed attempt with
  its reason and retry delay, give-up with bytes kept, total time and
  MB/s of the last attempt, cancel time, delete time and bytes freed.

## Phase 0 spike (2026-09-15)

Harness: [`tool/whisper_spike.dart`](../../tool/whisper_spike.dart). It
logs every step under `[whisper-spike]`: model download, the package's
audio conversion, a cold and a warm transcription (load time =
cold − warm), progress callbacks, real-time factor, resident memory.

```
# Desktop, unattended (exits when done)
flutter run -d windows --profile -t tool/whisper_spike.dart \
  --dart-define=SPIKE_AUDIO=<clip.wav> \
  --dart-define=SPIKE_MODELS=tiny,base --dart-define=SPIKE_LANG=it

# Phone: record (the app's RecordConfig) or pick a file, then "Avvia";
# "Copia log" copies the log
flutter run --profile -t tool/whisper_spike.dart
```

### Windows x64 (12 threads), 30 s Italian speech, 16 kHz mono WAV

| Model | Download | Cold | Warm | RTF (warm) | RSS added | Quality |
|-------|----------|------|------|------------|-----------|---------|
| tiny (74 MB) | 5.2 s | 1177 ms | 970 ms | 0.03 | ~160 MB | Misspellings ("jovedi", "paneli", "fature") |
| base (141 MB) | 8.9 s | 2492 ms | 2408 ms | 0.08 | ~300 MB | One merged word ("martediale"), otherwise exact |

Model load is 80–200 ms here once the file is in the OS cache; it is
part of the cold figure. `releaseModel` takes 20–35 ms and returns the
memory.

### Build impact

| Target | Before | After | Delta |
|--------|--------|-------|-------|
| Windows release dir | 43.7 MB | 45.1 MB | +1.4 MB (`whisper_ggml.dll` 1.3 MB) |
| Android release APK (universal) | 86.7 MB | 151.5 MB | +64.8 MB |
| Linux | — | _not built yet_ | — |

Native libraries per ABI in the APK (compressed):

| ABI | Before | After | whisper.cpp | FFmpeg (ffmpeg_kit) |
|-----|--------|-------|-------------|---------------------|
| arm64-v8a | 28.2 MB | 45.1 MB | 2.8 MB | ~14 MB |
| armeabi-v7a | 26.2 MB | 55.2 MB | 2.0 MB | ~27 MB (plain + NEON copies) |
| x86_64 | 29.6 MB | 48.0 MB | 2.9 MB | ~15 MB |

whisper.cpp itself is cheap; almost all of the growth is the FFmpeg that
`whisper_ggml` pulls in through `ffmpeg_kit_flutter_new_min`. Our flow
converts WAV clips in Dart, so FFmpeg is only useful for non-WAV
imports on Android. The package calls `FFmpegKit.execute` on every
Android transcription, so its libraries cannot simply be stripped from
the APK.

**Decision:** ship 64-bit only. `android/app/build.gradle.kts` excludes
`armeabi-v7a` at packaging (`ndk.abiFilters` is overridden by the
Flutter Gradle plugin). Release APK with whisper_ggml: **96.1 MB**
(+9.4 MB over the 86.7 MB universal APK without it). Switching recording
to 16 kHz mono is tracked separately in
[#87](https://github.com/Nihmar/Niman/issues/87).

### Findings that shape the implementation

- **Input must be 16 kHz mono/stereo PCM16 WAV.** The native side
  rejects anything else ("WAV file must be 16 kHz"). The app records
  with the `record` defaults (44.1 kHz), so every clip needs a
  conversion first. Before transcribing, the package tries ffmpeg
  (`ffmpeg_kit` on Android, `ffmpeg` from PATH on desktop) and silently
  passes the file through when that fails.
- **The package converts next to the input.** It writes
  `<audio>.wav` beside the source file, which would land inside the
  library. Always hand it a temp copy.
- **Errors are swallowed.** `WhisperController.transcribe` returns
  `null` and only `debugPrint`s the reason; a bad WAV still loads the
  model first (+140 MB RSS, then nothing). Validate the format before
  calling.
- **Model location is fixed:** `<app support dir>/ggml-<name>.bin`
  (`%APPDATA%\dev.niman\niman` on Windows). `transcribe` takes the
  `WhisperModel` enum, not a path, so our downloader must write there.
  `downloadModel` buffers the whole file in memory and has no progress,
  so we stream our own download (`.part` + rename). Hugging Face
  redirects once; `HttpClient` follows it, `contentLength` is set.
- **Progress is coarse:** 2–3 `onProgress` callbacks per 30 s clip.
  The UI should estimate from clip length × measured RTF.
- **No cancellation.** No abort callback is wired in the native request;
  "Cancel" can only discard the result.
- **Android build needs two Gradle fixes** (in `android/`): NDK
  29.0.13113456 (the plugin's version) and compiling the `whisper_ggml`
  module against the app's `compileSdk`, because
  `ffmpeg_kit_flutter_new_min` requires compileSdk 35+ and the plugin
  pins 34.
- **`ffmpeg_kit_flutter_new_min` applies the Kotlin Gradle Plugin**,
  joining `flutter_timezone` and `home_widget` in Flutter's "future
  versions will fail to build" warning.
- **Desktop x64 builds target AVX2** (`WHISPER_GGML_AVX2`, on by
  default).

### Still to measure

- Timings and memory on a mid-range Android phone (tiny/base/small).
- Linux x64 build and run.
