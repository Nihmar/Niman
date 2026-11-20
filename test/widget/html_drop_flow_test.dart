// What a web page dropped on the window becomes (#1293): the dialog's three
// choices, the two that attach disabled — and saying why — with no note to
// attach to, and what each choice does.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/html_convert_flow.dart';
import 'package:niman/src/ui/html_drop_dialog.dart';
import 'package:niman/src/ui/html_drop_flow.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  Future<HtmlDropChoice?> ask(
    WidgetTester tester, {
    required bool canAttach,
    List<String> paths = const ['/downloads/Dune.html'],
    Future<void> Function()? act,
  }) async {
    HtmlDropChoice? answer;
    var answered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                answer = await showHtmlDropDialog(
                  context,
                  paths: paths,
                  canAttach: canAttach,
                );
                answered = true;
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await act?.call();
    await tester.pumpAndSettle();
    expect(answered, isTrue);
    return answer;
  }

  group('the dialog', () {
    for (final (key, choice) in <(String, HtmlDropChoice)>[
      ('html-drop-convert', HtmlDropChoice.convert),
      ('html-drop-attach', HtmlDropChoice.attach),
      ('html-drop-both', HtmlDropChoice.both),
    ]) {
      testWidgets('with a note open, $key answers ${choice.name}', (
        tester,
      ) async {
        final answer = await ask(
          tester,
          canAttach: true,
          act: () async {
            expect(find.text('Dune.html'), findsOneWidget);
            expect(
              tester
                  .widget<Visibility>(
                    find.ancestor(
                      of: find.byKey(const Key('html-drop-needs-note')),
                      matching: find.byType(Visibility),
                    ),
                  )
                  .visible,
              isFalse,
            );
            await tester.tap(find.byKey(Key(key)));
          },
        );
        expect(answer, choice);
      });
    }

    testWidgets('with no note, the two that attach are disabled and keep '
        'their place, with the reason', (tester) async {
      final both = find.byKey(const Key('html-drop-both'));
      final attach = find.byKey(const Key('html-drop-attach'));
      late Offset attachAt;
      late Offset bothAt;
      final answer = await ask(
        tester,
        canAttach: false,
        act: () async {
          expect(tester.widget<ListTile>(attach).enabled, isFalse);
          expect(tester.widget<ListTile>(both).enabled, isFalse);
          expect(
            tester
                .widget<ListTile>(find.byKey(const Key('html-drop-convert')))
                .enabled,
            isTrue,
          );
          expect(
            tester
                .widget<Visibility>(
                  find.ancestor(
                    of: find.byKey(const Key('html-drop-needs-note')),
                    matching: find.byType(Visibility),
                  ),
                )
                .visible,
            isTrue,
          );
          expect(find.text(AppStrings.htmlDropNeedsNote), findsOneWidget);
          attachAt = tester.getTopLeft(attach);
          bothAt = tester.getTopLeft(both);
          // A tap on a disabled choice answers nothing.
          await tester.tap(attach, warnIfMissed: false);
          await tester.tap(both, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('html-drop-dialog')), findsOneWidget);
          await tester.tap(find.byKey(const Key('html-drop-convert')));
        },
      );
      expect(answer, HtmlDropChoice.convert);
      // The same dialog with a note has them where they were.
      await tester.pumpWidget(const SizedBox());
      await ask(
        tester,
        canAttach: true,
        act: () async {
          expect(tester.getTopLeft(attach), attachAt);
          expect(tester.getTopLeft(both), bothAt);
          await tester.tap(find.byKey(const Key('html-drop-cancel')));
        },
      );
    });

    testWidgets('several pages are counted and listed', (tester) async {
      await ask(
        tester,
        canAttach: true,
        paths: const ['/a/One.html', '/a/Two.htm'],
        act: () async {
          expect(find.text(AppStrings.htmlConvertMany(2)), findsOneWidget);
          expect(find.text('One.html'), findsOneWidget);
          expect(find.text('Two.htm'), findsOneWidget);
          await tester.tap(find.byKey(const Key('html-drop-cancel')));
        },
      );
    });

    testWidgets('Cancel answers nothing', (tester) async {
      final answer = await ask(
        tester,
        canAttach: true,
        act: () => tester.tap(find.byKey(const Key('html-drop-cancel'))),
      );
      expect(answer, isNull);
    });
  });

  group('the flow', () {
    late FakeLibrarySession session;
    late List<List<String>> attached;
    late bool canAttach;
    late bool attachWorks;

    Future<void> drop(
      WidgetTester tester,
      List<String> paths,
      String choiceKey,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => unawaited(
                  HtmlDropFlow(
                    convert: HtmlConvertFlow(
                      session: session,
                      reveal: (_) {},
                      open: (_) {},
                      // No page to read: none is a book.
                      preview: (source, words, {name}) async => null,
                    ),
                    attach: (paths) async {
                      attached.add(paths);
                      return attachWorks;
                    },
                    canAttach: () => canAttach,
                  ).run(context, paths),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(choiceKey)));
      await tester.pumpAndSettle();
    }

    setUp(() {
      attached = [];
      canAttach = true;
      attachWorks = true;
    });

    Future<void> openLibrary() async {
      session = FakeLibrarySession();
      await session.open('/library', create: true);
    }

    testWidgets('Attach attaches the files and converts nothing', (
      tester,
    ) async {
      await openLibrary();
      await drop(tester, ['/d/One.html', '/d/Two.html'], 'html-drop-attach');
      expect(attached, [
        ['/d/One.html', '/d/Two.html'],
      ]);
      expect(find.byKey(const Key('html-convert-dialog')), findsNothing);
    });

    testWidgets('Convert converts, asking where, and attaches nothing', (
      tester,
    ) async {
      await openLibrary();
      await drop(tester, ['/d/One.html'], 'html-drop-convert');
      expect(attached, isEmpty);
      expect(find.byKey(const Key('html-convert-dialog')), findsOneWidget);
    });

    testWidgets('Attach and convert attaches first, then converts', (
      tester,
    ) async {
      await openLibrary();
      await drop(tester, ['/d/One.html'], 'html-drop-both');
      expect(attached, [
        ['/d/One.html'],
      ]);
      expect(find.byKey(const Key('html-convert-dialog')), findsOneWidget);
    });

    testWidgets('a note gone meanwhile says so, and Attach and convert goes '
        'on to convert', (tester) async {
      await openLibrary();
      attachWorks = false;
      await drop(tester, ['/d/One.html'], 'html-drop-both');
      expect(find.textContaining('One.html'), findsWidgets);
      expect(find.byKey(const Key('html-convert-dialog')), findsOneWidget);
    });
  });
}
