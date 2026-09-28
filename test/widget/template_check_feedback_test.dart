// The template checker's findings in the source surface (T-TPL-09): the span
// the checker reported wears the wavy mark, the hint on the caret carries the
// message and — only where the checker offered one — the fix as a single
// action, and the status row counts what is left.
//
// Only a template is checked: a `{{…}}` in an ordinary note is text.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/render/squiggle_painter.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/templates/check_state.dart';
import 'package:niman/src/ui/note_view_chrome.dart';
import 'package:niman/src/ui/strings.dart';

/// The words painted under a wavy mark, in order.
///
/// The squiggle is painted over the line (`SquigglePainter`), not written
/// into its style, so it is read from the painters and the text they paint
/// over.
List<String> _underlined(WidgetTester tester) => <String>[
  for (final paint in tester.widgetList<CustomPaint>(find.byType(CustomPaint)))
    if (paint.foregroundPainter case final SquigglePainter squiggle)
      for (final range in squiggle.ranges)
        range.textInside(
          tester
              .widget<RichText>(
                find.descendant(
                  of: find.byWidget(paint),
                  matching: find.byType(RichText),
                ),
              )
              .text
              .toPlainText(),
        ),
];

/// Everything the hint says, as one string.
String _hintWords(WidgetTester tester) {
  final card = find.byKey(const Key('template-hint'));
  return <String>[
    for (final text in tester.widgetList<Text>(
      find.descendant(of: card, matching: find.byType(Text)),
    ))
      text.data ?? text.textSpan?.toPlainText() ?? '',
  ].join(' | ');
}

/// The surface over [buffer], as a template or as an ordinary note.
Widget _surface(
  SourceBuffer buffer,
  TemplateCheck? check, {
  bool template = true,
  int? caret,
}) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: MarkdownSourceView(
        buffer: buffer,
        theme: markdownThemeOf(context),
        showLineNumbers: false,
        templateCommands: template,
        templateCheck: check,
        selection: caret == null ? null : SelectionModel.at(caret),
      ),
    ),
  ),
);

/// Pumps the surface and the frames its first check arrives on.
Future<void> _pump(
  WidgetTester tester,
  SourceBuffer buffer,
  TemplateCheck check, {
  bool template = true,
  int? caret,
}) async {
  await tester.pumpWidget(
    _surface(buffer, check, template: template, caret: caret),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('the span the checker reported wears the wavy mark', (
    tester,
  ) async {
    final check = TemplateCheck();
    addTearDown(check.dispose);
    await _pump(
      tester,
      SourceBuffer.fromText('hello {{titlex}} there\n'),
      check,
    );

    expect(_underlined(tester), <String>['{{titlex}}']);
  });

  testWidgets('a note that is not a template is never checked', (tester) async {
    final check = TemplateCheck();
    addTearDown(check.dispose);
    await _pump(
      tester,
      SourceBuffer.fromText('hello {{titlex}} there\n'),
      check,
      template: false,
    );

    expect(_underlined(tester), isEmpty, reason: 'a `{{…}}` that is text');
    expect(find.byKey(const Key('template-hint')), findsNothing);
    expect(
      check.problemCount,
      0,
      reason: 'the checker was never handed the note',
    );
  });

  testWidgets('the hint names the mistake and offers the fix as one tap', (
    tester,
  ) async {
    final check = TemplateCheck();
    addTearDown(check.dispose);
    final buffer = SourceBuffer.fromText('{{titlex}} here\n');
    await _pump(tester, buffer, check, caret: 0);

    final words = _hintWords(tester);
    expect(words, contains("unknown placeholder 'titlex'"));
    expect(
      words,
      contains('Did you mean {{title}}?'),
      reason: 'the fix the checker computed, in the sentence around it',
    );
    expect(
      buffer.text,
      '{{titlex}} here\n',
      reason: 'nothing is applied without asking',
    );

    await tester.tap(find.byKey(const Key('template-hint-fix')));
    await tester.pump();
    expect(buffer.text, '{{title}} here\n');

    // The note is read again once the writer pauses, and the mark it finds
    // there — none — takes the hint away with it.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byKey(const Key('template-hint')), findsNothing);
    expect(_underlined(tester), isEmpty);
  });

  testWidgets('a mistake with no fix offers Dismiss alone', (tester) async {
    final check = TemplateCheck();
    addTearDown(check.dispose);
    // `}}` with nothing open: reported, and nothing the checker would write.
    await _pump(tester, SourceBuffer.fromText('title}}\n'), check, caret: 5);

    expect(_hintWords(tester), contains(AppStrings.templateHintNoFix));
    expect(find.byKey(const Key('template-hint-fix')), findsNothing);
    expect(find.byKey(const Key('template-hint-dismiss')), findsOneWidget);

    await tester.tap(find.byKey(const Key('template-hint-dismiss')));
    await tester.pump();
    expect(find.byKey(const Key('template-hint')), findsNothing);
  });

  testWidgets('the mark waits for the pause, and never rides a keystroke', (
    tester,
  ) async {
    final check = TemplateCheck();
    addTearDown(check.dispose);
    final buffer = SourceBuffer.fromText('{{title}}\n');
    await _pump(tester, buffer, check, caret: 0);
    expect(_underlined(tester), isEmpty, reason: 'a clean template');

    // A keystroke through the app's own path: the note is edited, and the
    // surface is told of it — the pause it arms is what reads the note.
    final state = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    expect(buffer.text, '{{title}}\n', reason: 'the note as it stands');

    state.replaceText(2, 7, 'titlex');
    await tester.pump();
    expect(
      _underlined(tester),
      isEmpty,
      reason: 'the keystroke paid for the pause, not for a pass',
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(_underlined(tester), <String>['{{titlex}}']);
  });

  group('the status row', () {
    Widget row(int problems) => MaterialApp(
      home: Scaffold(
        body: NoteStatusRow(
          loading: false,
          showPreview: false,
          showWysiwyg: false,
          spellCheckAvailable: false,
          canSwitchEditorKind: false,
          wordCount: 12,
          statusText: 'Saved',
          statusActions: const <Widget>[],
          templateProblems: problems,
          onOutline: () async {},
          onFind: () {},
          onSpellCheck: () async {},
          onToggleEditorKind: () {},
        ),
      ),
    );

    testWidgets('counts what the checker found', (tester) async {
      await tester.pumpWidget(row(3));

      expect(find.byKey(const Key('template-problems')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(
        tester
            .widget<Tooltip>(
              find.ancestor(
                of: find.byKey(const Key('template-problems')),
                matching: find.byType(Tooltip),
              ),
            )
            .message,
        AppStrings.templateProblems(3),
      );
    });

    testWidgets('says nothing at all for a clean template', (tester) async {
      await tester.pumpWidget(row(0));

      expect(find.byKey(const Key('template-problems')), findsNothing);
      expect(find.text(AppStrings.wordCount(12)), findsOneWidget);
    });
  });
}
