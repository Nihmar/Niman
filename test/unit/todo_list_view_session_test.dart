// #1003, #1028: the view the shell builds for a library — its two failure
// branches log a warning and leave the view usable: a folded set that does
// not save, and one that does not read.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/todo_list_view_session.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() async {
    AppLog.enabled = true;
    AppLog.clear();
    session = FakeLibrarySession();
    await session.open('/fake', create: false);
  });

  tearDown(AppLog.clear);

  /// Lets the unawaited persistence futures of the view finish.
  Future<void> drain() => Future<void>.delayed(Duration.zero);

  bool logged(String text) => AppLog.lines().any(
    (line) => line.contains('WARNING') && line.contains(text),
  );

  test('a folded set that does not save is logged, and stays folded', () async {
    final view = todoListViewFor(session);
    addTearDown(view.dispose);
    await drain();
    session.failTodoCollapsedWrite = true;

    view.toggleSection('due.later');
    await drain();

    expect(logged('todo folded sections not saved'), isTrue);
    expect(view.isCollapsed('due.later'), isTrue, reason: 'the fold is kept');
    expect(await session.todoCollapsedSections, {'done'}, reason: 'not saved');
  });

  test(
    'a folded set that does not read is logged, and Done stays folded',
    () async {
      session.failTodoCollapsedRead = true;

      final view = todoListViewFor(session);
      addTearDown(view.dispose);
      await drain();

      expect(logged('todo folded sections not read'), isTrue);
      expect(view.collapsed, {'done'}, reason: 'the default stands');
    },
  );

  test('a stored set replaces the default, and nothing is logged', () async {
    await session.setTodoCollapsedSections({'due.later'});

    final view = todoListViewFor(session);
    addTearDown(view.dispose);
    await drain();

    expect(view.collapsed, {'due.later'});
    expect(logged('todo folded sections'), isFalse);
  });
}
