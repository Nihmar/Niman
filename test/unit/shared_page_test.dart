// What a browser's share is (#531): a page — its address alone, or a
// title with it — or a quote, selected text with the page it came from;
// anything else stays plain text for the quick note.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/shared_page.dart';

void main() {
  test('a lone address is a page, titled by the subject', () {
    final share = classifyShare(
      ' https://example.com/garden ',
      subject: 'Tending a winter garden',
    );
    expect(share, isA<SharedPage>());
    expect(share!.url, Uri.parse('https://example.com/garden'));
    expect(share.title, 'Tending a winter garden');
  });

  test('a title and an address after it is a page', () {
    final share = classifyShare('Tending a winter garden\nhttps://ex.com/g');
    expect(share, isA<SharedPage>());
    expect(share!.title, 'Tending a winter garden');
  });

  test('the subject before the address is a page, on one line too', () {
    final share = classifyShare(
      'Tending a winter garden https://ex.com/g',
      subject: 'Tending a winter garden',
    );
    expect(share, isA<SharedPage>());
    expect(share!.title, 'Tending a winter garden');
  });

  test("a browser's highlight is a quote, its page without the fragment", () {
    final share = classifyShare(
      '"Conflicts should read as a choice."\n'
      'https://example.com/post#:~:text=Conflicts%20should',
    );
    expect(share, isA<SharedQuote>());
    final quote = share! as SharedQuote;
    expect(quote.quote, 'Conflicts should read as a choice.');
    expect(quote.pageUrl, Uri.parse('https://example.com/post'));
  });

  test('quoted text before an address is a quote', () {
    final share = classifyShare('“Two versions, both kept.” https://ex.com/p');
    expect(share, isA<SharedQuote>());
    expect((share! as SharedQuote).quote, 'Two versions, both kept.');
  });

  test('plain text, or text with no address at its end, stays text', () {
    expect(classifyShare('buy milk'), isNull);
    expect(classifyShare('see https://example.com and call'), isNull);
    expect(
      classifyShare('Buy this tomorrow https://shop.example/item'),
      isNull,
      reason: "text on the address's line is a message (#640)",
    );
    expect(classifyShare('Buy this\ntomorrow\nhttps://ex.com'), isNull);
    expect(
      classifyShare('one\ntwo\nthree\nfour\nhttps://example.com'),
      isNull,
      reason: 'a whole message that ends in a link is a message',
    );
  });

  test("a fragment that only points somewhere is the page's own", () {
    expect(
      withoutTextFragment(Uri.parse('https://e.com/a#part:~:text=x')),
      Uri.parse('https://e.com/a#part'),
    );
    expect(
      withoutTextFragment(Uri.parse('https://e.com/a#part')),
      Uri.parse('https://e.com/a#part'),
    );
  });
}
