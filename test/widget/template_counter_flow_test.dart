// #497: a template's `{{counter:…}}` does not burn a number when the note is
// not made — the name dialog is cancelled, or the creation fails after the
// number was reserved on disk.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/shell_template_flow.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

void main() {
  late Directory dir;
  late FakeLibrarySession session;
  late List<String> filed;
  late List<Object> errors;
  late List<Route<dynamic>> pushes;
  late GlobalKey<NavigatorState> navigator;
  late ShellTemplateFlow flow;
  late BuildContext context;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_template_counter_');
    session = FakeLibrarySession();
    await session.open(dir.path, create: true);
    await session.ensureFolder('Templates');
    await session.createNote(
      parentPath: 'Templates',
      name: 'Quest',
      content: '{{counter:quest|pad:3}}\n',
    );
    // A template that names its note, with the number in the name: no name
    // dialog, and the number is reserved before anything is created.
    await session.createNote(
      parentPath: 'Templates',
      name: 'Numbered',
      content:
          '---\nniman:\n  filename: "Quest {{counter:quest|pad:3}}"\n---\n'
          'body {{counter:quest}}\n',
    );
    filed = [];
    errors = [];
    pushes = [];
    navigator = GlobalKey<NavigatorState>();
    flow = ShellTemplateFlow(
      controller: session,
      origin: () => (selected: null, isDir: false, treeVisible: true),
      createParent: () => '',
      // What the shell's guard does with a failure: report it, and go on.
      guard: (action) async {
        try {
          await action();
        } on Object catch (error) {
          errors.add(error);
        }
      },
      opensPreviewOnly: () => false,
      onNoteFiled: ({required path, required preview, required caret}) =>
          filed.add(path),
    );
  });

  tearDown(() async {
    await session.dispose();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  File counterFile() => File(p.join(dir.path, '.niman', 'counters.json'));

  /// The number the file holds for `quest`, or 0 when it holds none.
  int reached() {
    if (!counterFile().existsSync()) return 0;
    final text = counterFile().readAsStringSync();
    final match = RegExp(r'"quest":\s*(\d+)').firstMatch(text);
    return match == null ? 0 : int.parse(match.group(1)!);
  }

  Future<void> pumpHost(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      navigatorObservers: [_PushLog(pushes)],
      home: Scaffold(
        body: Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );

  /// Runs one creation from [templateName], answering the picker with it and
  /// the name dialog (when the template has one) with [name] — null cancels
  /// it. The whole flow runs where the counter file's own I/O can complete:
  /// no frame can be pumped in here, so the routes the observer sees are
  /// popped instead.
  Future<void> create(
    WidgetTester tester,
    String templateName, {
    String? name,
    bool asks = true,
  }) async {
    final source = (await session.templateSource)!;
    final template = (await source.templates()).singleWhere(
      (t) => t.path == 'Templates/$templateName.md',
    );
    await tester.runAsync(() async {
      Future<void> untilPushed(int count) async {
        while (pushes.length < count) {
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
      }

      // The home route was pushed by the first frame; only what the
      // creation itself opens is counted.
      pushes.clear();
      final made = flow.createFromTemplate(context);
      await untilPushed(1);
      navigator.currentState!.pop(template);
      if (asks) {
        await untilPushed(2);
        navigator.currentState!.pop(name);
      }
      await made;
    });
  }

  testWidgets('cancelling the name dialog burns no counter', (tester) async {
    await pumpHost(tester);
    await create(tester, 'Quest');
    expect(filed, isEmpty);
    expect(
      counterFile().existsSync(),
      isFalse,
      reason: 'a note that was not made reserved nothing',
    );

    // The next note gets the first number, not the second.
    await create(tester, 'Quest', name: 'First');
    expect(filed, ['First.md']);
    expect(session.contentOf('First.md'), '001\n');
  });

  testWidgets('a creation that fails gives its number back', (tester) async {
    await pumpHost(tester);
    session.createNoteError = const FileSystemException('disk full');
    await create(tester, 'Quest', name: 'First');
    expect(errors.single, isA<FileSystemException>());
    expect(filed, isEmpty);
    expect(reached(), 0, reason: 'the number reserved was handed back');

    session.createNoteError = null;
    await create(tester, 'Quest', name: 'First');
    expect(filed, ['First.md']);
    expect(session.contentOf('First.md'), '001\n');
    expect(reached(), 1);
  });

  testWidgets('a template naming its note gives the number back too', (
    tester,
  ) async {
    await pumpHost(tester);
    session.createNoteError = const FileSystemException('disk full');
    await create(tester, 'Numbered', asks: false);
    expect(errors.single, isA<FileSystemException>());
    expect(reached(), 0);

    session.createNoteError = null;
    await create(tester, 'Numbered', asks: false);
    expect(filed, ['Quest 001.md']);
    expect(session.contentOf('Quest 001.md'), 'body 1\n');
  });
}

/// The routes pushed on the navigator, in order: the picker is the first
/// of a creation, the name dialog the one that follows it.
final class _PushLog extends NavigatorObserver {
  new(this.pushed);

  final List<Route<dynamic>> pushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}
