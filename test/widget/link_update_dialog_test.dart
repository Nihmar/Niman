// The question a move asks under "ask" for links (#848): the number of
// notes that would change, and two answers. A dismissed dialog is a no.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/link_update_dialog.dart';
import 'package:niman/src/ui/strings.dart';

void main() {
  /// Opens the question for [notes] notes; what it answered lands in the
  /// returned list.
  Future<List<bool>> open(WidgetTester tester, int notes) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final answers = <bool>[];
    unawaited(askLinkUpdate(context, notes).then(answers.add));
    await tester.pumpAndSettle();
    return answers;
  }

  testWidgets('it names how many notes would change', (tester) async {
    final answers = await open(tester, 12);
    expect(find.text(AppStrings.linkUpdateAskBody(12)), findsOne);
    expect(find.textContaining('12'), findsOne);
    expect(answers, isEmpty, reason: 'nothing answered yet');
  });

  testWidgets('Update answers yes', (tester) async {
    final answers = await open(tester, 3);
    await tester.tap(find.byKey(const Key('link-update-confirm')));
    await tester.pumpAndSettle();
    expect(answers, [true]);
  });

  testWidgets('Leave as is answers no', (tester) async {
    final answers = await open(tester, 3);
    await tester.tap(find.byKey(const Key('link-update-keep')));
    await tester.pumpAndSettle();
    expect(answers, [false]);
  });

  testWidgets('dismissing the dialog answers no', (tester) async {
    final answers = await open(tester, 3);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(answers, [false]);
  });
}
