// Importing a folder (#75, #1295): what a walk takes from it and what it
// refuses, where each file lands and which file a link points at, and the
// import end to end into a temporary library — pages converted, Markdown
// copied, the links between them rewritten, the pictures kept once, nothing
// else brought in, and a cancel that leaves nothing behind.
//
// HTML is written in pieces, and a space between two would be a word of
// the page: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/capture_pictures.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/import/folder/folder_import.dart';
import 'package:niman/src/import/folder/folder_job.dart';
import 'package:niman/src/import/folder/folder_plan.dart';
import 'package:niman/src/import/folder/folder_scan.dart';
import 'package:path/path.dart' as p;

const List<int> _png = [137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3];
const List<int> _jpg = [255, 216, 255, 224, 0, 16, 74, 70, 73, 70, 9, 9];
const List<int> _gif = [71, 73, 70, 56, 57, 97, 1, 0, 1, 0, 8, 8];

String _name(List<int> bytes, String extension) =>
    '${sha256.convert(bytes)}$extension';

void main() {
  late Directory tmp;
  late String site;
  late String library;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niman_folder_import_');
    site = p.join(tmp.path, 'Site');
    library = p.join(tmp.path, 'library');
    Directory(site).createSync();
    Directory(library).createSync();
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  void put(String relative, Object content) {
    final file = File(p.joinAll([site, ...relative.split('/')]))
      ..parent.createSync(recursive: true);
    if (content is String) {
      file.writeAsStringSync(content);
    } else {
      file.writeAsBytesSync(content as List<int>);
    }
  }

  String read(String relative) =>
      File(p.joinAll([library, ...relative.split('/')])).readAsStringSync();

  /// Everything under the library, as `/`-separated relative paths.
  List<String> tree() => [
    for (final entry in Directory(library).listSync(recursive: true))
      p.relative(entry.path, from: library).replaceAll(r'\', '/'),
  ]..sort();

  /// A folder of two pages that link each other, a Markdown file that links
  /// a page, a browser's `_files` folders, a subfolder, a hidden folder and
  /// the things that are not imported.
  void fixture() {
    put(
      'index.html',
      '<html><head><title>Home</title></head><body><h1>Home</h1>'
          '<p>Go to <a href="a/b.html">the deep page</a>, to '
          '<a href="about.html#team">the team</a>, to '
          '<a href="notes.md">the notes</a>, read the '
          '<a href="guide.pdf">guide</a> or <a href="https://example.org/x">'
          'the web</a>. <a href="missing.html">Gone</a>.</p></body></html>',
    );
    put(
      'about.html',
      '<html><head><title>About</title></head><body><h1>About</h1>'
          '<p><img src="about_files/logo.png" alt="logo"></p>'
          '<h2 id="intro">Intro</h2><p>Back <a href="index.html">home</a> or '
          '<a href="./a/b.html#deep">deep</a>; <a href="#team">below</a>.</p>'
          '<h2 id="team">The team</h2><p>Us.</p></body></html>',
    );
    put(
      'a/b.html',
      '<html><head><title>Deep</title></head><body><h1>Deep</h1>'
          '<p><a href="../index.html">home</a> and '
          '<a href="..%2Fabout.html#team">the team</a></p>'
          '<p><img src="b_files/x.png" alt="x"> '
          '<img src="data:image/gif;base64,${base64.encode(_gif)}" alt="dot">'
          '</p><h2 id="deep">Deeper</h2><p>Here.</p></body></html>',
    );
    put('a/b_files/x.png', _png);
    put('a/b_files/style.css', 'body{}');
    put('a/b_files/frame.html', '<html><body><p>an ad</p></body></html>');
    put('about_files/logo.png', _png);
    put(
      'notes.md',
      '# Notes\n\nSee [the team](about.html#team) and [deep](a/b.html), '
          '[other](other.md) and [web](https://example.org).\n',
    );
    put('other.md', '# Other\n');
    put('guide.pdf', 'pdf');
    put('style.css', 'body{}');
    put('script.js', 'x');
    put('.git/HEAD', 'ref');
    put('.hidden/page.html', '<html><body><p>hidden</p></body></html>');
  }

  FolderImportRequest request({
    String? name,
    LinkType linkType = LinkType.wikilink,
    FolderLimits limits = folderImportLimits,
  }) {
    final scan = scanImportFolder(site, limits: limits);
    return (
      source: site,
      name: name ?? 'Site',
      libraryRoot: library,
      staging: p.join(library, '.folder.niman-tmp-1'),
      attachments: 'assets',
      linkType: linkType,
      markdown: scan.markdown,
      pages: scan.pages,
      importedOn: DateTime(2026, 11, 20),
    );
  }

  Future<FetchedPicture?> noFetch(String url) async => null;

  group('the walk', () {
    test('takes the Markdown and the pages, and nothing else', () {
      fixture();
      final scan = scanImportFolder(site);
      expect(scan.markdown, ['notes.md', 'other.md']);
      // Not the hidden folder's, nor the `_files` folder's frame.
      expect(scan.pages, ['a/b.html', 'about.html', 'index.html']);
    });

    test('knows a page by any of its extensions, in any case', () {
      put('one.HTM', '<p>1</p>');
      put('two.xhtml', '<p>2</p>');
      put('three.Html', '<p>3</p>');
      put('four.markdown', '# 4');
      put('five.txt', '5');
      final scan = scanImportFolder(site);
      expect(scan.pages, ['one.HTM', 'three.Html', 'two.xhtml']);
      expect(scan.markdown, ['four.markdown']);
    });

    test("enters a `_files` folder that is no page's", () {
      put('Page.html', '<p>x</p>');
      put('Page_files/frame.html', '<p>frame</p>');
      put('project_files/plan.md', '# Plan');
      put('project_files/plan.html', '<p>plan</p>');
      put('Other.HTM', '<p>x</p>');
      put('Other_FILES/frame.htm', '<p>frame</p>');
      final scan = scanImportFolder(site);
      expect(scan.markdown, ['project_files/plan.md']);
      expect(scan.pages, ['Other.HTM', 'Page.html', 'project_files/plan.html']);
    });

    test('says what it holds in bytes', () {
      put('a.md', '12345');
      put('b.html', '1234567');
      put('c.png', 'not counted');
      expect(scanImportFolder(site).bytes, 12);
    });

    test('refuses a folder with more files than it allows', () {
      for (var i = 0; i < 5; i++) {
        put('n$i.md', '#');
      }
      expect(
        () => scanImportFolder(
          site,
          limits: (files: 4, bytes: 1 << 20, visited: 100),
        ),
        throwsA(
          isA<FolderImportRefused>().having(
            (e) => e.reason,
            'reason',
            FolderRefusal.tooManyFiles,
          ),
        ),
      );
    });

    test('refuses a folder with more bytes than it allows', () {
      put('a.md', 'x' * 60);
      put('b.html', 'y' * 60);
      expect(
        () => scanImportFolder(
          site,
          limits: (files: 100, bytes: 100, visited: 100),
        ),
        throwsA(
          isA<FolderImportRefused>().having(
            (e) => e.reason,
            'reason',
            FolderRefusal.tooManyBytes,
          ),
        ),
      );
    });

    test('gives up on a folder with too many entries of any kind', () {
      for (var i = 0; i < 12; i++) {
        put('pics/$i.png', _png);
      }
      expect(
        () => scanImportFolder(
          site,
          limits: (files: 100, bytes: 1 << 20, visited: 10),
        ),
        throwsA(isA<FolderImportRefused>()),
      );
    });
  });

  group('the plan', () {
    FolderPlan plan(List<String> markdown, List<String> pages) =>
        FolderPlan((markdown: markdown, pages: pages, bytes: 0));

    test('keeps the layout and names a page after its file', () {
      final p0 = plan(
        ['notes.md', 'sub/two.markdown'],
        ['index.html', 'sub/Deep Page.htm'],
      );
      expect(
        {for (final e in p0.entries) e.source: e.target},
        {
          'index.html': 'index.md',
          'sub/Deep Page.htm': 'sub/Deep Page.md',
          'notes.md': 'notes.md',
          'sub/two.markdown': 'sub/two.markdown',
        },
      );
      expect(p0.pages.map((e) => e.index), [0, 1]);
      expect(p0.markdown.map((e) => e.index), [2, 3]);
    });

    test('numbers a page whose note would take a name already taken', () {
      final p0 = plan(
        ['a/page.md'],
        ['a/page.html', 'a/page.htm', 'a/Page.xhtml', 'b/page.html'],
      );
      expect(
        [for (final e in p0.entries) e.target],
        ['a/page_2.md', 'a/page_3.md', 'a/Page_4.md', 'b/page.md', 'a/page.md'],
      );
    });

    test('resolves a link as a browser reads it', () {
      final p0 = plan(
        ['notes.md'],
        ['index.html', 'a/b.html', 'a/c d.html', 'docs/index.html'],
      );
      final here = p0.entries.firstWhere((e) => e.source == 'a/b.html');
      String? to(String href) => p0.resolve(here, href)?.entry.source;
      expect(to('c%20d.html'), 'a/c d.html');
      expect(to('./c%20d.html#x'), 'a/c d.html');
      expect(to('../index.html'), 'index.html');
      expect(to(r'..\index.html'), 'index.html');
      expect(to('/index.html'), 'index.html');
      expect(to('../notes.md'), 'notes.md');
      expect(to('../index.html?v=2'), 'index.html');
      expect(to('..%2Findex.html'), 'index.html');
      expect(to('../INDEX.html'), 'index.html');
      // A folder is its index page.
      expect(to('../docs/'), 'docs/index.html');
      expect(to('../docs'), 'docs/index.html');
      // Not to a file of the folder.
      expect(to('#top'), isNull);
      expect(to(''), isNull);
      expect(to('https://example.org/index.html'), isNull);
      expect(to('//example.org/index.html'), isNull);
      expect(to('mailto:a@b.c'), isNull);
      expect(to('../../outside.html'), isNull);
      expect(to('../missing.html'), isNull);
      expect(to('../guide.pdf'), isNull);
      expect(p0.resolve(here, '../index.html#top')?.fragment, 'top');
      expect(p0.resolve(here, '../index.html')?.fragment, '');
    });
  });

  group('the import', () {
    test('keeps the layout, converts the pages, copies the Markdown, '
        'brings nothing else', () async {
      fixture();
      final progress = <(int, int)>[];
      final imported = await importFolder(
        request(),
        fetch: noFetch,
        progress: (step) => progress.add((step.done, step.total)),
      );
      expect(imported, isNotNull);
      expect(imported!.folder, 'Site');
      expect(imported.notes, 5);
      expect(imported.pages, 3);
      expect(imported.skipped, 0);
      // The logo twice (once on each page that has it) and the gif: the
      // same picture is one file.
      expect(imported.pictures, 2);
      expect(
        tree(),
        [
          'Site',
          'Site/a',
          'Site/a/b.md',
          'Site/about.md',
          'Site/index.md',
          'Site/notes.md',
          'Site/other.md',
          'assets',
          'assets/${_name(_png, '.png')}',
          'assets/${_name(_gif, '.gif')}',
        ]..sort(),
      );
      // Where it was is left as it was.
      expect(File(p.join(site, 'index.html')).existsSync(), isTrue);
      expect(File(p.join(site, 'a', 'b_files', 'x.png')).existsSync(), isTrue);
      // Progress counts files: three pages, then two Markdown files.
      expect(progress.last.$2, 5);
      expect({for (final s in progress) s.$1}, {0, 1, 2, 3, 4});
    });

    test('points a link between two pages at the note it became', () async {
      fixture();
      await importFolder(request(), fetch: noFetch);
      final index = read('Site/index.md');
      // A page in a subfolder, a heading for an `id`, a Markdown file.
      expect(index, contains('[the deep page](a/b.md)'));
      expect(index, contains('[the team](about.md#The%20team)'));
      expect(index, contains('[the notes](notes.md)'));
      // What is not imported keeps its link as written; the web stays.
      expect(index, contains('[guide](<guide.pdf>)'));
      expect(index, contains('[the web](<https://example.org/x>)'));
      expect(index, contains('[Gone](<missing.html>)'));

      final about = read('Site/about.md');
      expect(about, contains('[home](index.md)'));
      expect(about, contains('[deep](a/b.md#Deeper)'));
      // A link into its own page is the page's own.
      expect(about, contains('[below](#The%20team)'));

      final deep = read('Site/a/b.md');
      expect(deep, contains('[home](../index.md)'));
      expect(deep, contains('[the team](../about.md#The%20team)'));
    });

    test(
      "rewrites a Markdown file's links to a page, and only those",
      () async {
        fixture();
        await importFolder(request(), fetch: noFetch);
        expect(
          read('Site/notes.md'),
          '# Notes\n\nSee [the team](about.md#The%20team) and '
          '[deep](a/b.md), [other](other.md) and [web](https://example.org).\n',
        );
        // A Markdown file with no page in it is copied as it is.
        expect(read('Site/other.md'), '# Other\n');
      },
    );

    test('drops a fragment the page does not have', () async {
      put(
        'one.html',
        '<title>One</title><p><a href="two.html#nope">two</a></p>',
      );
      put('two.html', '<title>Two</title><p>Two.</p>');
      put('m.md', '[two](two.html#nope) and [two](two.html)\n');
      await importFolder(request(), fetch: noFetch);
      expect(read('Site/one.md'), contains('[two](two.md)'));
      expect(read('Site/m.md'), '[two](two.md) and [two](two.md)\n');
    });

    test('keeps a title and angle brackets of a Markdown link', () async {
      put('two.html', '<title>Two</title><p>Two.</p>');
      put('sub/m.md', '[a](<../two.html> "Two") and [b](../two.html (t))\n');
      await importFolder(request(), fetch: noFetch);
      expect(
        read('Site/sub/m.md'),
        '[a](<../two.md> "Two") and [b](../two.md (t))\n',
      );
    });

    test('names a page after its file, whatever its title', () async {
      put('x.html', '<title>Another title entirely</title><p>Text.</p>');
      put('x.md', '# Existing\n');
      await importFolder(request(), fetch: noFetch);
      expect(read('Site/x.md'), '# Existing\n');
      expect(read('Site/x_2.md'), contains('# Another title entirely'));
    });

    test('is numbered when the folder name is taken', () async {
      put('one.md', '# One');
      Directory(p.join(library, 'Site')).createSync();
      final imported = await importFolder(request(), fetch: noFetch);
      expect(imported?.folder, 'Site 2');
      expect(File(p.join(library, 'Site 2', 'one.md')).existsSync(), isTrue);
    });

    test('writes a picture as the library embeds it', () async {
      fixture();
      await importFolder(request(), fetch: noFetch);
      expect(
        read('Site/about.md'),
        contains('![[assets/${_name(_png, '.png')}]]'),
      );
      expect(
        read('Site/a/b.md'),
        contains('![[assets/${_name(_gif, '.gif')}]]'),
      );
    });

    test(
      "writes a picture from the note's folder in a Markdown library",
      () async {
        fixture();
        await importFolder(
          request(linkType: LinkType.markdown),
          fetch: noFetch,
        );
        expect(
          read('Site/a/b.md'),
          contains('![x](../../assets/${_name(_png, '.png')})'),
        );
        expect(
          read('Site/about.md'),
          contains('![logo](../assets/${_name(_png, '.png')})'),
        );
      },
    );

    test('downloads a web picture once for the whole folder', () async {
      for (var i = 0; i < 3; i++) {
        put(
          'p$i.html',
          '<title>P$i</title><p><img src="https://example.org/logo.png">'
              '<img src="https://example.org/p$i.png"></p>',
        );
      }
      final asked = <String>[];
      final imported = await importFolder(
        request(),
        fetch: (url) async {
          asked.add(url);
          return (
            bytes: Uint8List.fromList([..._jpg, ...utf8.encode(url)]),
            extension: '.png',
          );
        },
      );
      expect(asked.where((url) => url.endsWith('logo.png')), hasLength(1));
      expect(asked, hasLength(4));
      expect(imported?.pictures, 4);
    });

    test("takes at most what a page does of the web's pictures", () async {
      put(
        'long.html',
        '<title>Long</title><p>${[for (var i = 0; i < maxCapturedPictures + 10; i++) '<img src="https://example.org/$i.png">'].join()}</p>',
      );
      var asked = 0;
      await importFolder(
        request(),
        fetch: (url) async {
          asked++;
          return (
            bytes: Uint8List.fromList([..._jpg, asked]),
            extension: '.png',
          );
        },
      );
      expect(asked, maxCapturedPictures);
      // The ones past it keep their address.
      expect(
        read('Site/long.md'),
        contains('![](https://example.org/${maxCapturedPictures + 5}.png)'),
      );
    });

    test('leaves out a page it cannot read, and its links stay', () async {
      put('ok.html', '<title>Ok</title><p><a href="bad.html">bad</a></p>');
      put('bad.html', '<meta charset="shift_jis"><title>x</title><p>y</p>');
      put('m.md', '[bad](bad.html)\n');
      final imported = await importFolder(request(), fetch: noFetch);
      expect(imported?.skipped, 1);
      expect(imported?.pages, 1);
      expect(imported?.notes, 2);
      expect(File(p.join(library, 'Site', 'bad.md')).existsSync(), isFalse);
      expect(read('Site/ok.md'), contains('[bad](<bad.html>)'));
      expect(read('Site/m.md'), '[bad](bad.html)\n');
    });

    test('copies a Markdown file that is not UTF-8 as it is', () async {
      final bytes = [...latin1.encode('café see x.html\n')];
      put('latin.md', bytes);
      put('x.html', '<title>X</title><p>x</p>');
      await importFolder(request(), fetch: noFetch);
      expect(
        File(p.join(library, 'Site', 'latin.md')).readAsBytesSync(),
        bytes,
      );
    });

    test('is nothing for a folder with nothing to import', () async {
      put('pic.png', _png);
      put('style.css', 'x');
      expect(await importFolder(request(), fetch: noFetch), isNull);
      expect(tree(), isEmpty);
    });

    test('is nothing when every page is left out and there is no '
        'Markdown', () async {
      put('bad.html', '<meta charset="shift_jis"><title>x</title><p>y</p>');
      expect(await importFolder(request(), fetch: noFetch), isNull);
      expect(tree(), isEmpty);
    });

    test('stopped, leaves the library as it was', () async {
      fixture();
      var steps = 0;
      await expectLater(
        importFolder(request(), fetch: noFetch, stopped: () => ++steps > 6),
        throwsA(isA<Exception>()),
      );
      expect(tree(), isEmpty);
    });

    test('told not to finish, moves nothing in', () async {
      fixture();
      await expectLater(
        importFolder(request(), fetch: noFetch, mayFinish: () async => false),
        throwsA(isA<Exception>()),
      );
      expect(tree(), isEmpty);
    });
  });

  group('the import on its isolate', () {
    Future<FolderImport> start() async => await FolderImport.start(
      source: site,
      scan: await scanFolder(site),
      libraryRoot: library,
      attachments: 'assets',
      linkType: LinkType.wikilink,
      importedOn: DateTime(2026, 11, 20),
    );

    test('is counted as a job and runs off this isolate', () async {
      fixture();
      final import = await start();
      expect(IsolateGauge.inFlight, greaterThan(0));
      final imported = await import.done;
      expect(IsolateGauge.inFlight, 0);
      expect(imported?.folder, 'Site');
      expect(imported?.notes, 5);
      expect(imported?.pages, 3);
      expect(import.progress.value?.total, 5);
      expect(read('Site/index.md'), contains('[the deep page](a/b.md)'));
      // Nothing of its staging is left.
      expect(tree().where((path) => path.contains('niman-tmp')), isEmpty);
    });

    test(
      'a folder of 2 000 notes is walked and copied off the UI isolate',
      () async {
        for (var i = 0; i < 2000; i++) {
          put('notes/$i.md', '# $i');
        }
        final imported = await (await start()).done;
        expect(imported?.notes, 2000);
        expect(IsolateGauge.inFlight, 0);
      },
    );

    test('cancelled, leaves the library as it was', () async {
      for (var i = 0; i < 300; i++) {
        put('n/$i.html', '<title>N$i</title><p>Page $i.</p>');
      }
      final import = await start();
      // Asked before it is ready, which is before it has written anything
      // or been asked whether it may move in.
      expect(import.cancellable, isTrue);
      expect(await import.cancel(), isTrue);
      await expectLater(import.done, throwsA(isA<HtmlConvertCancelled>()));
      expect(tree(), isEmpty);
      expect(IsolateGauge.inFlight, 0);
      expect(await import.cancel(), isFalse);
    });

    test('a folder with nothing to import answers null', () async {
      put('pic.png', _png);
      expect(await (await start()).done, isNull);
      expect(tree(), isEmpty);
    });
  });
}
