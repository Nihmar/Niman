// How a diagram writes a value beside what it measures (#530).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_values.dart';

void main() {
  test('a whole value has no decimals, any other two at most', () {
    expect(diagramValue(25), '25');
    expect(diagramValue(2.5), '2.5');
    expect(diagramValue(1 / 3), '0.33');
    expect(diagramValue(1.996), '2');
  });
}
