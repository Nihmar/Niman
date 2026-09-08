// T-TK-04: the list-kind GUI — checkable rows, nesting, the add row.
import 'package:copist/src/ui/kinds/list_note.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(ListNoteView view) =>
    MaterialApp(home: Scaffold(body: view));

void main() {
  testWidgets('renders items; tapping a row flips the box byte-stably', (
    tester,
  ) async {
    // The host feeds the edited text back, like NoteView does (the
    // controller's text changes and the kind body re-parses).
    var text = '---\ntype: list\n---\n- [ ] one\n  - [x] two\n';
    Widget app() => _app(ListNoteView(text: text, onChanged: (t) {
          text = t;
        }));
    await tester.pumpWidget(app());
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);

    await tester.tap(find.text('one'));
    await tester.pump();
    expect(text, '---\ntype: list\n---\n- [x] one\n  - [x] two\n');

    // The host rebuilds with the new text; tapping again flips it back.
    await tester.pumpWidget(app());
    await tester.tap(find.text('one'));
    await tester.pump();
    expect(text, '---\ntype: list\n---\n- [ ] one\n  - [x] two\n');
  });

  testWidgets('nested items are indented by depth', (tester) async {
    await tester.pumpWidget(
      _app(ListNoteView(text: '- [ ] a\n  - [ ] b\n', onChanged: (_) {})),
    );
    expect(
      tester.getTopLeft(find.text('b')).dx,
      greaterThan(tester.getTopLeft(find.text('a')).dx),
    );
  });

  testWidgets('the add row appends an unchecked item', (tester) async {
    String? out;
    const text = '---\ntype: list\n---\n- [ ] one\n';
    await tester.pumpWidget(_app(ListNoteView(text: text, onChanged: (t) {
      out = t;
    })));
    await tester.enterText(find.byType(TextField), 'three');
    await tester.tap(find.byKey(const Key('list-add-button')));
    await tester.pump();
    expect(out, '---\ntype: list\n---\n- [ ] one\n- [ ] three\n');
  });

  testWidgets('a note without task items shows the empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(ListNoteView(text: '---\ntype: list\n---\n', onChanged: (_) {})),
    );
    expect(find.text(AppStrings.listEmpty), findsOneWidget);
  });

  testWidgets('prose lines are not rendered', (tester) async {
    await tester.pumpWidget(
      _app(
        ListNoteView(
          text: 'a prose line\n- [ ] one\nanother line\n',
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('one'), findsOneWidget);
    expect(find.text('a prose line'), findsNothing);
    expect(find.text('another line'), findsNothing);
  });
}
