import 'dart:ffi';

import 'package:niman/src/core/download/downloadable.dart';

/// One published build of the OCR engine (scripts/ocr-engine.sh, released
/// by the ocr-engine workflow on a prerelease tag): a single shared
/// library for one platform and ABI.
final class OcrEngineBuild implements Downloadable {
  /// The build for [target], [bytes] long, hashing to [sha256].
  const new(this.target, {required this.bytes, required this.sha256});

  /// The release tag the files are published on.
  static const String release = 'ocr-engine-2';

  /// The Tesseract version they hold.
  static const String version = '5.5.3';

  /// `linux-x64`, `android-arm64-v8a`, `android-x86_64`, `windows-x64`.
  final String target;

  @override
  final int bytes;

  @override
  final String sha256;

  String get _file =>
      'niman-ocr-$target.${target.startsWith('windows') ? 'dll' : 'so'}';

  @override
  String get id => 'engine';

  /// Under the release's own folder: a new engine never overwrites a
  /// library a running process may hold.
  @override
  String get fileName => 'engine/$release/$_file';

  @override
  Uri get uri => Uri.parse(
    'https://github.com/Nihmar/Niman/releases/download/$release/$_file',
  );

  @override
  String toString() => 'engine $target';
}

/// Every published build.
const List<OcrEngineBuild> ocrEngineBuilds = [
  OcrEngineBuild(
    'linux-x64',
    bytes: 2889080,
    sha256: 'e5a8149b1c724687ecc6579b717f7fdaffb835b97a59846e2c62d1ae21740632',
  ),
  OcrEngineBuild(
    'android-arm64-v8a',
    bytes: 2347896,
    sha256: 'ff4d6abc34130b592ebfb117e5d97da361004082478fd90f329a0276c45e5c4c',
  ),
  OcrEngineBuild(
    'android-x86_64',
    bytes: 2683776,
    sha256: '812063feb4fafadd6c8eaf8bdf36aac3f98df8a3d4c4116d00eed9910f9c5df2',
  ),
  OcrEngineBuild(
    'windows-x64',
    bytes: 3950592,
    sha256: 'c6c0e30b741184972c739eb478d5fe6037296a39fbd95d84be585e6c84f5f0b8',
  ),
];

/// The build this process can load, or null where none is published.
OcrEngineBuild? ocrEngineBuildFor([Abi? abi]) {
  final target = switch (abi ?? Abi.current()) {
    Abi.linuxX64 => 'linux-x64',
    Abi.androidArm64 => 'android-arm64-v8a',
    Abi.androidX64 => 'android-x86_64',
    Abi.windowsX64 => 'windows-x64',
    _ => null,
  };
  for (final build in ocrEngineBuilds) {
    if (build.target == target) return build;
  }
  return null;
}
