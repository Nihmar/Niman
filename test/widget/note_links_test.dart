// #674: a Markdown link with no target goes nowhere when tapped in the
// preview, as on a slide.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/ui/note_links.dart';

import '../fakes/fake_link_source.dart';

void main() {
  testWidgets('a link with no target resolves nothing (#674)', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    final source = FakeLinkSource(notes: ['a.md']);
    final targets = NoteLinkTargets(
      source: source,
      notePath: '/lib/n.md',
      libraryRoot: '/lib',
      missingNoteLocation: MissingNoteLocation.currentFolder,
      outline: const [],
      jumpToHeading: (_) {},
    );

    await openHref(context, '', targets);
    await openHref(context, '  ', targets);
    expect(source.queries, isEmpty);

    await openHref(context, 'a.md', targets);
    expect(source.queries, isNotEmpty, reason: 'a link with one does');
  });
}
