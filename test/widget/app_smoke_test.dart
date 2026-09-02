import 'package:copist/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots and shows placeholder branding', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CopistApp()));
    await tester.pump();

    expect(find.text('Copist'), findsWidgets);
    expect(find.text('No library set'), findsOne);
    expect(find.byKey(const Key('branding')), findsOne);
    expect(tester.takeException(), isNull);
  });
}
