// A callout's first line, read (#279): `[!type]`, a fold sign, a title.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/callout.dart';

void main() {
  test('a type alone is titled by its type', () {
    expect(
      Callout.of('[!note]'),
      const Callout(type: 'note', fold: CalloutFold.none, title: 'Note'),
    );
  });

  test('a title of its own, and the fold signs', () {
    expect(
      Callout.of('[!WARNING]- Mind the gap'),
      const Callout(
        type: 'warning',
        fold: CalloutFold.closed,
        title: 'Mind the gap',
      ),
    );
    expect(Callout.of('[!tip]+')?.fold, CalloutFold.open);
    expect(Callout.of('  [!info] x')?.type, 'info');
  });

  test('anything else is a quote', () {
    for (final line in ['not [!note]', '[note]', '[!] x', '[!1st] x', '']) {
      expect(Callout.of(line), isNull, reason: line);
    }
  });

  test('the mark is what live hides: up to the title', () {
    expect(Callout.markLength('[!note]- Title'), '[!note]- '.length);
    expect(Callout.markLength('[!note]'), '[!note]'.length);
    expect(Callout.markLength('a quote'), 0);
  });
}
