// What a running Niman holds, by owner (#1193, `docs/dev/memory.md`).
//
// Connects to the VM service of a profile build and prints, at the moment it
// runs:
//
// * the process's memory as the VM attributes it (`getProcessMemoryUsage`):
//   the Dart heaps, the VM's own, and what the rest of the process mapped —
//   the engine, the GPU driver, SQLite — under one figure the VM cannot split;
// * each isolate group's heap after a collection, new and old space and the
//   external memory its objects own — the isolates of a group share it: the
//   UI isolate with every `Isolate.run` it spawned, the index and search
//   connections' drift isolates;
// * the classes holding most of each heap.
//
// Run it beside the app's log: every action's line ends with the resident set
// (`rss … MB`), and this says what that figure is made of.
//
//   flutter build windows --profile --dart-define=APP_CHANNEL=testing
//   set FLUTTER_ENGINE_SWITCHES=2
//   set FLUTTER_ENGINE_SWITCH_1=vm-service-port=8181
//   set FLUTTER_ENGINE_SWITCH_2=disable-service-auth-codes
//   build\windows\x64\runner\Profile\niman.exe
//   dart run --packages=.dart_tool/package_config.json tool/memory_report.dart
//
// Options: `--uri ws://127.0.0.1:8181/ws` (the default), `--top 15` classes
// per isolate, `--label "library open"` printed in the heading.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final VmService service;
  try {
    service = await vmServiceConnectUri(options.uri);
  } on Object catch (error) {
    stderr.writeln('no VM service at ${options.uri}: $error');
    exitCode = 1;
    return;
  }
  try {
    print('# Memory of the running app${options.label}');
    print('');
    await _process(service);
    final vm = await service.getVM();
    for (final group in vm.isolateGroups ?? const <IsolateGroupRef>[]) {
      final isolates = (await service.getIsolateGroup(group.id!)).isolates;
      if (isolates == null || isolates.isEmpty) continue;
      await _group(service, isolates, options.top);
    }
  } finally {
    await service.dispose();
  }
}

/// The process's memory as the VM attributes it, two levels deep.
Future<void> _process(VmService service) async {
  final usage = await service.getProcessMemoryUsage();
  final root = usage.root!;
  print('## Process: ${_mb(root.size!)}');
  print('');
  _items(root.children, '');
  print('');
}

/// [items] from the largest, two levels deep; the ones under a megabyte —
/// a process maps hundreds of small libraries — summed on one line.
void _items(List<ProcessMemoryItem>? items, String indent) {
  var small = 0;
  var smallCount = 0;
  for (final item in _bySize(items)) {
    if (item.size! < 1 << 20) {
      small += item.size!;
      smallCount++;
      continue;
    }
    print('$indent- ${item.name}: ${_mb(item.size!)}');
    if (indent.isEmpty) _items(item.children, '$indent  ');
  }
  if (smallCount > 0) {
    print('$indent- $smallCount smaller: ${_mb(small)}');
  }
}

/// One isolate group's heap after a collection, and the classes holding
/// most of it. The isolates of a group share one heap — an `Isolate.run` is
/// in its spawner's — so it is read once, through the first of them.
Future<void> _group(
  VmService service,
  List<IsolateRef> isolates,
  int top,
) async {
  final names = isolates.map((isolate) => isolate.name).join(', ');
  final AllocationProfile profile;
  try {
    profile = await service.getAllocationProfile(isolates.first.id!, gc: true);
  } on RPCError catch (error) {
    // An isolate that ended between the listing and the read.
    print('## $names: gone (${error.message})');
    print('');
    return;
  }
  final usage = profile.memoryUsage!;
  print(
    '## $names: heap ${_mb(usage.heapUsage!)} of '
    '${_mb(usage.heapCapacity!)}, external ${_mb(usage.externalUsage!)}',
  );
  print('');
  final classes = [
    for (final member in profile.members ?? const <ClassHeapStats>[])
      if ((member.bytesCurrent ?? 0) > 0) member,
  ]..sort((a, b) => b.bytesCurrent!.compareTo(a.bytesCurrent!));
  for (final member in classes.take(top)) {
    print(
      '- ${member.classRef?.name}: ${_mb(member.bytesCurrent!)}, '
      '${member.instancesCurrent} instance(s)',
    );
  }
  print('');
}

List<ProcessMemoryItem> _bySize(List<ProcessMemoryItem>? items) =>
    [...?items]..sort((a, b) => b.size!.compareTo(a.size!));

String _mb(int bytes) => '${(bytes / (1 << 20)).toStringAsFixed(1)} MB';

/// The command line: where the VM service is, how many classes, a label.
final class _Options {
  const new({required this.uri, required this.top, required this.label});

  factory parse(List<String> args) {
    var uri = 'ws://127.0.0.1:8181/ws';
    var top = 15;
    var label = '';
    for (var at = 0; at + 1 < args.length; at += 2) {
      switch (args[at]) {
        case '--uri':
          uri = args[at + 1];
        case '--top':
          top = int.parse(args[at + 1]);
        case '--label':
          label = ': ${args[at + 1]}';
      }
    }
    return _Options(uri: uri, top: top, label: label);
  }

  final String uri;
  final int top;
  final String label;
}
