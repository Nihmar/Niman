// The Mermaid pie-chart parser (#530): the header, its title and
// `showData`, the slices, and the errors that name a line.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/pie_parser.dart';

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

void main() {
  test('slices keep their order, labels and values', () {
    final pie = parsePie('pie\n"Dogs" : 386\n"Cats" : 85.5\n  "50%% off" : 15');
    expect(pie.slices.map((s) => s.label), ['Dogs', 'Cats', '50%% off']);
    expect(pie.slices.map((s) => s.value), [386, 85.5, 15]);
    expect(pie.title, isNull);
    expect(pie.showData, isFalse);
  });

  test('the header carries showData and a title', () {
    final pie = parsePie('pie showData title Pets adopted\n"Dogs" : 1');
    expect(pie.showData, isTrue);
    expect(pie.title, 'Pets adopted');
  });

  test('a title may have a line of its own', () {
    final pie = parsePie('pie\n  title Key elements\n  "Iron" : 5');
    expect(pie.title, 'Key elements');
  });

  test('accessibility lines and comments are stepped over', () {
    final pie = parsePie(
      '---\nconfig: {}\n---\n%% a note\npie\naccTitle: Pets\n'
      'accDescr {\n  Which pets\n  were adopted\n}\n"Dogs" : 3 %% most',
    );
    expect(pie.slices.single.label, 'Dogs');
  });

  test('a zero slice is kept, a pie of zeros is an error', () {
    expect(parsePie('pie\n"A" : 0\n"B" : 2').slices, hasLength(2));
    expect(() => parsePie('pie\n"A" : 0'), _error(1, 'greater than zero'));
    expect(() => parsePie('pie title Empty'), _error(1, 'greater than zero'));
  });

  test('a slice that does not read names its line', () {
    expect(() => parsePie('pie\n"A" : 1\n"B"'), _error(3, 'expected ":"'));
    expect(() => parsePie('pie\n"A" : many'), _error(2, 'expected a number'));
    expect(() => parsePie('pie\n"A" : -4'), _error(2, 'cannot be negative'));
    expect(() => parsePie('pie\nA : 4'), _error(2, 'found "A : 4"'));
  });

  test('a header that is not a pie names its line', () {
    expect(() => parsePie('pie chart\n"A" : 1'), _error(1, 'expected "pie"'));
  });
}
