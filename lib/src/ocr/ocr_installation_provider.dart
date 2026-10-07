import 'dart:async';
import 'dart:isolate';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/resume_observer.dart';
import 'package:niman/src/ocr/ocr_engine_build.dart';
import 'package:niman/src/ocr/ocr_engine_locator.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The installation's OCR engine, languages and settings, shared by the
/// settings page and the Recognize command. Kept under `ocr/` in the app
/// support folder.
final ocrInstallationProvider = Provider<OcrInstallation>((ref) {
  final installation = OcrInstallation(
    directory: () async =>
        p.join((await getApplicationSupportDirectory()).path, 'ocr'),
    build: ocrEngineBuildFor(),
    // Opening a library is disk I/O, and a slow one on a phone.
    findInstalled: () => Isolate.run(findInstalledOcrEngine),
  );
  unawaited(installation.load());
  // Back in the foreground: pick up the downloads the freeze cut off.
  final observer = ResumeObserver(
    () => unawaited(installation.resumeInterrupted()),
  );
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
    installation.dispose();
  });
  return installation;
});
