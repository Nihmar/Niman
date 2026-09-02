import 'package:copist/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots with the open-library screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CopistApp()));
    await tester.pumpAndSettle();

    expect(find.text('Copist'), findsWidgets);
    expect(find.byKey(const Key('branding')), findsOne);
    expect(find.text('Open existing'), findsOne);
    expect(find.text('Create new'), findsOne);
  });
}
