// The diagram style's cache key (#530): whatever changes the drawing
// changes the key, or a cache and a painter serve the old one.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_style.dart';

void main() {
  test('the typeface is part of the key', () {
    const sans = DiagramStyle(fontFamily: 'Inter');
    const serif = DiagramStyle(fontFamily: 'Merriweather');
    expect(sans.cacheKey, isNot(serif.cacheKey));
    expect(sans.cacheKey, isNot(const DiagramStyle().cacheKey));
    expect(sans.cacheKey, const DiagramStyle(fontFamily: 'Inter').cacheKey);
  });
}
