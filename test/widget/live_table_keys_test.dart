// Leaving a table in `live` with the keyboard alone (2026-09-24 report).
// Enter goes to the cell below and, from the last row, out of the table;
// Shift+Enter and Ctrl+Enter leave it from any row; Down from the last row
// leaves it too. A table the note ends with gets a line to leave to.
//
// Through the platform each embedder is: Enter is the framework's key first
// on the desktops and the soft keyboard's line break on Android.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';

import '../fakes/fake_embedder.dart';

const String _table = '| a | b |\n| --- | --- |\n| uno | 2 |\n| due | 1 |';

Future<(MarkdownSourceViewState, SourceBuffer, FakeEmbedder)> _pump(
  WidgetTester tester,
  EmbedderProfile profile,
  String text,
) async {
  final platform = FakeEmbedder(tester, profile)..install();
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final buffer = SourceBuffer.fromText(text);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => MarkdownSourceView(
            buffer: buffer,
            theme: markdownThemeOf(context),
            showLineNumbers: false,
            hideMarkers: true,
            autofocus: true,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final view = tester.state<MarkdownSourceViewState>(
    find.byType(MarkdownSourceView),
  );
  return (view, buffer, platform);
}

/// Presses Enter with [modifier] held.
Future<void> _enterWith(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.sendKeyUpEvent(modifier);
  await tester.pumpAndSettle();
}

void main() {
  for (final profile in EmbedderProfile.values) {
    group(profile.name, () {
      testWidgets('Enter goes to the cell below, then out of the table', (
        tester,
      ) async {
        const text = 'intro\n\n$_table\n\nafter\n';
        final (view, buffer, platform) = await _pump(tester, profile, text);
        view.placeCaret(text.indexOf('uno') + 1);
        await tester.pump();

        await platform.enter();
        await tester.pumpAndSettle();
        expect(buffer.text, text, reason: 'no row split');
        expect(
          view.selection.extent,
          text.indexOf('due') + 'due'.length,
          reason: 'the end of the cell below, same column',
        );
        expect(platform.text, buffer.text);

        await platform.enter();
        await tester.pumpAndSettle();
        expect(buffer.text, text);
        expect(
          buffer.lineOf(view.selection.extent),
          buffer.lineOf(text.indexOf('| due')) + 1,
          reason: 'the line after the table',
        );
      });

      testWidgets('a table the note ends with gets a line to leave to', (
        tester,
      ) async {
        const text = 'intro\n\n$_table';
        final (view, buffer, platform) = await _pump(tester, profile, text);
        view.placeCaret(text.indexOf('due') + 1);
        await tester.pump();

        await platform.enter();
        await tester.pumpAndSettle();
        expect(buffer.text, '$text\n');
        expect(view.selection.extent, buffer.length);
        expect(platform.text, buffer.text);
      });

      if (profile != EmbedderProfile.android) {
        testWidgets(
          'Down from the last row leaves a table the note ends with',
          (tester) async {
            const text = 'intro\n\n$_table';
            final (view, buffer, _) = await _pump(tester, profile, text);
            view.placeCaret(text.indexOf('due') + 1);
            await tester.pump();

            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            await tester.pumpAndSettle();
            expect(buffer.text, '$text\n');
            expect(view.selection.extent, buffer.length);
          },
        );

        for (final modifier in [
          LogicalKeyboardKey.shiftLeft,
          LogicalKeyboardKey.controlLeft,
        ]) {
          testWidgets('${modifier.keyLabel}+Enter leaves it from any row', (
            tester,
          ) async {
            const text = 'intro\n\n$_table\n\nafter\n';
            final (view, buffer, platform) = await _pump(tester, profile, text);
            view.placeCaret(text.indexOf('a |') + 1);
            await tester.pump();

            await _enterWith(tester, modifier);
            expect(buffer.text, text, reason: 'nothing typed');
            expect(
              buffer.lineOf(view.selection.extent),
              buffer.lineOf(text.indexOf('| due')) + 1,
            );
            expect(platform.text, buffer.text);
          });
        }

        testWidgets('Shift+Enter outside a table is left alone', (
          tester,
        ) async {
          const text = 'intro\n';
          final (view, buffer, _) = await _pump(tester, profile, text);
          view.placeCaret(2);
          await tester.pump();
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          final handled = await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          expect(handled, isFalse, reason: 'it goes on to the platform');
          expect(buffer.text, text);
        });
      }
    });
  }
}
