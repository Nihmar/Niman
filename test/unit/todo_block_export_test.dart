// A `todo` fence in an export (#1152): the list it is at the moment of the
// export, ☐ and ☑ as text, links by their labels; the source is not printed;
// a block with errors prints its error lines; a fence nobody asked the tasks
// about stays the code it is.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/epub_note.dart';
import 'package:niman/src/export/export_note.dart';
import 'package:niman/src/export/export_sources.dart';
import 'package:niman/src/export/note_html.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/export/printed_todo_block.dart';
import 'package:niman/src/ui/export_todo_blocks.dart';
import 'package:path/path.dart' as p;

import '../fakes/note_tasks_fixture.dart';

String _note(String body) => 'Intro\n\n```todo\n$body```\n\nTail\n';

const String _path = 'House/Repairs.md';

void main() {
  late NoteTasksFixture fixture;

  Future<PrintedTodoBlocks> printed(String text) async {
    fixture = await NoteTasksFixture.open(
      todo: [
        'Call the plumber [[House/Repairs]] +house due:2026-09-08',
        '(A) Pay the bill +house',
        'Elsewhere [[Ideas]] +garden',
      ],
      done: ['x 2026-09-01 2026-08-30 Fix the tap [[Repairs]] +house'],
    );
    addTearDown(fixture.dispose);
    return await ExportTodoBlocks(fixture.host).of(text: text, notePath: _path);
  }

  String body(String text, PrintedTodoBlocks blocks) =>
      NoteHtml(NoteHtmlSource(text: text, title: 't', todoBlocks: blocks))
          .body();

  group('the sources of a note', () {
    test('are its closed todo fences, in order', () {
      final sources = ExportSources.todoBlockSources(
        '```todo\nlink: any\n```\n\n```dart\nx\n```\n\n- item\n\n'
        '  ```todo\n  project: a\n  ```\n\n```todo\nopen forever\n',
      );
      expect(sources, ['link: any', 'project: a']);
    });

    test('the key ignores the indent and the blank lines', () {
      expect(
        todoBlockKey('  link: any\n\n  due: today  \n'),
        'link: any\ndue: today',
      );
    });
  });

  group('what the tasks say', () {
    test(
      'an empty block is the tasks that link the note, open then done',
      () async {
        final blocks = await printed(_note(''));
        final block = blocks[todoBlockKey('')]!;
        expect(block.head, 'Tasks · linked here · 1');
        expect(block.tasks, [
          (
            done: false,
            text: 'Call the plumber Repairs +house — Due 2026-09-08',
          ),
        ]);
        expect(block.problems, isEmpty);
        expect(block.empty, isNull);
      },
    );

    test('links are their labels, never their syntax', () async {
      final blocks = await printed(_note('link: any\ndone: all\n'));
      final texts = [
        for (final task in blocks[todoBlockKey('link: any\ndone: all')]!.tasks)
          task.text,
      ];
      expect(
        texts,
        contains('Call the plumber Repairs +house — Due 2026-09-08'),
      );
      expect(texts, contains('(A) Pay the bill +house'));
      expect(texts.any((text) => text.contains('[[')), isFalse);
      expect(texts.last, startsWith('Fix the tap Repairs'));
    });

    test('a block with an error prints its error lines and no task', () async {
      final blocks = await printed(_note('prio: A\nproject: house\n'));
      final block = blocks[todoBlockKey('prio: A\nproject: house')]!;
      expect(block.tasks, isEmpty);
      expect(block.problems, [
        'Unknown key prio — did you mean priority? — Line 1 of the block',
      ]);
      expect(block.head, 'Tasks · linked here · project house');
    });

    test('a block that lists nothing says so', () async {
      final blocks = await printed(_note('link: any\nproject: nothing\n'));
      final block = blocks[todoBlockKey('link: any\nproject: nothing')]!;
      expect(block.tasks, isEmpty);
      expect(block.empty, 'No tasks match');
    });

    test('a note with no todo fence asks the tasks nothing', () async {
      expect(await printed('# Title\n\nText\n'), isEmpty);
    });
  });

  group('the HTML page', () {
    test('prints the list, not the source', () async {
      final text = _note('link: any\nproject: house\ndone: all\n');
      final html = body(text, await printed(text));
      expect(html, contains('class="todo-block"'));
      expect(html, contains('<strong>Tasks</strong> · project house'));
      expect(html, contains('☐ (A) Pay the bill +house'));
      expect(html, contains('class="todo-task todo-done">☑ Fix the tap'));
      expect(html, isNot(contains('link: any')));
      expect(html, isNot(contains('<pre')));
      expect(html, contains('<p>Tail</p>'));
    });

    test('prints the error lines of a block with errors', () async {
      final text = _note('prio: A\n');
      final html = body(text, await printed(text));
      expect(html, contains('todo-failed'));
      expect(
        html,
        contains('<li>Unknown key prio — did you mean priority? — Line 1'),
      );
      expect(html, isNot(contains('todo-task')));
    });

    test('a block that lists nothing prints one line', () async {
      final text = _note('link: any\nproject: nothing\n');
      expect(
        body(text, await printed(text)),
        contains('<p class="todo-empty">No tasks match</p>'),
      );
    });

    test('a fence nobody asked about is the code it is', () {
      final html = body(_note('link: any\n'), const {});
      expect(html, contains('<pre'));
      expect(html, contains('<span class="hljs-attr">link</span>'));
      expect(html, isNot(contains('todo-block')));
    });

    test('a fence the note never closed is code', () async {
      const text = 'Intro\n\n```todo\nlink: any\n';
      final html = body(text, await printed(_note('link: any\n')));
      expect(html, isNot(contains('todo-block')));
    });

    test('a fence in a list item is found by its source', () async {
      final blocks = await printed(_note('link: any\n'));
      final html = body('- item\n\n  ```todo\n  link: any\n  ```\n', blocks);
      expect(html, contains('todo-block'));
    });

    test('exportNote writes it into the file', () async {
      final text = _note('link: any\nproject: house\n');
      final payload = await exportNote(
        text: text,
        title: 'T',
        path: _path,
        root: '/lib',
        language: 'en',
        format: ExportFileFormat.html,
        todoBlocks: await printed(text),
      );
      final page = utf8.decode(payload.bytes);
      expect(page, contains('class="todo-block"'));
      expect(page, contains('☐ (A) Pay the bill'));
      expect(page, isNot(contains('project: house')));
      expect(page, contains('.todo-block {'));
    });
  });

  test('the EPUB chapter prints it too', () async {
    final root = await Directory.current.createTemp('niman_todo_epub_');
    addTearDown(() => root.delete(recursive: true));
    final text = _note('link: any\nproject: house\n');
    final payload = await exportNoteEpub(
      text: text,
      title: 'T',
      path: _path,
      root: root.path,
      language: 'en',
      todoBlocks: await printed(text),
    );
    final file = p.join(root.path, 'out.epub');
    await File(file).writeAsBytes(payload.bytes);
    final archive = ZipDecoder().decodeBytes(File(file).readAsBytesSync());
    final chapter = utf8.decode(
      archive.findFile('OEBPS/text/note.xhtml')!.content as List<int>,
    );
    expect(chapter, contains('class="todo-block"'));
    expect(chapter, contains('☐ (A) Pay the bill'));
    expect(chapter, isNot(contains('link: any')));
  });
}
