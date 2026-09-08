// T-M2-05 M-05-2: the math cache — LRU bound, exact-string reuse (the AC),
// errors never cached, inflight coalescing.
import 'dart:async';

import 'package:copist/src/preview/math_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart'
    show BoxNode, KatexOptions, renderToBox;

BoxNode _realRender(String tex, {required bool displayMode}) =>
    renderToBox(tex, options: KatexOptions(displayMode: displayMode));

void main() {
  test('renders once and reuses unchanged spans (the edit-reuse AC)', () async {
    var renders = 0;
    final cache = MathCache(
      renderer: (tex, {required displayMode}) {
        renders++;
        return _realRender(tex, displayMode: displayMode);
      },
    );
    final first = await cache.ensure(r'\frac{a}{b}', displayMode: false);
    expect(first, isNotNull);
    final second = await cache.ensure(r'\frac{a}{b}', displayMode: false);
    expect(second, same(first));
    expect(renders, 1);
    expect(cache.hits, 1);
    final display = await cache.ensure(r'\frac{a}{b}', displayMode: true);
    expect(display, isNot(same(second)));
    expect(renders, 2, reason: 'display mode is part of the key');
    cache.dispose();
  });

  test('errors are remembered but never cached', () async {
    final cache = MathCache(
      renderer: (tex, {required displayMode}) =>
          throw const FormatException('bad'),
    );
    expect(await cache.ensure(r'\frac{a}', displayMode: false), isNull);
    expect(cache.isError(r'\frac{a}', displayMode: false), isTrue);
    expect(cache.boxFor(r'\frac{a}', displayMode: false), isNull);
    // A retry re-attempts (and fails again) — no cached error result.
    expect(await cache.ensure(r'\frac{a}', displayMode: false), isNull);
    cache.dispose();
  });

  test('is bounded: oldest entry evicted first (LRU)', () async {
    final cache = MathCache(capacity: 2, renderer: _realRender);
    await cache.ensure('a', displayMode: false);
    await cache.ensure('b', displayMode: false);
    // Touch 'a' so 'b' is the least recent.
    await cache.ensure('a', displayMode: false);
    await cache.ensure('c', displayMode: false);
    expect(cache.boxFor('a', displayMode: false), isNotNull);
    expect(cache.boxFor('b', displayMode: false), isNull);
    expect(cache.boxFor('c', displayMode: false), isNotNull);
    cache.dispose();
  });

  test('pending renders are coalesced', () {
    final completer = Completer<BoxNode?>();
    var renders = 0;
    final cache = MathCache(
      renderer: (tex, {required displayMode}) {
        renders++;
        return completer.future as BoxNode;
      },
    );
    final serial = cache.ensure('a', displayMode: false);
    final second = cache.ensure('a', displayMode: false);
    expect(cache.isPending('a', displayMode: false), isTrue);
    expect(identical(second, serial), isTrue, reason: 'one in-flight render');
    expect(renders, 1);
    completer.complete(_realRender('x', displayMode: false));
    cache.dispose();
  });

  test('default path renders through katex_dart (real box)', () async {
    final cache = MathCache();
    final box = await cache.ensure(r'\sum_{i=0}^n i', displayMode: false);
    expect(box, isNotNull);
    expect(box!.width, greaterThan(0));
    cache.dispose();
  });
}
