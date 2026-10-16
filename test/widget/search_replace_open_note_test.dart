// Replace all and the notes open with unsaved edits (#1042): they are saved
// before the run rewrites the files, so the replacement is not written over
// by an editor that still holds the old words, and they are told afterwards
// to adopt the new text.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/search/replace.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/ui/search_screen.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_replace_source.dart';
import '../fakes/fake_search_source.dart';

/// A replace source that writes down what the open note had done by then.
final class _OrderedReplace extends FakeReplaceSource {
  new(this.onRun);

  final void Function() onRun;

  @override
  Future<ReplaceReport> replaceAll({
    required String term,
    required String replacement,
    required bool caseSensitive,
    Set<String>? only,
    Set<String> skip = const {},
  }) {
    onRun();
    return super.replaceAll(
      term: term,
      replacement: replacement,
      caseSensitive: caseSensitive,
      only: only,
      skip: skip,
    );
  }
}

final class _OpenNote implements UnsavedNote {
  new(this.path);

  @override
  final String path;
  @override
  bool unsaved = true;
  @override
  String text = 'Acme plan';
  Error? failure;

  @override
  Future<void> save() async {
    if (failure case final error?) throw error;
    unsaved = false;
  }
}

void main() {
  late UnsavedTracker tracker;
  late _OpenNote note;
  late List<String> events;

  setUp(() {
    tracker = UnsavedTracker();
    note = _OpenNote('/lib/Plan.md');
    tracker.register(note);
    events = [];
    tracker.diskChanges.listen(
      (paths) => events.add('changed ${paths.length}'),
    );
  });

  Future<void> replaceAll(WidgetTester tester, ReplaceSource replace) async {
    final source = FakeSearchSource()
      ..hits = [
        const SearchHit(noteId: 0, path: 'Plan.md', title: 'Plan', snippet: ''),
      ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            controller: FakeLibrarySession(),
            onOpenNote: (_) {},
            source: source,
            replaceSource: replace,
            unsavedTracker: tracker,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'Acme');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    await tester.tap(find.byKey(const Key('search-replace')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('replace-with')), 'Globex');
    await tester.pump();
    await tester.tap(find.byKey(const Key('replace-confirm')));
    await tester.pumpAndSettle();
    // The deferred results refresh.
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the open notes are saved before the run, and told after it', (
    tester,
  ) async {
    final replace =
        _OrderedReplace(() => events.add('run, saved=${!note.unsaved}'))
          ..preview = const [
            ReplaceMatchNote(path: 'Plan.md', occurrences: 1, samples: []),
          ];
    await replaceAll(tester, replace);

    expect(events, ['run, saved=true', 'changed 0']);
    expect(replace.replaceRequests, hasLength(1));
  });

  testWidgets('a note that cannot be saved stops the run before it starts', (
    tester,
  ) async {
    note.failure = StateError('disk full');
    final replace = _OrderedReplace(() => events.add('run'))
      ..preview = const [
        ReplaceMatchNote(path: 'Plan.md', occurrences: 1, samples: []),
      ];
    await replaceAll(tester, replace);

    expect(events, isEmpty, reason: 'nothing was rewritten, nobody told');
    expect(replace.replaceRequests, isEmpty);
    expect(find.text(AppStrings.noteSaveFailedSnack), findsOneWidget);
  });
}
