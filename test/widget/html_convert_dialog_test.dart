// The question a web page's conversion asks (#1293): what the page is
// called, where it goes, and the pages of a drop of several asked about at
// once.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/html_convert_dialog.dart';
import 'package:niman/src/ui/strings.dart';

void main() {
  Future<HtmlConvertChoice?> ask(
    WidgetTester tester, {
    List<String> sources = const ['/web/Dune.html'],
    String? name,
    String parent = 'Web',
    Future<String?> Function(String current)? pickFolder,
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

  testWidgets('names the page and starts in its folder', (tester) async {
    final choice = await ask(
      tester,
      act: () async {
        expect(find.text('Dune.html'), findsOneWidget);
        expect(find.text('Web'), findsOneWidget);
        await tester.tap(find.byKey(const Key('html-convert-start')));
      },
    );
    expect(choice, (parent: 'Web'));
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
    expect(choice, (parent: 'Archive/Web'));
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
    expect(choice, (parent: 'Web'));
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
    expect(choice, (parent: 'Web'));
  });

  testWidgets('Cancel answers nothing', (tester) async {
    final choice = await ask(
      tester,
      act: () => tester.tap(find.byKey(const Key('html-convert-cancel'))),
    );
    expect(choice, isNull);
  });
}
