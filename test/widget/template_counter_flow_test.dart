// #497: a template's `{{counter:…}}` is reserved once the name is known,
// so cancelling the name dialog — or a creation that fails — does not
// burn a number.
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
  late List<Route<dynamic>> pushes;
  late GlobalKey<NavigatorState> navigator;

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
    filed = [];
    pushes = [];
    navigator = GlobalKey<NavigatorState>();
  });

  tearDown(() async {
    await session.dispose();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  File counterFile() => File(p.join(dir.path, '.niman', 'counters.json'));

  testWidgets('cancelling the name dialog burns no counter', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
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
    final flow = ShellTemplateFlow(
      controller: session,
      origin: () => (selected: null, isDir: false, treeVisible: true),
      createParent: () => '',
      guard: (action) => action(),
      opensPreviewOnly: () => false,
      onNoteFiled: ({required path, required preview, required caret}) =>
          filed.add(path),
    );
    final source = (await session.templateSource)!;
    final quest = (await source.templates()).singleWhere(
      (template) => template.path == 'Templates/Quest.md',
    );

    // The whole flow runs where the counter file's own I/O can complete;
    // the picker and the name dialog are answered by popping the routes
    // the observer sees, since no frame can be pumped in here.
    await tester.runAsync(() async {
      Future<void> untilPushed(int count) async {
        while (pushes.length < count) {
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
      }

      // The home route was pushed by the first frame; only what the
      // creation itself opens is counted.
      pushes.clear();
      final cancelled = flow.createFromTemplate(context);
      await untilPushed(1);
      navigator.currentState!.pop(quest);
      await untilPushed(2);
      navigator.currentState!.pop();
      await cancelled;

      expect(filed, isEmpty);
      expect(
        counterFile().existsSync(),
        isFalse,
        reason: 'a note that was not made reserved nothing',
      );

      // The next note gets the first number, not the second.
      pushes.clear();
      final made = flow.createFromTemplate(context);
      await untilPushed(1);
      navigator.currentState!.pop(quest);
      await untilPushed(2);
      navigator.currentState!.pop('First');
      await made;

      expect(filed, ['First.md']);
      expect(session.contentOf('First.md'), '001\n');
    });
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
