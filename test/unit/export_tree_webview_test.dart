// A folder's PDF where the system WebView prints (Android, a Mac's WebKit):
// the export's isolate asks the UI isolate to print each page, whose
// channel call is the one a single note's export makes — a background
// isolate's own call stood still on a Mac until something was clicked.
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/export_tree.dart';
import 'package:niman/src/export/pdf_webview.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory lib;
  late String notes;
  late String zip;
  final printed = <String>[];

  setUp(() async {
    debugSystemWebViewPrints = true;
    printed.clear();
    lib = await Directory.systemTemp.createTemp('niman_tree_webview_');
    notes = p.join(lib.path, 'Notes');
    await Directory(p.join(notes, 'sub')).create(recursive: true);
    await File(p.join(notes, 'a.md')).writeAsString('# A\n\nalpha\n');
    await File(p.join(notes, 'sub', 'b.md')).writeAsString('# B\n\nbeta\n');
    zip = p.join(lib.path, 'out.zip');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(webViewPdfChannel), (
          call,
        ) async {
          final arguments = (call.arguments as Map).cast<String, String>();
          printed.add(File(arguments['htmlPath']!).readAsStringSync());
          await File(arguments['pdfPath']!).writeAsString('%PDF-fake');
          return null;
        });
  });

  tearDown(() async {
    debugSystemWebViewPrints = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(webViewPdfChannel), null);
    if (lib.existsSync()) await lib.delete(recursive: true);
  });

  test('the UI isolate prints every page the export asks for', () async {
    await TreeExport.run(
      dir: notes,
      zipPath: zip,
      format: ExportTreeFormat.pdf,
      language: 'en',
    );

    final archive = ZipDecoder().decodeBytes(await File(zip).readAsBytes());
    final names = {for (final file in archive.files) file.name};
    expect(names, containsAll(<String>['a.pdf', 'sub/b.pdf']));
    expect(printed, hasLength(2));
    expect(printed.join(), allOf(contains('alpha'), contains('beta')));
  });
}
