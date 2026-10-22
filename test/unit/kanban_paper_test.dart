// The sheet a kanban board is printed on, through every way a PDF is made
// (#1170): the paper chosen per note, what each engine is told, and the
// folder export printing each note on its own.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/export_pdf.dart';
import 'package:niman/src/export/export_sources.dart';
import 'package:niman/src/export/export_tree.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_webview.dart';
import 'package:path/path.dart' as p;

/// A board of [columns] columns, one card each.
String _columns(int columns) {
  final cards = [for (var i = 1; i <= columns; i++) '## C$i\n- [ ] card $i\n'];
  return '---\ntype: kanban\n---\n${cards.join('\n')}';
}

const String _plain = '# Plain\n\nJust a note.\n';

/// A printer that keeps the page it was handed and the sheet it was told.
final class _Prints implements PdfPrinter {
  new();

  String? page;
  PdfPaper? paper;

  @override
  Future<bool> get canPrint async => true;

  @override
  Future<PdfOutcome> print(
    String htmlPath,
    String pdfPath, {
    PdfPaper paper = PdfPaper.a4,
  }) async {
    page = await File(htmlPath).readAsString();
    this.paper = paper;
    await File(pdfPath).writeAsBytes(<int>[1, 2, 3, 4]);
    return const PdfPrinted();
  }
}

/// The width and the height of the first `/MediaBox` of [pdf], in points.
(double, double)? _mediaBox(List<int> pdf) {
  final match = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)')
      .firstMatch(latin1.decode(pdf));
  return match == null
      ? null
      : (double.parse(match.group(1)!), double.parse(match.group(2)!));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the paper of a note', () {
    Future<PdfPaper> paperOf(String text, {bool kanban = true}) async =>
        (await ExportSources.printable(
          NoteHtmlSource(text: text, title: 't', kanban: kanban),
          language: 'en',
        )).paper;

    test('is A4 landscape for a board of up to four columns', () async {
      expect(await paperOf(_columns(1)), PdfPaper.a4Landscape);
      expect(await paperOf(_columns(4)), PdfPaper.a4Landscape);
    });

    test('is A4 portrait for a board of five or more', () async {
      expect(await paperOf(_columns(5)), PdfPaper.a4);
      expect(await paperOf(_columns(9)), PdfPaper.a4);
    });

    test('is A4 portrait for any other note, and for a board with the '
        'feature off', () async {
      expect(await paperOf(_plain), PdfPaper.a4);
      expect(await paperOf(_columns(3), kanban: false), PdfPaper.a4);
      // A kanban note with no column is prose.
      expect(
        await paperOf('---\ntype: kanban\n---\nOnly words.\n'),
        PdfPaper.a4,
      );
    });

    test('is the page that was built for it', () async {
      Future<String> pageOf(String text) async =>
          (await ExportSources.printable(
            NoteHtmlSource(text: text, title: 't', kanban: true),
            language: 'en',
          )).html;
      expect(await pageOf(_columns(4)), contains('size: A4 landscape'));
      expect(await pageOf(_columns(5)), isNot(contains('A4 landscape')));
    });
  });

  group('exportNotePdf', () {
    late Directory root;

    setUp(() async {
      root = await Directory.current.createTemp('niman_kanban_paper_');
    });

    tearDown(() async {
      if (root.existsSync()) await root.delete(recursive: true);
    });

    Future<_Prints> printed(
      String text, {
      bool kanban = true,
      List<String>? slides,
    }) async {
      final printer = _Prints();
      await exportNotePdf(
        text: text,
        title: 'Board',
        path: 'Board.md',
        root: root.path,
        language: 'en',
        printer: printer,
        kanban: kanban,
        slides: slides,
      );
      return printer;
    }

    test('asks the printer for A4 landscape for four columns', () async {
      final printer = await printed(_columns(4));
      expect(printer.paper, PdfPaper.a4Landscape);
      // The engines that read the page's own sheet find it there too.
      expect(printer.page, contains('@page { size: A4 landscape'));
    });

    test(
      'asks for A4 for five columns, a plain note and the feature off',
      () async {
        expect((await printed(_columns(5))).paper, PdfPaper.a4);
        expect((await printed(_plain)).paper, PdfPaper.a4);
        expect((await printed(_columns(4), kanban: false)).paper, PdfPaper.a4);
      },
    );

    test('keeps the slides on their own sheet', () async {
      final printer = await printed(_columns(4), slides: const ['# One']);
      expect(printer.paper, PdfPaper.slides);
    });
  });

  group('the desktop engine', () {
    test('is told the sheet by the page it prints, not by a flag', () async {
      final calls = <List<String>>[];
      final printer = ProcessPdfPrinter(
        engine: '/usr/bin/chromium',
        run: (exe, args, {timeout, outputLimit}) async {
          calls.add(args);
          return (exit: 0, stdout: '');
        },
        size: (path) async => 10,
      );
      for (final paper in PdfPaper.values) {
        await printer.print('/tmp/page.html', '/tmp/out.pdf', paper: paper);
      }
      // One command for every sheet: the engine takes the paper from the
      // page's `@page`, as it does for the slides' sheet; a flag of its own
      // would be a second place to say it.
      expect(calls, hasLength(PdfPaper.values.length));
      for (final args in calls) {
        expect(args, equals(calls.first));
        expect(args.join(' '), isNot(contains('landscape')));
      }
    });

    test('prints a board on a landscape sheet', () async {
      final engine = await findPdfEngine();
      if (engine == null) {
        markTestSkipped('no browser engine on this machine');
        return;
      }
      final dir = await Directory.systemTemp.createTemp('niman_kanban_live_');
      addTearDown(() async {
        try {
          await dir.delete(recursive: true);
        } on FileSystemException {
          // An engine that is still winding down holds its profile.
        }
      });
      var run = 0;
      Future<(double, double)?> boxOf(String text) async {
        run++;
        final htmlPath = p.join(dir.path, 'page$run.html');
        final pdfPath = p.join(dir.path, 'page$run.pdf');
        final out = await ExportSources.printable(
          NoteHtmlSource(text: text, title: 't', kanban: true),
          language: 'en',
        );
        await File(htmlPath).writeAsString(out.html);
        final outcome = await ProcessPdfPrinter(engine: engine)
            .print(htmlPath, pdfPath, paper: out.paper);
        // Edge on Windows hands its work to a process that outlives the
        // one launched: the file lands a moment after the launcher exits.
        for (var wait = 0; wait < 100; wait++) {
          if (outcome is PdfPrinted || (await fileSize(pdfPath) ?? 0) > 0) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        // Whole, not half written.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return _mediaBox(await File(pdfPath).readAsBytes());
      }

      final landscape = await boxOf(_columns(4));
      expect(landscape, isNotNull);
      expect(landscape!.$1, closeTo(842, 2));
      expect(landscape.$2, closeTo(595, 2));
      final portrait = await boxOf(_columns(5));
      expect(portrait!.$1, closeTo(595, 2));
      expect(portrait.$2, closeTo(842, 2));
    }, timeout: const Timeout(Duration(minutes: 3)));
  });

  group('the system WebView', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('niman_kanban_webview_');
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel(webViewPdfChannel),
            null,
          );
      if (dir.existsSync()) await dir.delete(recursive: true);
    });

    test('is told the paper by name, as the bridges read it', () async {
      final seen = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(webViewPdfChannel), (
            call,
          ) async {
            final arguments = (call.arguments as Map).cast<String, String>();
            seen.add(arguments['paper']!);
            await File(arguments['pdfPath']!).writeAsBytes(<int>[1]);
            return null;
          });
      for (final paper in PdfPaper.values) {
        await const WebViewPdfPrinter().print(
          p.join(dir.path, 'page.html'),
          p.join(dir.path, 'page.pdf'),
          paper: paper,
        );
      }
      // The words PdfBridge.kt (PdfSheet) and the Apple bridges match.
      expect(seen, <String>['a4', 'a4Landscape', 'slides']);
    });
  });

  group('a folder export', () {
    late Directory lib;
    late String notes;

    setUp(() async {
      debugSystemWebViewPrints = true;
      lib = await Directory.systemTemp.createTemp('niman_kanban_tree_');
      notes = p.join(lib.path, 'Notes');
      await Directory(notes).create(recursive: true);
      await File(p.join(notes, 'narrow.md')).writeAsString(_columns(3));
      await File(p.join(notes, 'wide.md')).writeAsString(_columns(6));
      await File(p.join(notes, 'plain.md')).writeAsString(_plain);
    });

    tearDown(() async {
      debugSystemWebViewPrints = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel(webViewPdfChannel),
            null,
          );
      if (lib.existsSync()) await lib.delete(recursive: true);
    });

    Future<Map<String, String>> papersOf({required bool kanban}) async {
      final papers = <String, String>{};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(webViewPdfChannel), (
            call,
          ) async {
            final arguments = (call.arguments as Map).cast<String, String>();
            final page = File(arguments['htmlPath']!).readAsStringSync();
            final title = RegExp('<title>(.*?)</title>').firstMatch(page)!;
            papers[title.group(1)!] = arguments['paper']!;
            await File(arguments['pdfPath']!).writeAsString('%PDF-fake');
            return null;
          });
      await TreeExport.run(
        dir: notes,
        zipPath: p.join(lib.path, 'out.zip'),
        format: ExportTreeFormat.pdf,
        language: 'en',
        kanban: kanban,
      );
      final archive = ZipDecoder().decodeBytes(
        await File(p.join(lib.path, 'out.zip')).readAsBytes(),
      );
      expect(
        archive.files.where((file) => file.isFile).map((file) => file.name),
        containsAll(<String>['narrow.pdf', 'wide.pdf', 'plain.pdf']),
      );
      return papers;
    }

    test('prints each note on the paper of its own', () async {
      expect(await papersOf(kanban: true), <String, String>{
        'narrow': 'a4Landscape',
        'wide': 'a4',
        'plain': 'a4',
      });
    });

    test('prints every note on A4 with the Kanban feature off', () async {
      expect(await papersOf(kanban: false), <String, String>{
        'narrow': 'a4',
        'wide': 'a4',
        'plain': 'a4',
      });
    });
  });
}
