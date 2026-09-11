import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';

void main() {
  testWidgets('app boots with the open-library screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NimanApp()));
    await tester.pumpAndSettle();

    expect(find.text('Niman'), findsWidgets);
    expect(find.byKey(const Key('branding')), findsOne);
    expect(find.text('Open existing'), findsOne);
    expect(find.text('Create new'), findsOne);
  });
}
