// Printing an exported page with the machine's own browser engine (#63):
// which engine is found where, the command it is run with, and what each
// failure reports.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:path/path.dart' as p;

void main() {
  group('finding the engine', () {
    test('Linux takes the first Chromium-family browser on PATH', () async {
      Future<bool> isFile(String path) async =>
          path == '/usr/bin/chromium-browser' ||
          path == '/usr/bin/google-chrome';
      expect(
        await findPdfEngine(
          isWindows: false,
          isLinux: true,
          path: const ['/usr/local/bin', '/usr/bin'],
          isFile: isFile,
        ),
        '/usr/bin/chromium-browser',
      );
    });

    test('Linux with none on PATH finds nothing', () async {
      expect(
        await findPdfEngine(
          isWindows: false,
          isLinux: true,
          path: const ['/usr/bin'],
          isFile: (path) async => false,
        ),
        isNull,
      );
    });

    test('Windows asks the App Paths key first', () async {
      const edge =
          r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe';
      expect(
        await findPdfEngine(
          isWindows: true,
          isLinux: false,
          run: (exe, args, {timeout}) async => (
            exit: 0,
            stdout:
                'HKEY_LOCAL_MACHINE\\...\n'
                '    (Default)    REG_SZ    $edge\n',
          ),
          isFile: (path) async => path == edge,
          roots: const [r'C:\Program Files'],
        ),
        edge,
      );
    });

    test('Windows falls back to the install folders', () async {
      const edge = r'C:\Program Files\Microsoft\Edge\Application\msedge.exe';
      expect(
        await findPdfEngine(
          isWindows: true,
          isLinux: false,
          run: (exe, args, {timeout}) async => (exit: 1, stdout: ''),
          isFile: (path) async => path == edge,
          roots: const [r'C:\Program Files'],
        ),
        edge,
      );
    });

    test('a platform with neither engine finds nothing', () async {
      expect(await findPdfEngine(isWindows: false, isLinux: false), isNull);
    });
  });

  group('whether there is anything to print with', () {
    test('an engine given is a printer', () async {
      expect(
        await ProcessPdfPrinter(engine: '/usr/bin/chromium').canPrint,
        isTrue,
      );
    });

    test('discovery answers when none was given', () async {
      expect(
        await ProcessPdfPrinter(findEngine: () async => null).canPrint,
        isFalse,
      );
      expect(
        await ProcessPdfPrinter(findEngine: () async => '/usr/bin/chromium')
            .canPrint,
        isTrue,
      );
    });
  });

  group('printing', () {
    test('the command is headless, and the file is checked', () async {
      final calls = <(String, List<String>)>[];
      final printer = ProcessPdfPrinter(
        engine: '/usr/bin/chromium',
        run: (exe, args, {timeout}) async {
          calls.add((exe, args));
          return (exit: 0, stdout: '');
        },
        size: (path) async => path == '/tmp/out.pdf' ? 10 : null,
      );

      expect(
        await printer.print('/tmp/page.html', '/tmp/out.pdf'),
        isA<PdfPrinted>(),
      );
      expect(calls, hasLength(1));
      expect(calls.single.$1, '/usr/bin/chromium');
      expect(calls.single.$2, contains('--headless=new'));
      expect(calls.single.$2, contains('--disable-gpu'));
      expect(calls.single.$2, contains('--no-pdf-header-footer'));
      expect(calls.single.$2, contains('--print-to-pdf=/tmp/out.pdf'));
      expect(calls.single.$2.last, Uri.file('/tmp/page.html').toString());
    });

    test('no engine is no engine', () async {
      final printer = ProcessPdfPrinter(
        findEngine: () async => null,
        run: (_, _, {timeout}) async => (exit: 0, stdout: ''),
        size: (path) async => 1,
      );
      expect(await printer.print('a.html', 'b.pdf'), isA<PdfNoEngine>());
    });

    test('a failing engine reports its exit', () async {
      final printer = ProcessPdfPrinter(
        engine: '/usr/bin/chromium',
        run: (_, _, {timeout}) async => (exit: 2, stdout: ''),
        size: (path) async => 1,
      );
      final outcome = await printer.print('a.html', 'b.pdf');
      expect(outcome, isA<PdfFailed>());
      expect((outcome as PdfFailed).message, contains('2'));
    });

    test('a missing or empty file is a failure', () async {
      Future<PdfOutcome> printed(Future<int?> size) => ProcessPdfPrinter(
        engine: '/usr/bin/chromium',
        run: (_, _, {timeout}) async => (exit: 0, stdout: ''),
        size: (path) => size,
      ).print('a.html', 'b.pdf');

      expect(await printed(Future.value()), isA<PdfFailed>());
      expect(await printed(Future.value(0)), isA<PdfFailed>());
    });

    test('an engine that never answers times out', () async {
      final printer = ProcessPdfPrinter(
        engine: '/usr/bin/chromium',
        run: (_, _, {timeout}) async => throw const ProcessTimedOut(),
        size: (path) async => 1,
        timeout: const Duration(milliseconds: 20),
      );
      final outcome = await printer.print('a.html', 'b.pdf');
      expect(outcome, isA<PdfFailed>());
      expect((outcome as PdfFailed).message, contains('finish'));
    });
  });

  group('running a process', () {
    test('a process that never answers is killed', () async {
      final dir = await Directory.current.createTemp('niman_process_');
      addTearDown(() async {
        if (dir.existsSync()) await dir.delete(recursive: true);
      });
      final script = File(p.join(dir.path, 'hang.dart'));
      await script.writeAsString('void main() { while (true) {} }\n');

      final started = Stopwatch()..start();
      await expectLater(
        runProcess(Platform.resolvedExecutable, <String>[
          script.path,
        ], timeout: const Duration(milliseconds: 500)),
        throwsA(isA<ProcessTimedOut>()),
      );
      // Killed, not waited out: the script would run forever.
      expect(started.elapsed, lessThan(const Duration(seconds: 20)));
    });
  });
}
