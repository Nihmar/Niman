# ffmpeg_kit_flutter_new_min, as Niman ships it

A copy of [`ffmpeg_kit_flutter_new_min`](https://pub.dev/packages/ffmpeg_kit_flutter_new_min)
2.1.0 (LGPL-3.0, see `LICENSE`), which `whisper_ggml` depends on, put in
place of the published package by `dependency_overrides` in the app's
`pubspec.yaml`.

Why: FFmpeg is left out of the Apple builds (docs/records/apple-platforms.md).
Its iOS and macOS frameworks weigh 76 MB, and 2.1.0's iOS ones carry no
arm64 slice for the simulator, so nothing linked there. On Apple the app
decodes other formats with AVFoundation (`packages/niman_apple`) and hands
whisper a 16 kHz mono WAV it never has to convert.

What changed from the published package, and nothing else (each change is
marked `Niman:` in the source):

- `pubspec.yaml`: the `ios` and `macos` platforms are removed, so the
  plugin registers on Android only; `publish_to: none`.
- `lib/ffmpeg_kit.dart`: on iOS and macOS, `executeWithArguments` returns
  a session that reports a failure without calling the native side.
- `analysis_options.yaml`, which keeps the app's lint set off this code.
- This file.

The `example/` and `scripts/` folders and the `ios/` and `macos/` ones are
not copied. Android is unchanged: the same Dart wrapper and Kotlin plugin,
which fetch `com.antonkarpenko:ffmpeg-kit-min:1.0.3` from Maven Central.
