// A template's commands, coloured in the source apart from the Markdown
// they stand in — and only a template's: elsewhere a `{{…}}` is text.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';

void main() {
  Widget surface(SourceBuffer buffer, {required bool template}) => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => MarkdownSurface(
          buffer: buffer,
          mode: MarkdownSurfaceMode.source,
          theme: markdownThemeOf(context),
          templateCommands: template,
        ),
      ),
    ),
  );

  List<String> commands(WidgetTester tester, String line, int index) => [
    for (final token
        in tester
            .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
            .tokensOf(index))
      if (token.kind == TokenKind.templateCommand)
        line.substring(token.start, token.end),
  ];

  const text =
      '---\n'
      'date: {{date}}\n'
      '---\n'
      '# {{title}}\n'
      'Due **{{date:YYYY-MM-DD|+7d}}**, not {{titel}}.\n';

  testWidgets("a template's commands are runs of their own, anywhere", (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText(text);
    await tester.pumpWidget(surface(buffer, template: true));
    await tester.pumpAndSettle();
    final lines = text.split('\n');
    expect(commands(tester, lines[1], 1), ['{{date}}']);
    expect(commands(tester, lines[3], 3), ['{{title}}']);
    expect(commands(tester, lines[4], 4), ['{{date:YYYY-MM-DD|+7d}}']);
  });

  testWidgets('a note that is no template leaves them text', (tester) async {
    final buffer = SourceBuffer.fromText(text);
    await tester.pumpWidget(surface(buffer, template: false));
    await tester.pumpAndSettle();
    expect(commands(tester, text.split('\n')[4], 4), isEmpty);
  });

  testWidgets('a command typed in is coloured as it is finished', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText('Hello {{tit\n');
    await tester.pumpWidget(surface(buffer, template: true));
    await tester.pumpAndSettle();
    expect(commands(tester, 'Hello {{tit', 0), isEmpty);
    tester
        .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
        .replaceText(11, 11, 'le}}');
    await tester.pump();
    expect(commands(tester, 'Hello {{title}}', 0), ['{{title}}']);
  });
}
