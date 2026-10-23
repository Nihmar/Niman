/// Running a program to its end, or killing it when it will not get there.
///
/// The PDF export prints with the machine's browser engine (#63), and the
/// web capture asks the same engine for a page's DOM (#531): both run a
/// headless browser that may hang, and both need its pipes drained so it
/// never blocks on a full one.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
/// only it holds the process to kill. [outputLimit] is how much of the
/// output is kept, [processOutputLimit] when null.
typedef ProcessRunner = Future<ProcessAnswer> Function(
  String exe,
  List<String> args, {
  Duration? timeout,
  int? outputLimit,
});

/// How much of a program's output is kept unless the caller asks for more.
/// The pipe is always drained, or a talkative engine blocks on it; past the
/// limit the output is read and dropped (P3). A print reads only the exit
/// code, so its output exists for a log line and nothing else.
const int processOutputLimit = 64 * 1024;

/// Runs [exe] with [args], through `dart:io`, in [environment] when one is
/// given — whole, in place of this process's own — and in this process's
/// own environment otherwise.
Future<ProcessAnswer> runProcess(
  String exe,
  List<String> args, {
  Duration? timeout,
  int? outputLimit,
  Map<String, String>? environment,
}) async {
  final process = await Process.start(
    exe,
    args,
    environment: environment,
    includeParentEnvironment: environment == null,
  );
  final stdoutDone = collectProcessOutput(
    process.stdout,
    limit: outputLimit ?? processOutputLimit,
  );
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

/// [stream]'s text, at most [limit] characters: everything is read, so the
/// writer never waits on a full pipe, but only the head is kept.
Future<String> collectProcessOutput(
  Stream<List<int>> stream, {
  int limit = processOutputLimit,
}) async {
  final out = StringBuffer();
  await for (final text in stream.transform(utf8.decoder)) {
    if (out.length >= limit) continue;
    final room = limit - out.length;
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

/// Runs the browser engine — the PDF export's printer, the web capture's
/// reader — as [runProcess] does, in [engineEnvironment].
Future<ProcessAnswer> runEngine(
  String exe,
  List<String> args, {
  Duration? timeout,
  int? outputLimit,
}) => runProcess(
  exe,
  args,
  timeout: timeout,
  outputLimit: outputLimit,
  environment: engineEnvironment(Platform.environment),
);

/// [environment] without Windows' compatibility layer (`__COMPAT_LAYER`).
///
/// Windows hands its compatibility shims down to the programs a process
/// starts through that variable — it carried `DetectorsAppHealth` here.
/// Edge refuses to run under one: it starts itself again without it
/// (`--edge-skip-compat-layer-relaunch`) and exits at once, so the process
/// the export started ends before the PDF is written, and the copy it
/// started writes its `--dump-dom` to an output that is not ours. Every
/// export then read "no PDF" and drew pictures; every capture read an empty
/// page (#1176). Started without the layer, Edge runs in the process that
/// was started. Windows spells its variables in any case.
Map<String, String> engineEnvironment(Map<String, String> environment) => {
  for (final MapEntry(:key, :value) in environment.entries)
    if (key.toUpperCase() != '__COMPAT_LAYER') key: value,
};
