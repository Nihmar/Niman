// #136: the Tools sheet and the list count's sheet.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/editor_tool.dart';
import 'package:niman/src/editor/list_tally.dart';
import 'package:niman/src/ui/editor_tools_sheet.dart';
import 'package:niman/src/ui/list_tally_sheet.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/shell_harness.dart';

/// Pumps a page whose one button opens [open] and records its answer.
Future<void> _pumpOpener<T>(
  WidgetTester tester,
  Future<T?> Function(BuildContext context) open,
  void Function(T? value) onDone,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => onDone(await open(context)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await settle(tester);
}

void main() {
  group('the tools sheet', () {
    testWidgets('offers the tool and resolves to it', (tester) async {
      EditorTool? picked;
      await _pumpOpener<EditorTool>(
        tester,
        (context) => showEditorToolsSheet(
          context,
          available: const <EditorTool>{EditorTool.countList},
        ),
        (value) => picked = value,
      );

      expect(find.byKey(const Key('editor-tools-sheet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('editor-tool-countList')));
      await settle(tester);

      expect(picked, EditorTool.countList);
    });

    testWidgets('a tool that cannot run keeps its place, with the reason', (
      tester,
    ) async {
      var returned = false;
      EditorTool? picked;
      await _pumpOpener<EditorTool>(
        tester,
        (context) =>
            showEditorToolsSheet(context, available: const <EditorTool>{}),
        (value) {
          picked = value;
          returned = true;
        },
      );

      // Listed, not dropped: a row that comes and goes is a row nobody
      // learns is there (the keep-its-place rule).
      final row = find.byKey(const Key('editor-tool-countList'));
      expect(row, findsOneWidget);
      expect(find.text(AppStrings.toolCountListNeedsList), findsOneWidget);
      expect(tester.widget<ListTile>(row).enabled, isFalse);

      await tester.tap(row);
      await settle(tester);
      expect(returned, isFalse, reason: 'the sheet should still be open');
      expect(picked, isNull);
    });
  });

  group('the count sheet', () {
    const order = <String>[
      'Alessandro -  acqua naturale, brioche',
      'Chantal - cappuccino, brioche',
      'Gerard - macchiato, brioche',
    ];

    testWidgets('previews what it would write, and hands back the choice', (
      tester,
    ) async {
      TallyChoice? choice;
      await _pumpOpener<TallyChoice>(
        tester,
        (context) => showListTallySheet(
          context,
          candidates: const <TallyCandidate>[TallyCandidate(rows: order)],
          initialIndex: 0,
        ),
        (value) => choice = value,
      );

      expect(find.byKey(const Key('list-tally-sheet')), findsOneWidget);
      // The cut was guessed from the rows, so the preview is already the
      // answer: three brioches, one of everything else.
      expect(find.text('brioche'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('acqua naturale'), findsOneWidget);
      // One list, so the source is a line rather than a picker.
      expect(find.byKey(const Key('tally-source-label')), findsOneWidget);
      expect(find.byKey(const Key('tally-source-picker')), findsNothing);
      expect(find.text(AppStrings.tallyInsert), findsOneWidget);

      await tester.tap(find.byKey(const Key('tally-apply')));
      await settle(tester);

      expect(choice?.index, 0);
      expect(choice?.cut, TallyCut.dash);
      expect(choice?.sort, TallySort.count);
    });

    testWidgets('reading the rows another way recounts the preview', (
      tester,
    ) async {
      await _pumpOpener<TallyChoice>(
        tester,
        (context) => showListTallySheet(
          context,
          candidates: const <TallyCandidate>[TallyCandidate(rows: order)],
          initialIndex: 0,
        ),
        (_) {},
      );

      await tester.tap(find.byKey(const Key('tally-cut-picker')));
      await settle(tester);
      await tester.tap(find.text(AppStrings.tallyCutWhole).last);
      await settle(tester);

      // Whole rows: nothing repeats, so every row counts once and the
      // name is part of the value.
      expect(find.text('brioche'), findsNothing);
      expect(find.text('Chantal - cappuccino, brioche'), findsOneWidget);
    });

    testWidgets('a tick carried over shows before it is committed', (
      tester,
    ) async {
      await _pumpOpener<TallyChoice>(
        tester,
        (context) => showListTallySheet(
          context,
          candidates: const <TallyCandidate>[
            TallyCandidate(
              rows: order,
              checks: <String, bool>{'brioche': true},
              replaces: true,
            ),
          ],
          initialIndex: 0,
        ),
        (_) {},
      );

      expect(find.byIcon(Icons.check_box), findsOneWidget);
      // It is replacing a block, so the button says so.
      expect(find.text(AppStrings.tallyUpdate), findsOneWidget);
      expect(find.text(AppStrings.tallyInsert), findsNothing);
    });

    testWidgets('several lists are a picker, and switching one recounts', (
      tester,
    ) async {
      TallyChoice? choice;
      await _pumpOpener<TallyChoice>(
        tester,
        (context) => showListTallySheet(
          context,
          candidates: const <TallyCandidate>[
            TallyCandidate(rows: order),
            TallyCandidate(rows: <String>['Dara - orzo', 'Ilaria - orzo']),
          ],
          initialIndex: 1,
        ),
        (value) => choice = value,
      );

      expect(find.byKey(const Key('tally-source-picker')), findsOneWidget);
      // It opened on the caret's list, the second one.
      expect(find.text('orzo'), findsOneWidget);
      expect(find.text('brioche'), findsNothing);

      await tester.tap(find.byKey(const Key('tally-source-picker')));
      await settle(tester);
      await tester.tap(find.text(order.first).last);
      await settle(tester);

      expect(find.text('brioche'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tally-apply')));
      await settle(tester);
      expect(choice?.index, 0);
    });

    testWidgets('nothing to count leaves nothing to press', (tester) async {
      await _pumpOpener<TallyChoice>(
        tester,
        (context) => showListTallySheet(
          context,
          candidates: const <TallyCandidate>[
            TallyCandidate(rows: <String>['   ']),
          ],
          initialIndex: 0,
        ),
        (_) {},
      );

      expect(find.byKey(const Key('tally-empty')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('tally-apply')))
            .enabled,
        isFalse,
      );
    });
  });
}
