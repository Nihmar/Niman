// The width bound a picture is decoded at (#1194) follows the pixel ratio and
// the fallback the probe is given, not only the constraints it is laid out in
// (#1237).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/preview/decode_bound.dart';
import 'package:niman/src/preview/decode_width_probe.dart';

void main() {
  testWidgets('a changed ratio reports a new bound without new constraints', (
    tester,
  ) async {
    final bounds = <int>[];
    Widget probe(double ratio) => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 200,
          height: 50,
          child: DecodeWidthProbe(
            ratio: ratio,
            fallback: 640,
            onWidth: bounds.add,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.pumpWidget(probe(1));
    expect(bounds.last, decodeBound(200, 1));

    // Same box, same constraints: only the ratio moved (a denser screen).
    bounds.clear();
    await tester.pumpWidget(probe(3));
    expect(bounds, isNotEmpty, reason: 'the bound was not reported again');
    expect(bounds.last, decodeBound(200, 3));
    expect(bounds.last, isNot(decodeBound(200, 1)));
  });

  testWidgets('a changed fallback reports a new bound when unbounded', (
    tester,
  ) async {
    final bounds = <int>[];
    Widget probe(double fallback) => Directionality(
      textDirection: TextDirection.ltr,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DecodeWidthProbe(
          ratio: 2,
          fallback: fallback,
          onWidth: bounds.add,
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    );

    await tester.pumpWidget(probe(400));
    expect(bounds.last, decodeBound(400, 2));
    bounds.clear();
    await tester.pumpWidget(probe(800));
    expect(bounds.last, decodeBound(800, 2));
  });
}
