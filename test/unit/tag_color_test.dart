// T-TDM-02 AC: tag accent colors are deterministic per name.
import 'package:copist/src/ui/tag_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stable per name and case-insensitive', () {
    expect(tagColorFor('bills'), tagColorFor('bills'));
    expect(tagColorFor('Bills'), tagColorFor('bills'));
    expect(tagColorFor('a'), isNot(tagColorFor('b')));
  });

  test('maps the name to a fixed-saturation HSL color', () {
    final hue = ('home'.hashCode & 0x7fffffff) % 360;
    expect(
      tagColorFor('home'),
      HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.62).toColor(),
    );
  });
}
