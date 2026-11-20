// The question a web page's conversion asks (#1293, #1294): what the page is
// called, where it goes, how it is cut when it is a book, and the pages of a
// drop of several asked about at once.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/import/book/book_plan.dart';
import 'package:niman/src/import/html/html_conversion.dart';
import 'package:niman/src/ui/html_convert_dialog.dart';
import 'package:niman/src/ui/strings.dart';

Future<HtmlBookPreview?> _noBook(
  String source,
  BookWords words, {
  String? name,
}) async => null;

void main() {
  Future<HtmlConvertChoice?> ask(
    WidgetTester tester, {
    List<String> sources = const ['/web/Dune.html'],
    String? name,
    String parent = 'Web',
    Future<String?> Function(String current)? pickFolder,
    HtmlPreviewer preview = _noBook,
    Future<void> Function()? act,
  }) async {
    HtmlConvertChoice? answer;
    var answered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                answer = await showHtmlConvertDialog(
                  context,
                  sources: sources,
                  name: name,
                  parent: parent,
                  pickFolder: pickFolder,
                  preview: preview,
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
    // A page being read shows a spinner, which never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await act?.call();
    await tester.pumpAndSettle();
    expect(answered, isTrue);
    return answer;
  }

  testWidgets('names the page and starts in its folder', (tester) async {
    final choice = await ask(
      tester,
      act: () async {
        expect(find.text('Dune.html'), findsOneWidget);
        expect(find.text('Web'), findsOneWidget);
        await tester.tap(find.byKey(const Key('html-convert-start')));
      },
    );
    expect(choice, (parent: 'Web', book: null));
  });

  testWidgets('a share is named as it came, not by its copy', (tester) async {
    await ask(
      tester,
      sources: const ['/cache/1700000000-Dune.html'],
      name: 'Dune.html',
      act: () async {
        expect(find.text('Dune.html'), findsOneWidget);
        expect(find.textContaining('1700000000'), findsNothing);
        await tester.tap(find.byKey(const Key('html-convert-cancel')));
      },
    );
  });

  testWidgets('the top of the library is named as such', (tester) async {
    await ask(
      tester,
      parent: '',
      act: () async {
        expect(find.text(AppStrings.libraryRoot), findsOneWidget);
        await tester.tap(find.byKey(const Key('html-convert-cancel')));
      },
    );
  });

  testWidgets('another folder can be picked', (tester) async {
    String? from;
    final choice = await ask(
      tester,
      pickFolder: (current) async {
        from = current;
        return 'Archive/Web';
      },
      act: () async {
        await tester.tap(find.byKey(const Key('html-convert-folder')));
        await tester.pumpAndSettle();
        expect(find.text('Archive/Web'), findsOneWidget);
        await tester.tap(find.byKey(const Key('html-convert-start')));
      },
    );
    expect(from, 'Web');
    expect(choice, (parent: 'Archive/Web', book: null));
  });

  testWidgets('a folder picker dismissed keeps the folder', (tester) async {
    final choice = await ask(
      tester,
      pickFolder: (_) async => null,
      act: () async {
        await tester.tap(find.byKey(const Key('html-convert-folder')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('html-convert-start')));
      },
    );
    expect(choice, (parent: 'Web', book: null));
  });

  testWidgets('several pages are counted and listed, asked once', (
    tester,
  ) async {
    final choice = await ask(
      tester,
      sources: const ['/a/One.html', '/a/Two.htm', '/b/Three.xhtml'],
      act: () async {
        expect(find.text(AppStrings.htmlConvertMany(3)), findsOneWidget);
        for (final name in ['One.html', 'Two.htm', 'Three.xhtml']) {
          expect(find.text(name), findsOneWidget);
        }
        await tester.tap(find.byKey(const Key('html-convert-start')));
      },
    );
    expect(choice, (parent: 'Web', book: null));
  });

  testWidgets('Cancel answers nothing', (tester) async {
    final choice = await ask(
      tester,
      act: () => tester.tap(find.byKey(const Key('html-convert-cancel'))),
    );
    expect(choice, isNull);
  });

  group('a page that is a book', () {
    Future<HtmlBookPreview?> book(
      String source,
      BookWords words, {
      String? name,
    }) async =>
        (title: 'The Novel', authors: ['Ada', 'Bo'], notes: 24, folders: 0);

    testWidgets('says what it found and offers the two ways to cut it', (
      tester,
    ) async {
      final choice = await ask(
        tester,
        preview: book,
        act: () async {
          expect(find.byKey(const Key('html-convert-book-title')), findsOne);
          expect(find.text('The Novel'), findsOneWidget);
          expect(find.text('Ada, Bo'), findsOneWidget);
          expect(find.text(AppStrings.convertPerChapter), findsOneWidget);
          expect(
            find.text(AppStrings.convertPerChapterDetail(24, 0)),
            findsOneWidget,
          );
          expect(find.text(AppStrings.convertOneNote), findsOneWidget);
          await tester.tap(find.byKey(const Key('html-convert-start')));
        },
      );
      // A note a chapter is what a book is converted to, unless asked not.
      expect(choice, (parent: 'Web', book: HtmlBookSplit.chapters));
    });

    testWidgets('can be one note instead', (tester) async {
      final choice = await ask(
        tester,
        preview: book,
        act: () async {
          await tester.tap(find.byKey(const Key('html-convert-one-note')));
          await tester.pump();
          await tester.tap(find.byKey(const Key('html-convert-start')));
        },
      );
      expect(choice, (parent: 'Web', book: HtmlBookSplit.oneNote));
    });

    testWidgets('of one chapter starts as one note', (tester) async {
      final choice = await ask(
        tester,
        preview: (source, words, {name}) async =>
            (title: 'One Shot', authors: <String>[], notes: 1, folders: 0),
        act: () => tester.tap(find.byKey(const Key('html-convert-start'))),
      );
      expect(choice, (parent: 'Web', book: HtmlBookSplit.oneNote));
    });

    testWidgets('asks where it goes as a page does', (tester) async {
      final choice = await ask(
        tester,
        preview: book,
        pickFolder: (_) async => 'Books',
        act: () async {
          await tester.tap(find.byKey(const Key('html-convert-folder')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('html-convert-start')));
        },
      );
      expect(choice, (parent: 'Books', book: HtmlBookSplit.chapters));
    });

    testWidgets('is waited for: Convert is not offered before it is read', (
      tester,
    ) async {
      final read = Completer<HtmlBookPreview?>();
      final choice = await ask(
        tester,
        preview: (source, words, {name}) => read.future,
        act: () async {
          expect(find.byKey(const Key('html-convert-reading')), findsOne);
          final start = tester.widget<FilledButton>(
            find.byKey(const Key('html-convert-start')),
          );
          expect(start.onPressed, isNull);
          read.complete(null);
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('html-convert-reading')), findsNothing);
          await tester.tap(find.byKey(const Key('html-convert-start')));
        },
      );
      expect(choice, (parent: 'Web', book: null));
    });
  });

  testWidgets('a page that cannot be read is converted as a page', (
    tester,
  ) async {
    final choice = await ask(
      tester,
      preview: (source, words, {name}) => throw const FormatException('x'),
      act: () => tester.tap(find.byKey(const Key('html-convert-start'))),
    );
    expect(choice, (parent: 'Web', book: null));
  });

  testWidgets('several pages are not read for books', (tester) async {
    var asked = 0;
    await ask(
      tester,
      sources: const ['/a/One.html', '/a/Two.html'],
      preview: (source, words, {name}) async {
        asked++;
        return null;
      },
      act: () => tester.tap(find.byKey(const Key('html-convert-start'))),
    );
    expect(asked, 0);
  });
}
