// A line's base direction is its first strong character's (#1352).
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/line_direction.dart';

void main() {
  test('a Latin line is left to right, whatever follows', () {
    expect(lineDirection('abc'), TextDirection.ltr);
    expect(lineDirection('abc שלום'), TextDirection.ltr);
    expect(lineDirection('Élan'), TextDirection.ltr);
    expect(lineDirection('日本語'), TextDirection.ltr);
  });

  test('a Hebrew or Arabic line is right to left', () {
    expect(lineDirection('שלום עולם'), TextDirection.rtl);
    expect(lineDirection('مرحبا بالعالم'), TextDirection.rtl);
    expect(lineDirection('שלום abc'), TextDirection.rtl);
    expect(lineDirection('ܫܠܡܐ'), TextDirection.rtl, reason: 'Syriac');
    expect(lineDirection('\u{10800}'), TextDirection.rtl, reason: 'Cypriot');
  });

  test('markers, digits and punctuation have no direction of their own', () {
    expect(lineDirection('## שלום'), TextDirection.rtl);
    expect(lineDirection('- 12. مرحبا'), TextDirection.rtl);
    expect(lineDirection('> **abc**'), TextDirection.ltr);
    expect(lineDirection('1234'), isNull);
    expect(lineDirection('- '), isNull);
    expect(lineDirection(''), isNull);
    expect(
      lineDirection('١٢ مرحبا'),
      TextDirection.rtl,
      reason: 'Arabic-Indic digits are weak',
    );
  });

  test('a mark says the direction in so many words', () {
    expect(lineDirection('12 ‏abc'), TextDirection.rtl);
    expect(lineDirection('12 ‎שלום'), TextDirection.ltr);
  });

  test('only the start of a line is read', () {
    expect(lineDirection('${'1' * 2000}abc'), isNull);
    expect(lineDirection('${'1' * 100}abc'), TextDirection.ltr);
  });
}
