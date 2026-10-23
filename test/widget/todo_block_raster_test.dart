// A `todo` fence in the PDF drawn as pictures (#1152): the list it is at the
// moment of the export, in the note's type, where the fence's source would
// have been.
import 'dart:convert';
import 'dart:io' show ZLibCodec;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/pdf_raster.dart';
import 'package:niman/src/export/printed_todo_block.dart';
import 'package:niman/src/export/printed_todo_builder.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_export.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/todo_block_scope.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

const String _note = 'Intro\n\n```todo\nlink: any\n```\n\nTail\n';

final PrintedTodoBlocks _listed = <String, PrintedTodoBlock>{
  todoBlockKey('link: any'): const PrintedTodoBlock(
    head: 'Tasks · project house · 2',
    tasks: [
      (done: false, text: 'Pay the bill'),
      (done: true, text: 'Fix the tap'),
    ],
  ),
};

final PrintedTodoBlocks _failed = <String, PrintedTodoBlock>{
  todoBlockKey('link: any'): const PrintedTodoBlock(
    head: 'Tasks',
    problems: ['Unknown key prio — Line 1 of the block'],
  ),
};

/// How many pixels of the PDF's pages are the error red.
int _redPixels(Uint8List pdf) {
  final text = latin1.decode(pdf);
  var count = 0;
  var at = 0;
  while (true) {
    final image = text.indexOf('/Subtype /Image', at);
    if (image < 0) break;
    final start = text.indexOf('stream\n', image) + 'stream\n'.length;
    final end = text.indexOf('\nendstream', start);
    final rgb = ZLibCodec().decode(pdf.sublist(start, end));
    for (var i = 0; i + 2 < rgb.length; i += 3) {
      if (rgb[i] > 200 && rgb[i + 1] < 110 && rgb[i + 2] < 100) count++;
    }
    at = end;
  }
  return count;
}

void main() {
  late MarkdownTheme theme;
  late MathCache cache;

  setUp(() => cache = MathCache());
  tearDown(() => cache.dispose());

  Future<void> pumpTheme(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            theme = markdownThemeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  testWidgets('the page draws the list where the fence was', (tester) async {
    await pumpTheme(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TodoBlockScope(
              builder: PrintedTodoBuilder(_listed),
              child: MarkdownExportView(
                buffer: SourceBuffer.fromText(_note),
                parser: ReadParser(),
                theme: theme,
                mathCache: cache,
                width: 400,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Tasks · project house · 2'), findsOneWidget);
    expect(find.text('☐ Pay the bill'), findsOneWidget);
    expect(find.text('☑ Fix the tap'), findsOneWidget);
    expect(find.textContaining('link: any'), findsNothing);
    expect(find.text('Tail'), findsOneWidget);
  });

  testWidgets('a fence it has no list for stays code', (tester) async {
    await pumpTheme(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TodoBlockScope(
              builder: const PrintedTodoBuilder(<String, PrintedTodoBlock>{
                'other': PrintedTodoBlock(head: 'Tasks'),
              }),
              child: MarkdownExportView(
                buffer: SourceBuffer.fromText(_note),
                parser: ReadParser(),
                theme: theme,
                mathCache: cache,
                width: 400,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('link: any'), findsOneWidget);
  });

  testWidgets('the drawn pages carry the error in red', (tester) async {
    await pumpTheme(tester);
    final plain = await tester.runAsync(
      () => rasterPdf(text: _note, theme: theme, mathCache: cache),
    );
    final failed = await tester.runAsync(
      () => rasterPdf(
        text: _note,
        theme: theme,
        mathCache: cache,
        todoBlocks: _failed,
      ),
    );
    expect(latin1.decode(failed!.sublist(0, 8)), '%PDF-1.4');
    expect(_redPixels(plain!), 0);
    expect(_redPixels(failed), greaterThan(100));
  });
}
