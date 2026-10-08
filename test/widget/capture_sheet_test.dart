// The phone's capture sheet (#531): a page shared from the browser, or an
// address typed from New, is read as soon as it is known — the sheet then
// says how many pictures it has — and Save hands the reading, done or not,
// to the background capture with the folder, the title and the tags
// chosen. The reading is the test's own, so no network is in the way.
//
// The page is written in pieces of HTML, which run on without spaces.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/page_reading.dart';
import 'package:niman/src/capture/shared_page.dart';
import 'package:niman/src/capture/web_capture.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/ui/capture/capture_dialog.dart';
import 'package:niman/src/ui/capture/capture_sheet.dart';

final Uri _url = Uri.parse('https://example.com/garden');

WebReading _reading({int pictures = 2}) => (
  page: readPage(
    '<html><head><title>Tending a winter garden</title></head>'
    '<body><article><p>Kale and leeks.</p></article></body></html>',
    _url,
  ),
  bytes: 1024,
  ranBrowser: false,
  pictures: [for (var i = 0; i < pictures; i++) 'https://example.com/$i.png'],
);

void main() {
  late List<Uri> read;
  late Completer<WebReading> page;

  setUp(() => read = []);

  CaptureTarget target() => CaptureTarget(
    libraryRoot: '/library',
    attachmentsFolder: 'assets',
    linkType: LinkType.wikilink,
    folder: 'Reading',
    pickFolder: (current) async => 'Reading/Articles',
    create: (folder, name, text) async => '$folder/$name.md',
    read: (url, {browser, onProgress}) {
      read.add(url);
      return page.future;
    },
  );

  /// What the sheet last opened closes with.
  late Future<CaptureSheetResult?> closed;

  /// Opens the sheet from a button.
  Future<void> open(WidgetTester tester, {WebShare? share, Uri? url}) async {
    // Made in the test's zone, so the test's pumps complete it.
    page = Completer<WebReading>();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => closed = showCaptureSheet(
              context,
              target: target(),
              share: share,
              url: url,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  String title(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(const Key('capture-sheet-title')))
      .controller!
      .text;

  testWidgets('a shared page is read at once and saved as chosen', (
    tester,
  ) async {
    await open(tester, share: SharedPage(_url, title: 'From the browser'));
    expect(find.text('Save to Niman'), findsOne);
    expect(read, [_url]);
    expect(title(tester), 'From the browser');
    expect(find.text('Download its images to assets/'), findsOne);

    page.complete(_reading());
    await tester.pumpAndSettle();
    // The share's title stays: it is the one the user saw.
    expect(title(tester), 'From the browser');
    expect(find.text('Download the 2 images to assets/'), findsOne);

    await tester.tap(find.byKey(const Key('capture-sheet-folder')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-sheet-pictures')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('capture-sheet-save')));
    await tester.pumpAndSettle();

    final chosen = await closed;
    expect(chosen, isA<CapturePageChosen>());
    final page_ = chosen! as CapturePageChosen;
    expect(page_.reading.url, _url);
    expect(page_.reading.done, isNotNull);
    expect(page_.chosen.folder, 'Reading/Articles');
    expect(page_.chosen.title, 'From the browser');
    expect(page_.chosen.tags, ['web']);
    expect(page_.chosen.downloadPictures, isFalse);
    page_.reading.dispose();
  });

  testWidgets('Save before the page is read hands the reading on', (
    tester,
  ) async {
    await open(tester, share: SharedPage(_url));
    expect(title(tester), isEmpty);
    await tester.tap(find.byKey(const Key('capture-sheet-save')));
    await tester.pumpAndSettle();
    final chosen = (await closed)! as CapturePageChosen;
    expect(chosen.reading.done, isNull);
    expect(chosen.chosen.title, isNull);
    page.complete(_reading());
    expect((await chosen.reading.result).page.title, 'Tending a winter garden');
    chosen.reading.dispose();
  });

  testWidgets('a page with no pictures keeps the row, disabled', (
    tester,
  ) async {
    await open(tester, url: _url);
    page.complete(_reading(pictures: 0));
    await tester.pumpAndSettle();
    // From New, the page's own title fills the field once it is read.
    expect(title(tester), 'Tending a winter garden');
    final row = tester.widget<CheckboxListTile>(
      find.byKey(const Key('capture-sheet-pictures')),
    );
    expect(row.onChanged, isNull);
    expect(row.value, isFalse);
  });

  testWidgets('from New, an address is typed, and a wrong one said', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Capture web page'), findsOne);
    expect(read, isEmpty);
    await tester.enterText(
      find.byKey(const Key('capture-sheet-address')),
      'example.com',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.byKey(const Key('capture-sheet-error')), findsOne);
    expect(read, isEmpty);

    await tester.enterText(
      find.byKey(const Key('capture-sheet-address')),
      _url.toString(),
    );
    await tester.pump();
    expect(find.byKey(const Key('capture-sheet-error')), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(read, [_url]);
  });

  testWidgets('a page that cannot be had is said, and Save reads it again', (
    tester,
  ) async {
    await open(tester, share: SharedPage(_url));
    page.completeError(const PageFetchException(PageFetchFailure.network));
    await tester.pumpAndSettle();
    expect(
      find.text('The page could not be reached: check the connection.'),
      findsOne,
    );
    page = Completer<WebReading>();
    await tester.tap(find.byKey(const Key('capture-sheet-save')));
    await tester.pumpAndSettle();
    expect(read, [_url, _url]);
    final chosen = (await closed)! as CapturePageChosen;
    chosen.reading.dispose();
  });
}
