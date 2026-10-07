import 'dart:ffi';
import 'dart:io';

import 'package:niman/src/ocr/tesseract_bindings.dart';

/// Where the engine comes from.
enum OcrEngineSource {
  /// Shipped inside the package: a store build that may not download
  /// code puts it there.
  bundled,

  /// The distribution's own libtesseract (Linux).
  system,

  /// The library the app downloaded.
  downloaded,
}

/// An engine to open: the name or path `DynamicLibrary.open` takes,
/// where it comes from, and its version.
typedef OcrEngineLibrary = ({
  String name,
  OcrEngineSource source,
  String version,
});

/// The library names a package may bundle the engine under.
const List<String> bundledOcrEngineNames = ['libniman_ocr.so', 'niman_ocr.dll'];

/// The distribution libraries tried on Linux, newest first.
const List<String> systemOcrEngineNames = [
  'libtesseract.so.5',
  'libtesseract.so.4',
];

/// The engine already on this device, without a download: a library
/// bundled in the package ([bundledOcrEngineNames]), else on Linux the
/// distribution's ([systemOcrEngineNames]); null when none opens or none
/// is recent enough.
///
/// It opens libraries, so it runs on a worker isolate. The downloaded
/// engine is not probed here: once loaded, Windows locks the file until
/// the app exits, and the settings page must still be able to delete it.
///
/// [open] and [linux] are seams for tests; a name that fails to open is
/// skipped, a missing library being the common case.
OcrEngineLibrary? findInstalledOcrEngine({
  DynamicLibrary Function(String name) open = DynamicLibrary.open,
  bool? linux,
}) {
  final candidates = [
    for (final name in bundledOcrEngineNames) (name, OcrEngineSource.bundled),
    if (linux ?? Platform.isLinux)
      for (final name in systemOcrEngineNames) (name, OcrEngineSource.system),
  ];
  for (final (name, source) in candidates) {
    final api = openOcrEngine(name, open: open);
    if (api == null) continue;
    return (name: name, source: source, version: api.versionString());
  }
  return null;
}

/// The engine at [name] (a library name or an absolute path), bound;
/// null when it does not open, is not Tesseract, or is older than 4.1
/// (the LSTM models need it).
TesseractBindings? openOcrEngine(
  String name, {
  DynamicLibrary Function(String name) open = DynamicLibrary.open,
}) {
  final TesseractBindings api;
  try {
    api = TesseractBindings(open(name));
  } on Object {
    return null;
  }
  return ocrEngineVersionSupported(api.versionString()) ? api : null;
}

/// Whether Tesseract [version] (`5.5.3`, `4.1.1-rc2`) reads LSTM models:
/// 4.1 or later.
bool ocrEngineVersionSupported(String version) {
  final match = RegExp(r'^(\d+)\.(\d+)').firstMatch(version);
  if (match == null) return false;
  final major = int.parse(match[1]!);
  final minor = int.parse(match[2]!);
  return major > 4 || (major == 4 && minor >= 1);
}
