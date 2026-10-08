// The Readability port held to upstream's own test pages (#531): each page
// in test/fixtures/readability/ is read as upstream's test reads it — at
// http://fakehost/test/page.html, its comments removed, "caption" kept — and
// the article compared with upstream's expected one as a tree, its metadata
// field by field. A page listed in known-diffs.txt is one where html5lib and
// jsdom build different trees: it must still differ, so the list only
// shrinks.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:niman/src/capture/readability/readability.dart';
import 'package:path/path.dart' as p;

final String _root = p.join('test', 'fixtures', 'readability');
final Uri _uri = Uri.parse('http://fakehost/test/page.html');

/// [document] without its comments, as upstream's test reads it.
Document _withoutComments(Document document) {
  void strip(Node node) {
    for (final child in node.nodes.toList()) {
      if (child is Comment) {
        node.nodes.remove(child);
        child.parentNode = null;
      } else {
        strip(child);
      }
    }
  }

  strip(document);
  return document;
}

/// The next node after [node] in pre-order, past white space and comments.
Node? _next(Node node) {
  Node? step(Node from) {
    if (from.nodes.isNotEmpty) return from.nodes.first;
    Node? at = from;
    while (at != null) {
      final parent = at.parentNode;
      if (parent == null) return null;
      final index = parent.nodes.indexOf(at);
      if (index + 1 < parent.nodes.length) return parent.nodes[index + 1];
      at = parent;
    }
    return null;
  }

  var at = step(node);
  while (at != null &&
      (at is Comment || (at is Text && at.data.trim().isEmpty))) {
    at = step(at);
  }
  return at;
}

String _collapse(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

String _describe(Node? node) {
  if (node == null) return '(no node)';
  if (node is Text) return '#text(${_collapse(node.data)})';
  if (node is! Element) return 'node of type ${node.nodeType}';
  final id = node.id.isEmpty ? '' : '#${node.id}';
  final className = node.className.isEmpty ? '' : '.(${node.className})';
  return '${node.localName}$id$className';
}

String _path(Node node) {
  final parts = <String>[];
  Node? at = node;
  while (at is Element && at.localName != 'body') {
    final parent = at.parentNode!;
    parts.add('${_describe(at)}:${parent.nodes.indexOf(at) + 1}');
    at = parent;
  }
  return 'body > ${parts.reversed.join(' > ')}';
}

final _xmlName = RegExp(r'^[A-Za-z_:][-A-Za-z0-9_:.]*$');

Map<String, String> _attributes(Element element) => {
  for (final MapEntry(:key, :value) in element.attributes.entries)
    if (_xmlName.hasMatch(key.toString())) key.toString(): value,
};

/// The first difference between [actual] and [expected], or null.
String? _difference(Document actual, Document expected) {
  Node? a = actual.documentElement;
  Node? e = expected.documentElement;
  while (a != null || e != null) {
    final actualDesc = _describe(a);
    final expectedDesc = _describe(e);
    if (a == null || e == null || actualDesc != expectedDesc) {
      return 'at ${a == null ? '(end)' : _path(a)}: '
          '$actualDesc, expected $expectedDesc';
    }
    if (a is Element && e is Element) {
      final actualAttributes = _attributes(a);
      final expectedAttributes = _attributes(e);
      if (actualAttributes.length != expectedAttributes.length ||
          actualAttributes.entries.any(
            (entry) => expectedAttributes[entry.key] != entry.value,
          )) {
        return 'at ${_path(a)}: attributes $actualAttributes, '
            'expected $expectedAttributes';
      }
    }
    a = _next(a);
    e = _next(e);
  }
  return null;
}

void main() {
  final pages =
      Directory(_root)
          .listSync()
          .whereType<Directory>()
          .map((dir) => p.basename(dir.path))
          .toList()
        ..sort();
  final knownDiffs = {
    for (final line in File(p.join(_root, 'known-diffs.txt')).readAsLinesSync())
      if (line.trim().isNotEmpty && !line.startsWith('#'))
        line.split(':').first.trim(),
  };

  test('the fixtures are there', () => expect(pages, isNotEmpty));

  for (final page in pages) {
    group(page, () {
      String read(String name) =>
          File(p.join(_root, page, name)).readAsStringSync().trim();
      final metadata =
          jsonDecode(read('expected-metadata.json')) as Map<String, Object?>;

      late final article = readArticle(
        _withoutComments(html.parse(read('source.html'))),
        documentUri: _uri,
        options: const ReadabilityOptions(classesToPreserve: ['caption']),
      );

      test('content', () {
        expect(article, isNotNull);
        final difference = _difference(
          html.parse(article!.contentHtml),
          html.parse(read('expected.html')),
        );
        if (knownDiffs.contains(page)) {
          expect(
            difference,
            isNotNull,
            reason: 'it matches now: take it out of known-diffs.txt',
          );
        } else {
          expect(difference, isNull, reason: difference);
        }
      });

      test('metadata', () {
        expect(article?.title, metadata['title'], reason: 'title');
        expect(article?.byline, metadata['byline'], reason: 'byline');
        expect(article?.excerpt, metadata['excerpt'], reason: 'excerpt');
        expect(article?.siteName, metadata['siteName'], reason: 'siteName');
        for (final field in ['dir', 'lang', 'publishedTime']) {
          final expected = metadata[field];
          if (expected == null) continue;
          final actual = switch (field) {
            'dir' => article?.dir,
            'lang' => article?.lang,
            _ => article?.publishedTime,
          };
          expect(actual, expected, reason: field);
        }
      });

      test('readerable', () {
        expect(
          isProbablyReaderable(html.parse(read('source.html'))),
          metadata['readerable'],
        );
      });
    });
  }
}
