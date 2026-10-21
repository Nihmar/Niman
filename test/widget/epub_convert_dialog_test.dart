// The question a book's conversion asks (#1138): what each choice makes,
// which one it starts on, where the book goes, and a book it cannot
// convert saying why.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_archive.dart';
import 'package:niman/src/epub/epub_convert_job.dart';
import 'package:niman/src/ui/epub_convert_dialog.dart';
import 'package:niman/src/ui/strings.dart';

void main() {
  EpubConvertPreview preview({int notes = 12, int folders = 3}) => (
    title: 'Dune',
    authors: const ['Frank Herbert'],
    notes: notes,
    folders: folders,
    pictures: 2,
  );

  Future<EpubConvertChoice?> ask(
    WidgetTester tester, {
    required EpubPreviewer read,
    Future<String?> Function(String current)? pickFolder,
    Future<void> Function()? act,
  }) async {
    EpubConvertChoice? answer;
    var answered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                answer = await showEpubConvertDialog(
                  context,
                  source: '/books/Dune.epub',
                  parent: 'Books',
                  preview: read,
                  pickFolder: pickFolder,
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

  testWidgets(
    'a book of chapters starts on a note a chapter, into its folder',
    (tester) async {
      final choice = await ask(
        tester,
        read: (_, _) async => preview(),
        act: () async {
          expect(find.text('Dune'), findsOneWidget);
          expect(find.text('Frank Herbert'), findsOneWidget);
          expect(
            find.text(AppStrings.epubConvertPerChapterDetail(12, 3)),
            findsOneWidget,
          );
          expect(find.text('Books'), findsOneWidget);
          await tester.tap(find.byKey(const Key('epub-convert-start')));
        },
      );
      expect(choice, (oneNote: false, parent: 'Books'));
    },
  );

  testWidgets('one note and another folder are what it answers when picked', (
    tester,
  ) async {
    final choice = await ask(
      tester,
      read: (_, _) async => preview(),
      pickFolder: (current) async => 'Reading',
      act: () async {
        await tester.tap(find.byKey(const Key('epub-convert-one-note')));
        await tester.tap(find.byKey(const Key('epub-convert-folder')));
        await tester.pumpAndSettle();
        expect(find.text('Reading'), findsOneWidget);
        await tester.tap(find.byKey(const Key('epub-convert-start')));
      },
    );
    expect(choice, (oneNote: true, parent: 'Reading'));
  });

  testWidgets('a book of one chapter starts on one note', (tester) async {
    final choice = await ask(
      tester,
      read: (_, _) async => preview(notes: 1, folders: 0),
      act: () => tester.tap(find.byKey(const Key('epub-convert-start'))),
    );
    expect(choice?.oneNote, isTrue);
  });

  testWidgets('a protected book says so, and offers nothing to start', (
    tester,
  ) async {
    final choice = await ask(
      tester,
      read: (_, _) async =>
          throw const EpubRefused(EpubRefusal.protected, 'drm'),
      act: () async {
        expect(find.text(AppStrings.epubConvertProtected), findsOneWidget);
        expect(find.byKey(const Key('epub-convert-start')), findsNothing);
        await tester.tap(find.text(AppStrings.actionCancel));
      },
    );
    expect(choice, isNull);
  });
}
