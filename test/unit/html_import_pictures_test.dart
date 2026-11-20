// The pictures of an imported HTML page (#1293): where each `src` names, and
// the store they are kept in, named by their content.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/capture_pictures.dart';
import 'package:niman/src/import/html/html_picture_source.dart';
import 'package:niman/src/import/html/html_picture_store.dart';
import 'package:path/path.dart' as p;

const List<int> _png = [137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3];

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('niman_html_pics_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  group('where a src is', () {
    late Uri page;

    setUp(() => page = Uri.file(p.join(tmp.path, 'site', 'page.html')));

    PictureSource? parse(String src, [Uri? base]) =>
        PictureSource.parse(src, base ?? page);

    test('a file beside the page, when it is relative', () {
      final source = parse('Page_files/a.png')!;
      expect(source.kind, PictureKind.local);
      expect(source.address, p.join(tmp.path, 'site', 'Page_files', 'a.png'));
      expect(
        parse('../shared/b.png')!.address,
        p.join(tmp.path, 'shared', 'b.png'),
      );
      expect(parse('./a.png')!.address, p.join(tmp.path, 'site', 'a.png'));
    });

    test('read as a browser reads it: decoded, query and fragment cut', () {
      final spaced = p.join(tmp.path, 'site', 'My files', 'a b.png');
      expect(parse('My%20files/a%20b.png')!.address, spaced);
      expect(parse('My files/a b.png')!.address, spaced);
      expect(parse('My%20files/a%20b.png?v=3#top')!.address, spaced);
      expect(parse(r'My files\a b.png')!.address, spaced);
    });

    test('a file: address, as it is', () {
      final target = Uri.file(p.join(tmp.path, 'elsewhere', 'c.png'));
      final source = parse(target.toString())!;
      expect(source.kind, PictureKind.local);
      expect(source.address, p.join(tmp.path, 'elsewhere', 'c.png'));
    });

    test("a web address, absolute or over the page's own scheme", () {
      final web = parse('https://example.org/i/a.png?x=1')!;
      expect(web.kind, PictureKind.web);
      expect(web.address, 'https://example.org/i/a.png?x=1');
      expect(
        parse('//cdn.example/a.png')!.address,
        'https://cdn.example/a.png',
      );
      expect(
        parse('http://example.org/a.png#frag')!.address,
        endsWith('a.png'),
      );
    });

    test('a relative one is a web address when the page names a <base>', () {
      final base = Uri.parse('https://example.org/blog/post/');
      final source = parse('img/a.png', base)!;
      expect(source.kind, PictureKind.web);
      expect(source.address, 'https://example.org/blog/post/img/a.png');
      expect(parse('/top.png', base)!.address, 'https://example.org/top.png');
    });

    test('a data: address is the picture itself', () {
      final source = parse('data:image/png;base64,AAAA')!;
      expect(source.kind, PictureKind.data);
      expect(source.address, 'data:image/png;base64,AAAA');
    });

    test('nothing when it names no place', () {
      expect(parse(''), isNull);
      expect(parse('   '), isNull);
      expect(parse('ftp://example.org/a.png'), isNull);
    });
  });

  group('the store', () {
    late String staging;
    late List<String> fetched;
    late Uint8List? web;

    setUp(() {
      staging = p.join(tmp.path, 'staging');
      Directory(staging).createSync();
      fetched = [];
      web = Uint8List.fromList(_png);
    });

    HtmlPictureStore store() => HtmlPictureStore(
      staging: staging,
      attachments: 'assets',
      fetch: (url) async {
        fetched.add(url);
        final bytes = web;
        return bytes == null ? null : (bytes: bytes, extension: '.png');
      },
    );

    String named(List<int> bytes, String extension) =>
        'assets/${sha256.convert(bytes)}$extension';

    File local(String name, List<int> bytes) => File(p.join(tmp.path, name))
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes);

    List<String> inStaging() =>
        Directory(p.join(staging, 'assets'))
            .listSync()
            .map((entry) => p.basename(entry.path))
            .toList();

    test("keeps a local picture under its content's name", () async {
      final file = local('Page_files/a.PNG', _png);
      final kept = await store().keep(
        PictureSource(PictureKind.local, file.path),
      );
      expect(kept, named(_png, '.png'));
      expect(
        File(p.join(staging, kept)).readAsBytesSync(),
        orderedEquals(_png),
      );
    });

    test('keeps the same content once, whatever file brought it', () async {
      final one = local('a.png', _png);
      final two = local('copy of a.png', _png);
      final pictures = store();
      final a = await pictures.keep(PictureSource(PictureKind.local, one.path));
      final b = await pictures.keep(PictureSource(PictureKind.local, two.path));
      final c = await pictures.keep(PictureSource(PictureKind.local, one.path));
      expect(a, b);
      expect(a, c);
      expect(pictures.length, 1);
      expect(inStaging(), hasLength(1));
    });

    test('leaves out a local file that is missing, or is no picture', () async {
      final text = local('notes.txt', utf8.encode('not a picture'));
      final pictures = store();
      expect(
        await pictures.keep(
          PictureSource(PictureKind.local, p.join(tmp.path, 'gone.png')),
        ),
        isNull,
      );
      expect(
        await pictures.keep(PictureSource(PictureKind.local, text.path)),
        isNull,
      );
      expect(
        await pictures.keep(PictureSource(PictureKind.local, tmp.path)),
        isNull,
      );
      expect(pictures.length, 0);
    });

    test('decodes a data: picture', () async {
      final kept = await store().keep(
        PictureSource(
          PictureKind.data,
          'data:image/png;base64,${base64.encode(_png)}',
        ),
      );
      expect(kept, named(_png, '.png'));
    });

    test('leaves out a data: picture that is not valid', () async {
      final pictures = store();
      expect(
        await pictures.keep(
          const PictureSource(PictureKind.data, 'data:image/png;base64,@@@@'),
        ),
        isNull,
      );
      expect(
        await pictures.keep(
          const PictureSource(PictureKind.data, 'data:text/plain;base64,AAAA'),
        ),
        isNull,
      );
    });

    test('downloads a web picture through the fetcher', () async {
      final kept = await store().keep(
        const PictureSource(PictureKind.web, 'https://example.org/a.png'),
      );
      expect(kept, named(_png, '.png'));
      expect(fetched, ['https://example.org/a.png']);
    });

    test('leaves out a web picture that does not come', () async {
      final pictures = store();
      web = null;
      expect(
        await pictures.keep(
          const PictureSource(PictureKind.web, 'https://example.org/a.png'),
        ),
        isNull,
      );
      final failing = HtmlPictureStore(
        staging: staging,
        attachments: 'assets',
        fetch: (url) async => throw const SocketException('offline'),
      );
      expect(
        await failing.keep(
          const PictureSource(PictureKind.web, 'https://example.org/b.png'),
        ),
        isNull,
      );
    });

    test('downloads no more than a capture does', () async {
      final pictures = store();
      for (var i = 0; i < maxCapturedPictures + 5; i++) {
        await pictures.keep(
          PictureSource(PictureKind.web, 'https://example.org/$i.png'),
        );
      }
      expect(fetched, hasLength(maxCapturedPictures));
    });
  });
}
