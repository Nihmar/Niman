// A `todo` fence drawn as the list of tasks it asks for (#1152): in the read
// view and in `live`, with the caret outside the block; its source again with
// the caret inside; an error row in place of the list; a tick; Add task
// written out from the block's filters; and the fence left as code where no
// tasks are at hand. Drawing it never rewrites the note.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/todo_block_scope.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/note_todo_blocks.dart';

import '../fakes/note_tasks_fixture.dart';

const MarkdownTheme _theme = MarkdownTheme(
  body: TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
  heading1: TextStyle(fontSize: 25),
  heading2: TextStyle(fontSize: 21),
  heading3: TextStyle(fontSize: 18),
  heading4: TextStyle(fontSize: 16),
  heading5: TextStyle(fontSize: 14),
  heading6: TextStyle(fontSize: 13),
  code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
  quote: TextStyle(fontSize: 14),
  tableCell: TextStyle(fontSize: 14),
  tableHeader: TextStyle(fontSize: 14),
  link: TextStyle(fontSize: 14),
  wikilink: TextStyle(fontSize: 14),
  tag: TextStyle(fontSize: 14),
  marker: TextStyle(fontSize: 14),
  codeHighlight: <String, TextStyle>{},
  rule: Color(0xFF888888),
  codeBackground: Color(0xFFEEEEEE),
  quoteBar: Color(0xFFCCCCCC),
  tableBorder: Color(0xFFCCCCCC),
  markerDim: Color(0xFF999999),
  blockSpacing: 10,
  listIndentPerLevel: 22,
  quoteIndentPerLevel: 12,
  codePadding: 8,
  quoteBarWidth: 3,
  ruleThickness: 1,
  tableCellPadding: EdgeInsets.all(4),
  lineHeight: 21,
);

const String _notePath = 'House/Repairs.md';

const List<String> _todo = <String>[
  'Call the plumber [[House/Repairs]] +house @phone due:2026-09-08',
  'Pay the bill +house due:2026-09-20',
  'Elsewhere [[Ideas]] +garden',
];

String _note(String body) => 'Intro\n\n```todo\n$body```\n\nTail\n';

void main() {
  late NoteTasksFixture fixture;

  Future<void> open(WidgetTester tester) async {
    fixture = (await tester.runAsync(
      () => NoteTasksFixture.open(todo: _todo),
    ))!;
    addTearDown(fixture.dispose);
  }

  Widget scoped(Widget child, {bool tasks = true}) => MaterialApp(
    home: Scaffold(
      body: TodoBlockScope(
        builder: tasks
            ? NoteTodoBlocks(host: fixture.host, notePath: _notePath)
            : null,
        child: child,
      ),
    ),
  );

  Future<SourceBuffer> pumpRead(
    WidgetTester tester,
    String note, {
    bool tasks = true,
  }) async {
    await open(tester);
    final buffer = SourceBuffer.fromText(note);
    await tester.pumpWidget(
      scoped(
        MarkdownReadView(
          buffer: buffer,
          parser: ReadParser(),
          mathCache: MathCache(),
        ),
        tasks: tasks,
      ),
    );
    await fixture.settle(tester);
    return buffer;
  }

  Future<MarkdownSurfaceController> pumpLive(
    WidgetTester tester,
    String note, {
    required int caret,
  }) async {
    await open(tester);
    final buffer = SourceBuffer.fromText(note);
    final surface = MarkdownSurfaceController(buffer, caret: caret);
    await tester.pumpWidget(
      scoped(
        MarkdownSurface(
          buffer: buffer,
          mode: MarkdownSurfaceMode.live,
          theme: _theme,
          showLineNumbers: false,
          mathCache: MathCache(),
          surface: surface,
        ),
      ),
    );
    await fixture.settle(tester);
    return surface;
  }

  Future<void> written(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await fixture.settle(tester);
  }

  final block = find.byKey(const Key('todo-block'));

  group('the read view', () {
    testWidgets('an empty block lists the tasks that link the note', (
      tester,
    ) async {
      await pumpRead(tester, _note(''));
      expect(block, findsOneWidget);
      expect(find.text('Tasks · linked here · 1'), findsOneWidget);
      expect(find.text('Call the plumber'), findsOneWidget);
      expect(find.text('Pay the bill'), findsNothing);
      // The fence's own words are not printed.
      expect(find.textContaining('```'), findsNothing);
      expect(find.text('Tail'), findsOneWidget);
    });

    testWidgets('link: any with filters lists the dashboard', (tester) async {
      await pumpRead(tester, _note('link: any\nproject: house\n'));
      expect(find.text('Tasks · project house · 2'), findsOneWidget);
      // The soonest due first.
      expect(
        tester.getTopLeft(find.text('Call the plumber')).dy,
        lessThan(tester.getTopLeft(find.text('Pay the bill')).dy),
      );
      expect(find.text('Elsewhere'), findsNothing);
    });

    testWidgets('a row hides the link to this note and shows the others', (
      tester,
    ) async {
      await pumpRead(tester, _note('link: any\n'));
      // `link: any` hides none: the plumber's own note is a chip.
      expect(find.text('Repairs'), findsOneWidget);
      expect(find.text('Ideas'), findsOneWidget);
    });

    testWidgets('drawing a block never rewrites the note', (tester) async {
      final note = _note('link: any\nproject: house\n');
      final buffer = await pumpRead(tester, note);
      expect(buffer.text, note);
    });

    testWidgets('a block that lists nothing says so in one line', (
      tester,
    ) async {
      await pumpRead(tester, _note('link: any\nproject: nothing\n'));
      expect(find.byKey(const Key('todo-block-empty')), findsOneWidget);
      expect(find.text('No tasks match'), findsOneWidget);
      expect(find.text('Tasks · project nothing · 0'), findsOneWidget);
    });

    testWidgets('an error is a row, and the block lists nothing', (
      tester,
    ) async {
      await pumpRead(tester, _note('link: any\nprio: A\nproject: house\n'));
      expect(
        find.text('Unknown key prio — did you mean priority?'),
        findsOneWidget,
      );
      expect(find.text('Line 2 of the block'), findsOneWidget);
      // The good lines are in the head, with no count; no task is listed.
      expect(find.text('Tasks · project house'), findsOneWidget);
      expect(find.text('Call the plumber'), findsNothing);
      expect(find.text('Pay the bill'), findsNothing);
    });

    testWidgets('every bad line has its row', (tester) async {
      await pumpRead(tester, _note('due: soon\nnothing\nsort:\n'));
      expect(find.byKey(const Key('todo-block-error-1')), findsOneWidget);
      expect(find.byKey(const Key('todo-block-error-2')), findsOneWidget);
      expect(find.byKey(const Key('todo-block-error-3')), findsOneWidget);
      expect(find.textContaining('Can’t read “soon” for due'), findsOneWidget);
    });

    testWidgets('a link to a note that is not there is a row', (tester) async {
      await pumpRead(tester, _note('link: [[Nowhere]]\n'));
      await fixture.settle(tester);
      expect(find.text('No note matches [[Nowhere]]'), findsOneWidget);
      expect(find.text('Line 1 of the block'), findsOneWidget);
    });

    testWidgets('link: [[Note]] lists the tasks of that note', (tester) async {
      await pumpRead(tester, _note('link: [[Ideas]]\n'));
      await fixture.settle(tester);
      expect(find.text('Tasks · linked to Ideas · 1'), findsOneWidget);
      expect(find.text('Elsewhere'), findsOneWidget);
      expect(find.text('Call the plumber'), findsNothing);
    });

    testWidgets('ticking a box ticks the task, and the list follows', (
      tester,
    ) async {
      await pumpRead(tester, _note('link: any\nproject: house\n'));
      await tester.tap(find.byKey(const Key('note-task-check-open-0')));
      await written(tester);
      expect(fixture.source.todoLines, hasLength(2));
      expect(fixture.source.doneLines.single, contains('Call the plumber'));
      expect(find.text('Call the plumber'), findsNothing);
      expect(find.text('Tasks · project house · 1'), findsOneWidget);
    });

    testWidgets('a tap on a task opens the task dialog', (tester) async {
      await pumpRead(tester, _note(''));
      await tester.tap(find.text('Call the plumber'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Add task is filled from the filters', (tester) async {
      await pumpRead(
        tester,
        _note('project: house\ncontext: @phone\ntag: urgent\n'),
      );
      await tester.tap(find.byKey(const Key('todo-block-add')));
      await tester.pump();
      // The link to this note after a space, as the note's own list writes it,
      // then the tokens the filters name.
      expect(fixture.added, [' [[Repairs]] +house @phone #urgent']);
    });

    testWidgets('Add task of a dashboard writes the tokens alone', (
      tester,
    ) async {
      await pumpRead(tester, _note('link: any\nproject: house\n'));
      await tester.tap(find.byKey(const Key('todo-block-add')));
      await tester.pump();
      expect(fixture.added, [' +house']);
    });

    testWidgets('Add task of a block with nothing to write opens empty', (
      tester,
    ) async {
      await pumpRead(tester, _note('link: any\n'));
      await tester.tap(find.byKey(const Key('todo-block-add')));
      await tester.pump();
      expect(fixture.added, ['']);
    });

    testWidgets('the list follows the task map', (tester) async {
      await pumpRead(tester, _note(''));
      await tester.runAsync(
        () => fixture.controller.add('New one [[Repairs]]'),
      );
      await written(tester);
      expect(find.text('New one'), findsOneWidget);
      expect(find.text('Tasks · linked here · 2'), findsOneWidget);
    });

    testWidgets('without tasks at hand the fence is the code it is', (
      tester,
    ) async {
      await pumpRead(tester, _note('link: any\n'), tasks: false);
      expect(block, findsNothing);
      expect(find.textContaining('link: any'), findsOneWidget);
    });

    testWidgets('a fence the note has not closed is code', (tester) async {
      await pumpRead(tester, 'Intro\n\n```todo\nlink: any\n');
      expect(block, findsNothing);
    });
  });

  group('live', () {
    testWidgets('with the caret outside, the list is drawn', (tester) async {
      final note = _note('link: any\nproject: house\n');
      await pumpLive(tester, note, caret: note.length);
      expect(block, findsOneWidget);
      expect(find.text('Tasks · project house · 2'), findsOneWidget);
      // The fence's lines take no room: their text is a hair high.
      expect(
        tester.getSize(find.textContaining('project: house')).height,
        lessThan(2),
      );
    });

    testWidgets('with the caret inside, the source is shown', (tester) async {
      final note = _note('link: any\nproject: house\n');
      await pumpLive(tester, note, caret: note.indexOf('project:'));
      expect(block, findsNothing);
      expect(find.textContaining('project: house'), findsOneWidget);
      expect(find.text('Call the plumber'), findsNothing);
    });

    testWidgets('the caret moving out draws the list again', (tester) async {
      final note = _note('link: any\nproject: house\n');
      final surface = await pumpLive(tester, note, caret: note.indexOf('link'));
      expect(block, findsNothing);
      surface.placeCaret(note.length);
      await tester.pump();
      expect(block, findsOneWidget);
    });

    testWidgets('an empty block is drawn once its fence is closed', (
      tester,
    ) async {
      final note = _note('');
      await pumpLive(tester, note, caret: note.length);
      expect(block, findsOneWidget);
      expect(find.text('Tasks · linked here · 1'), findsOneWidget);
    });

    testWidgets('a tap on the head puts the caret in the block', (
      tester,
    ) async {
      final note = _note('link: any\nproject: house\n');
      final surface = await pumpLive(tester, note, caret: note.length);
      await tester.tap(find.byKey(const Key('todo-block-head')));
      await tester.pump();
      expect(surface.selection.caret, note.indexOf('link: any'));
      expect(block, findsNothing);
    });

    testWidgets('a tap on an error row puts the caret on its line', (
      tester,
    ) async {
      final note = _note('link: any\nprio: A\n');
      final surface = await pumpLive(tester, note, caret: note.length);
      await tester.tap(find.byKey(const Key('todo-block-error-2')));
      await tester.pump();
      expect(surface.selection.caret, note.indexOf('prio: A'));
    });

    testWidgets('a tick in live ticks the task', (tester) async {
      final note = _note('link: any\nproject: house\n');
      await pumpLive(tester, note, caret: note.length);
      await tester.tap(find.byKey(const Key('note-task-check-open-0')));
      await written(tester);
      expect(fixture.source.doneLines.single, contains('Call the plumber'));
    });
  });
}
