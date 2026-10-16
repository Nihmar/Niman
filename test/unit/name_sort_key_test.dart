import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/name_sort_key.dart';

void main() {
  List<String> sorted(List<String> names) =>
      [...names]..sort((a, b) => nameSortKey(a).compareTo(nameSortKey(b)));

  test('case does not decide the order', () {
    expect(sorted(['Zebra', 'apple', 'Mango']), ['apple', 'Mango', 'Zebra']);
  });

  test('marks fold into their letters, written whole or decomposed', () {
    expect(foldName('Émile'), 'emile');
    expect(foldName('émile'), 'emile');
    expect(foldName('Straße'), 'strasse');
    expect(sorted(['zed', 'Émile', 'emil']), ['emil', 'Émile', 'zed']);
  });

  test('numbers count by value', () {
    expect(nameSortKey('note 02'), nameSortKey('note 2'));
    expect(sorted(['note 10', 'note 2', 'note 1', 'note 100']), [
      'note 1',
      'note 2',
      'note 10',
      'note 100',
    ]);
  });

  test('a digit run beyond the cut still orders, and zero is a number', () {
    expect(nameSortKey('a0'), nameSortKey('a00'));
    expect(sorted(['a1', 'a0']), ['a0', 'a1']);
    expect(nameSortKey('1' * 120).length, 2 + 99);
  });
}
