/// Printing an exported page to PDF (#63).
///
/// The page is already HTML, so the machine's own browser engine prints
/// it: Edge on Windows, a Chromium-family browser on Linux, the WebView on
/// Android. A platform with none of those reports [PdfNoEngine] — the
/// caller tells the user, and Linux has the raster fallback to lean on.
library;

import 'dart:async';
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

/// What prints a page.
abstract interface class PdfPrinter {
  /// Prints the page at [htmlPath] into [pdfPath]; whether it worked is
  /// the [PdfOutcome].
  Future<PdfOutcome> print(String htmlPath, String pdfPath);
}

/// What running a program answered.
typedef ProcessAnswer = ({int exit, String stdout});

/// Runs a program with [args], answering its exit code and output.
typedef ProcessRunner = Future<ProcessAnswer> Function(
  String exe,
  List<String> args,
);

/// The size of the file at [path], or null when it is not there.
typedef FileSize = Future<int?> Function(String path);

/// Runs [exe] with [args], through `dart:io`.
Future<ProcessAnswer> runProcess(String exe, List<String> args) async {
  final result = await Process.run(exe, args);
  return (exit: result.exitCode, stdout: '${result.stdout}');
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
  '--no-pdf-header-footer',
  '--print-to-pdf=$pdfPath',
];

/// The desktop engine that prints, or null when this machine has none.
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
    final answer = await run('reg', <String>['query', key, '/ve']);
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
  const new({
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

  @override
  Future<PdfOutcome> print(String htmlPath, String pdfPath) async {
    final exe = engine ?? await (findEngine ?? _findEngine)();
    if (exe == null) return const PdfNoEngine();
    final ProcessAnswer answer;
    try {
      answer = await run(exe, <String>[
        ...printFlags(pdfPath),
        Uri.file(htmlPath).toString(),
      ]).timeout(timeout);
    } on TimeoutException {
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
