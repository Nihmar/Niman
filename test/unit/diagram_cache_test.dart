// The cache of laid-out diagrams (#530): a drawing once per source and
// style, the least recently used dropped past its capacity.
import 'package:flutter/material.dart' show Brightness;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_cache.dart';
import 'package:niman/src/diagrams/diagram_style.dart';

const String _a = 'flowchart TD\nA --> B';
const String _b = 'flowchart TD\nB --> C';
const String _c = 'flowchart TD\nC --> D';

void main() {
  test('a source is laid out once at a style, again at another', () {
    final cache = DiagramCache();
    const style = DiagramStyle();
    final first = cache.resolve(_a, style);
    expect(cache.resolve(_a, style), same(first));
    final dark = DiagramStyle(palette: DiagramPalette.of(Brightness.dark));
    expect(cache.resolve(_a, dark), isNot(same(first)));
  });

  test('past its capacity the least recently used is dropped', () {
    final cache = DiagramCache(capacity: 2);
    const style = DiagramStyle();
    final a = cache.resolve(_a, style);
    final b = cache.resolve(_b, style);
    // A used again: B is now the oldest, and C pushes it out.
    expect(cache.resolve(_a, style), same(a));
    cache.resolve(_c, style);
    expect(cache.resolve(_a, style), same(a));
    expect(cache.resolve(_b, style), isNot(same(b)));
  });
}
