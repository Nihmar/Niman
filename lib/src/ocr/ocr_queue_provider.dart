import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/ocr/ocr_installation_provider.dart';
import 'package:niman/src/ocr/ocr_queue.dart';

/// The installation's recognition jobs, shared by the files' bars, the
/// phone's strip and the shell's notification (#594).
final ocrQueueProvider = Provider<OcrQueue>((ref) {
  final queue = OcrQueue(installation: ref.watch(ocrInstallationProvider));
  ref.onDispose(queue.dispose);
  return queue;
});
