// Which files are web pages the app converts into notes (#1293): by their
// extension, and — for a share that came with none — by how they begin.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/import/html/html_file.dart';
import 'package:path/path.dart' as p;

void main() {
  test('a page is told by its extension, in any case', () {
    for (final name in ['a.html', 'B.HTM', 'c.xhtml', '/x/y/Page.Html']) {
      expect(isHtmlFile(name), isTrue, reason: name);
    }
    for (final name in ['a.md', 'a.htm.bak', 'html', 'a.xml', 'a.txt', '']) {
      expect(isHtmlFile(name), isFalse, reason: name);
    }
  });

  test('the picker filters by the same extensions', () {
    expect(htmlPickerExtensions.map((e) => '.$e').toSet(), htmlExtensions);
  });

  group('looksLikeHtml', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('niman-html-file'));
    tearDown(() => tmp.deleteSync(recursive: true));

    Future<bool> looks(List<int> bytes) {
      final file = File(p.join(tmp.path, 'msf-1234'))..writeAsBytesSync(bytes);
      return looksLikeHtml(file.path);
    }

    test('a document type or an html tag does', () async {
      expect(await looks('<!DOCTYPE html><title>x</title>'.codeUnits), isTrue);
      expect(await looks('  \n<html lang="it"><body>'.codeUnits), isTrue);
      expect(await looks('<HTML>'.codeUnits), isTrue);
    });

    test('past a byte-order mark, in UTF-8 and in UTF-16', () async {
      expect(
        await looks([0xEF, 0xBB, 0xBF, ...'<!doctype html>'.codeUnits]),
        isTrue,
      );
      expect(
        await looks([
          0xFF,
          0xFE,
          for (final c in '<html>'.codeUnits) ...[c, 0],
        ]),
        isTrue,
      );
    });

    test('a text, a note or a book does not', () async {
      expect(await looks('# A note about <html> tags'.codeUnits), isFalse);
      expect(await looks('Just words.'.codeUnits), isFalse);
      expect(await looks('<htmlish>'.codeUnits), isFalse);
      expect(await looks('PK\u0003\u0004'.codeUnits), isFalse);
      expect(await looks(const []), isFalse);
    });

    test('a file that is not there does not', () async {
      expect(await looksLikeHtml(p.join(tmp.path, 'gone')), isFalse);
    });
  });
}
