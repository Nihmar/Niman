/// Printing an exported page to PDF (#63).
///
/// The page is already HTML, so the machine's own browser engine prints
/// it: Edge on Windows, a Chromium-family browser on Linux. Android has no
/// such engine to run — its WebView prints instead, through the
/// `niman/pdf` channel (`WebViewPdfPrinter` in `pdf_webview.dart`). A
/// machine with neither reports [PdfNoEngine] and the caller draws the
/// note instead.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// How a print ended.
sealed class PdfOutcome {
  const new();
}

/// The PDF is written.
final class PdfPrinted extends PdfOutcome {
  /// Creates the outcome.
  const new();
}

/// No engine was found on this machine.
final class PdfNoEngine extends PdfOutcome {
  /// Creates the outcome.
  const new();
}

/// The engine was there and the print failed.
final class PdfFailed extends PdfOutcome {
  /// Creates the outcome, saying why.
  const new(this.message);

  /// What went wrong, for the message the user sees.
  final String message;
}

/// What a note's PDF is doing, for the dialog that shows it (#63).
enum PdfExportStage {
  /// A browser engine (or Android's WebView) is printing the page.
  printing,

  /// No engine answered: the note is being drawn page by page.
  drawing,
}

/// One report from a running PDF export.
final class PdfExportProgress {
  /// Creates a report: [done] of [total] pages drawn ([total] is 0 while
  /// the engine prints, which has no page count to give).
  const new({required this.stage, this.done = 0, this.total = 0});

  /// What the export is doing.
  final PdfExportStage stage;

  /// Pages drawn so far.
  final int done;

  /// Pages the note makes; 0 until the layout is done.
  final int total;
}

/// The export was cancelled by the user (the dialog's own button): no file
/// is written, and nothing is reported as a failure.
final class PdfExportCancelled implements Exception {
  /// Creates the cancellation.
  const new();

  @override
  String toString() => 'PDF export cancelled';
}

/// What prints a page.
abstract interface class PdfPrinter {
  /// Prints the page at [htmlPath] into [pdfPath]; whether it worked is
  /// the [PdfOutcome].
  Future<PdfOutcome> print(String htmlPath, String pdfPath);

  /// Whether this machine has anything to print with, asked before the
  /// page is built: with nothing, the note is drawn instead, and its HTML
  /// is never needed.
  Future<bool> get canPrint;
}

/// What running a program answered.
typedef ProcessAnswer = ({int exit, String stdout});

/// A process that did not finish in time, and was killed.
final class ProcessTimedOut implements Exception {
  /// Creates the timeout.
  const new();

  @override
  String toString() => 'the process did not finish';
}

/// Runs a program with [args], answering its exit code and output.
///
/// A program that outlives [timeout] is killed — politely first, then not —
/// and [ProcessTimedOut] is thrown: a hung headless browser must not hold
/// the machine, not just the export. The runner owns the timeout, because
/// only it holds the process to kill.
typedef ProcessRunner = Future<ProcessAnswer> Function(
  String exe,
  List<String> args, {
  Duration? timeout,
});

/// The size of the file at [path], or null when it is not there.
typedef FileSize = Future<int?> Function(String path);

/// How much of a program's output is kept. None of it is read — only the
/// exit code matters — but the pipe must be drained, or a talkative engine
/// blocks on it; the rest is read and dropped (P3).
const int processOutputLimit = 64 * 1024;

/// Runs [exe] with [args], through `dart:io`.
Future<ProcessAnswer> runProcess(
  String exe,
  List<String> args, {
  Duration? timeout,
}) async {
  final process = await Process.start(exe, args);
  final stdoutDone = collectProcessOutput(process.stdout);
  final stderrDone = process.stderr.drain<void>();
  try {
    final exit = timeout == null
        ? await process.exitCode
        : await process.exitCode.timeout(timeout);
    final stdout = await stdoutDone;
    await stderrDone;
    return (exit: exit, stdout: stdout);
  } on TimeoutException {
    await _kill(process);
    // The drains end when the process's pipes do; a dying process's output
    // is not the timeout's problem.
    unawaited(stdoutDone.then<void>((_) {}, onError: (Object _) {}));
    unawaited(stderrDone.then<void>((_) {}, onError: (Object _) {}));
    throw const ProcessTimedOut();
  }
}

/// [stream]'s text, at most [processOutputLimit] characters: everything is
/// read, so the writer never waits on a full pipe, but only the head is
/// kept. The runner asks for the exit code and the file size; the output
/// exists for a log line and nothing else.
Future<String> collectProcessOutput(Stream<List<int>> stream) async {
  final out = StringBuffer();
  await for (final text in stream.transform(utf8.decoder)) {
    if (out.length >= processOutputLimit) continue;
    final room = processOutputLimit - out.length;
    out.write(text.length <= room ? text : text.substring(0, room));
  }
  return out.toString();
}

/// Stops [process]: its own signal first, then SIGKILL when it will not go.
Future<void> _kill(Process process) async {
  process.kill();
  try {
    await process.exitCode.timeout(const Duration(seconds: 2));
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
  }
}

/// The size of the file at [path], or null when it is not there; a
/// directory answers null.
Future<int?> fileSize(String path) async {
  try {
    return await File(path).length();
  } on FileSystemException {
    return null;
  }
}

/// The Chromium-family executables a Linux desktop may have, in the order
/// they are looked for.
const List<String> chromiumExecutables = <String>[
  'chromium',
  'chromium-browser',
  'google-chrome',
  'google-chrome-stable',
  'microsoft-edge',
  'brave-browser',
];

/// The flags every engine prints headless with.
List<String> printFlags(String pdfPath) => <String>[
  '--headless=new',
  '--disable-gpu',
  // The page is one local file and its pictures are `file:` URLs into the
  // library: without this a Chromium treats every file as its own opaque
  // origin and refuses to load them.
  '--allow-file-access-from-files',
  '--no-pdf-header-footer',
  '--print-to-pdf=$pdfPath',
];

/// The desktop engine that prints, or null when this machine has none.
///
/// Android has no desktop engine: its WebView prints through the
/// `niman/pdf` channel instead, and so is not searched for here.
///
/// [isWindows] and [isLinux] default to the platform, [path] to `PATH`'s
/// directories, [roots] to the Windows install folders, and [run] and
/// [isFile] to the real ones — every one of them a seam a test can hand
/// in.
Future<String?> findPdfEngine({
  bool? isWindows,
  bool? isLinux,
  List<String>? path,
  List<String?>? roots,
  ProcessRunner run = runProcess,
  Future<bool> Function(String path)? isFile,
  Future<int?> Function(String path) size = fileSize,
}) async {
  final exists = isFile ?? ((path) async => await size(path) != null);
  if (isWindows ?? Platform.isWindows) {
    return await _edgeFromRegistry(run: run, isFile: exists) ??
        await _edgeFromFolders(roots: roots ?? _windowsRoots(), isFile: exists);
  }
  if (isLinux ?? Platform.isLinux) {
    return await _firstOnPath(
      chromiumExecutables,
      path ?? _pathDirectories(),
      exists,
    );
  }
  return null;
}

/// The first of [names] that is a file in one of [dirs].
Future<String?> _firstOnPath(
  List<String> names,
  List<String> dirs,
  Future<bool> Function(String path) isFile,
) async {
  for (final name in names) {
    for (final dir in dirs) {
      final candidate = p.join(dir, name);
      if (await isFile(candidate)) return candidate;
    }
  }
  return null;
}

/// Edge's path, through the shell's own App Paths key.
Future<String?> _edgeFromRegistry({
  required ProcessRunner run,
  required Future<bool> Function(String path) isFile,
}) async {
  const key =
      r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe';
  try {
    final answer = await run(
      'reg',
      <String>['query', key, '/ve'],
      // A hung `reg.exe` must not hold the folder export open before its
      // chooser even appears; the install folders are the fallback (P4).
      timeout: const Duration(seconds: 5),
    );
    if (answer.exit != 0) return null;
    for (final line in answer.stdout.split('\n')) {
      final mark = line.indexOf('REG_SZ');
      if (mark < 0) continue;
      final path = line.substring(mark + 'REG_SZ'.length).trim();
      if (path.isNotEmpty && await isFile(path)) return path;
    }
  } on Object {
    // No registry to ask, or no `reg`: the folders below are the answer.
  }
  return null;
}

/// Edge under the folders it installs into.
Future<String?> _edgeFromFolders({
  required List<String?> roots,
  required Future<bool> Function(String path) isFile,
}) async {
  const subfolders = <String>[
    r'Microsoft\Edge\Application',
    r'Microsoft\Edge Beta\Application',
    r'Microsoft\Edge Dev\Application',
  ];
  for (final root in roots) {
    if (root == null || root.isEmpty) continue;
    for (final subfolder in subfolders) {
      // Windows paths, whatever host the test runs on.
      final candidate = p.windows.join(root, subfolder, 'msedge.exe');
      if (await isFile(candidate)) return candidate;
    }
  }
  return null;
}

/// `PATH`'s directories.
List<String> _pathDirectories() => (Platform.environment['PATH'] ?? '')
    .split(Platform.isWindows ? ';' : ':')
    .where((dir) => dir.isNotEmpty)
    .toList();

/// Where Edge installs on Windows.
List<String?> _windowsRoots() => <String?>[
  Platform.environment['ProgramFiles(x86)'],
  Platform.environment['ProgramFiles'],
  Platform.environment['LOCALAPPDATA'],
];

/// Prints through the machine's browser engine.
final class ProcessPdfPrinter implements PdfPrinter {
  /// Prints with [engine] (found per platform by default), running
  /// processes with [run], and checking the written file with [size].
  new({
    this.engine,
    this.findEngine,
    this.run = runProcess,
    this.size = fileSize,
    this.timeout = const Duration(minutes: 2),
  });

  /// The engine's path; null asks [findEngine], or [findPdfEngine].
  final String? engine;

  /// The platform's own discovery; null runs [findPdfEngine] with this
  /// printer's [run] and [size].
  final Future<String?> Function()? findEngine;

  /// Runs the engine.
  final ProcessRunner run;

  /// Reads the written file's size.
  final FileSize size;

  /// How long an engine may take before it is called failed: a hung
  /// headless browser must not hold the export open.
  final Duration timeout;

  /// The engine already found, kept: on Windows discovery runs `reg.exe`,
  /// and both [canPrint] and [print] ask (L4).
  String? _found;
  bool _searched = false;

  Future<String?> _resolveEngine() async {
    final known = engine;
    if (known != null) return known;
    if (!_searched) {
      _searched = true;
      _found = await (findEngine ?? _findEngine)();
    }
    return _found;
  }

  @override
  Future<bool> get canPrint async => await _resolveEngine() != null;

  @override
  Future<PdfOutcome> print(String htmlPath, String pdfPath) async {
    final exe = await _resolveEngine();
    if (exe == null) return const PdfNoEngine();
    final ProcessAnswer answer;
    try {
      answer = await run(exe, <String>[
        ...printFlags(pdfPath),
        Uri.file(htmlPath).toString(),
      ], timeout: timeout);
    } on ProcessTimedOut {
      return const PdfFailed('the engine did not finish');
    } on Object catch (error) {
      return PdfFailed('$error');
    }
    if (answer.exit != 0) {
      return PdfFailed('the engine exited with ${answer.exit}');
    }
    final written = await size(pdfPath);
    if (written == null) return const PdfFailed('no PDF was written');
    if (written == 0) return const PdfFailed('the PDF is empty');
    return const PdfPrinted();
  }

  /// The default discovery, with this printer's own process and file
  /// seams.
  Future<String?> _findEngine() => findPdfEngine(run: run, size: size);
}
