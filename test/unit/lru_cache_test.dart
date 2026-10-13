// The one bounded cache the lazy readers share: least recently used goes.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/lru_cache.dart';

void main() {
  test('holds at most its capacity, the oldest entry going', () {
    final cache = LruCache<int, String>(3);
    for (var i = 0; i < 5; i++) {
      cache[i] = 'v$i';
    }

    expect(cache.length, 3);
    expect(cache[0], isNull);
    expect(cache[1], isNull);
    expect([cache[2], cache[3], cache[4]], ['v2', 'v3', 'v4']);
  });

  test('a read is a use: what was asked for last stays', () {
    final cache = LruCache<int, String>(3);
    cache[0] = 'a';
    cache[1] = 'b';
    cache[2] = 'c';

    expect(cache[0], 'a', reason: '0 is now the most recent');
    cache[3] = 'd';

    expect(cache[1], isNull, reason: '1 was the least recently used');
    expect(cache[0], 'a');
    expect(cache[2], 'c');
    expect(cache[3], 'd');
  });

  test('replacing an entry is a use, and does not grow the cache', () {
    final cache = LruCache<String, int>(2);
    cache['a'] = 1;
    cache['b'] = 2;
    cache['a'] = 10;
    cache['c'] = 3;

    expect(cache.length, 2);
    expect(cache['b'], isNull);
    expect(cache['a'], 10);
  });

  test('a stored null is a value, not a miss', () {
    final cache = LruCache<int, int?>(2);
    cache[1] = null;
    cache[2] = null;

    expect(cache.length, 2);
    expect(cache[1], isNull, reason: 'a stored null comes back as null');
    expect(
      cache.length,
      2,
      reason: 'asking for it is a use, and does not drop the entry',
    );

    cache[3] = null;
    expect(cache.length, 2, reason: 'the least recently used one goes');
  });

  test('remove and clear let go', () {
    final cache = LruCache<String, int>(4);
    cache['a'] = 1;
    cache['b'] = 2;

    expect(cache.remove('a'), 1);
    expect(cache.remove('a'), isNull);
    expect(cache.length, 1);
    cache.clear();
    expect(cache.isEmpty, isTrue);
  });
}
