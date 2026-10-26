// A formula view whose cache let go of its box (`MathCache.reclaim`, #1195)
// asks for the render again when it is rebuilt, rather than staying its
// placeholder.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/core/memory_reclaim.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_widget.dart';

void main() {
  for (final display in [false, true]) {
    testWidgets(
      '${display ? 'a block' : 'an inline'} formula is typeset again after a '
      'reclaim',
      (tester) async {
        const tex = r'\frac{a}{b}';
        var renders = 0;
        final cache = MathCache(
          renderer: (tex, {required displayMode}) {
            renders++;
            return renderToBox(
              tex,
              options: KatexOptions(displayMode: displayMode),
            );
          },
        );
        addTearDown(cache.dispose);
        final rebuild = ValueNotifier<int>(0);
        addTearDown(rebuild.dispose);
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ValueListenableBuilder<int>(
              valueListenable: rebuild,
              builder: (context, _, _) => display
                  ? BlockMathView(
                      cache: cache,
                      tex: tex,
                      style: const MathStyle(),
                    )
                  : InlineMathView(
                      cache: cache,
                      tex: tex,
                      style: const MathStyle(),
                    ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(cache.boxFor(tex, displayMode: display), isNotNull);
        expect(renders, 1);

        MemoryReclaim.reclaimAll();
        expect(cache.boxFor(tex, displayMode: display), isNull);

        rebuild.value++;
        await tester.pumpAndSettle();

        expect(renders, 2, reason: 'the view asked for its render again');
        expect(cache.boxFor(tex, displayMode: display), isNotNull);
        expect(find.text('…'), findsNothing, reason: 'no placeholder is left');
      },
    );
  }
}
