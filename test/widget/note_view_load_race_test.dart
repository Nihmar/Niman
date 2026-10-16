// A note's load against the reader moving on (#1059): a load that ends after
// the reader has gone elsewhere — or come back — changes nothing, whichever
// way it ends; and a load that failed can be tried again.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/note_read_failure.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';

Widget _app(NoteView view) => MaterialApp(home: Scaffold(body: view));

NoteView _view(
  String path,
  Future<String> Function(String) readNote, {
  int reloadToken = 0,
}) => NoteView(
  path: path,
  showLineNumbers: false,
  autofocusEditor: false,
  readNote: readNote,
  writeNote: (_, _) async {},
  reloadToken: reloadToken,
);

MarkdownSourceViewState _surface(WidgetTester tester) =>
    tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

String _text(WidgetTester tester) => _surface(tester).widget.buffer.text;

final Finder _error = find.byKey(const Key('note-load-error'));

/// A load that ended in the last turn, and the frame its setState asked for.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('a late failure of the note left does not mark the note shown', (
    tester,
  ) async {
    final late = Completer<String>();
    Future<String> read(String path) =>
        path.endsWith('a.md') ? late.future : Future.value('note b');

    await tester.pumpWidget(_app(_view('/notes/a.md', read)));
    await tester.pumpWidget(_app(_view('/notes/b.md', read)));
    await tester.pump();
    expect(_text(tester), 'note b');

    // The slow read of a.md gives up after b.md is on screen.
    late.completeError(const FileSystemException('locked'));
    await _settle(tester);

    expect(_error, findsNothing, reason: 'b.md loaded; a.md is not its error');
    expect(_text(tester), 'note b');
    expect(find.text(AppStrings.noteStatusSaved), findsOneWidget);
  });

  testWidgets('a load of the note finishing after it was left and come back to '
      'does not replace what was typed', (tester) async {
    final first = Completer<String>();
    final second = Completer<String>();
    var reads = 0;
    Future<String> read(String path) {
      if (!path.endsWith('a.md')) return Future.value('note b');
      return ++reads == 1 ? first.future : second.future;
    }

    await tester.pumpWidget(_app(_view('/notes/a.md', read)));
    await tester.pumpWidget(_app(_view('/notes/b.md', read)));
    await tester.pump();
    await tester.pumpWidget(_app(_view('/notes/a.md', read)));
    second.complete('fresh a');
    await tester.pump();
    expect(_text(tester), 'fresh a');

    // The user types; then the first, forgotten load of a.md lands.
    _surface(tester).replaceText(0, 0, 'typed ');
    await tester.pump();
    first.complete('stale a');
    await _settle(tester);

    expect(_text(tester), 'typed fresh a');
  });

  testWidgets('a failed load offers Retry, and Retry opens the note', (
    tester,
  ) async {
    var attempts = 0;
    Future<String> read(String path) async {
      if (++attempts == 1) throw const FileSystemException('busy');
      return 'the note';
    }

    await tester.pumpWidget(_app(_view('/notes/a.md', read)));
    await tester.pump();
    expect(_error, findsOneWidget);

    await tester.tap(find.byKey(const Key('note-load-error-retry')));
    await tester.pump();

    expect(_error, findsNothing);
    expect(_text(tester), 'the note');
  });

  testWidgets('the next reload trigger tries a failed load again', (
    tester,
  ) async {
    var attempts = 0;
    Future<String> read(String path) async {
      if (++attempts == 1) throw const FileSystemException('busy');
      return 'the note';
    }

    await tester.pumpWidget(_app(_view('/notes/a.md', read)));
    await tester.pump();
    expect(_error, findsOneWidget);

    await tester.pumpWidget(_app(_view('/notes/a.md', read, reloadToken: 1)));
    await tester.pump();

    expect(_error, findsNothing);
    expect(_text(tester), 'the note');
  });

  testWidgets('a file that is not text offers no Retry', (tester) async {
    await tester.pumpWidget(
      _app(
        _view(
          '/notes/a.png',
          (_) async => throw const NoteReadFailure('x', notText: true),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(AppStrings.noteNotText), findsOneWidget);
    expect(find.byKey(const Key('note-load-error-retry')), findsNothing);
  });

  group('the error says why', () {
    Future<void> failWith(WidgetTester tester, Object error) async {
      await tester.pumpWidget(
        _app(_view('/notes/a.md', (_) => Future<String>.error(error))),
      );
      await tester.pump();
    }

    testWidgets('a file that is gone', (tester) async {
      await failWith(
        tester,
        const PathNotFoundException('/notes/a.md', OSError()),
      );
      expect(find.text(AppStrings.noteLoadMissing), findsOneWidget);
    });

    testWidgets('a read the system refused', (tester) async {
      await failWith(
        tester,
        const PathAccessException('/notes/a.md', OSError()),
      );
      expect(find.text(AppStrings.noteLoadDenied), findsOneWidget);
    });

    testWidgets('a file another program holds', (tester) async {
      // 32 is Windows' sharing violation; 16 is EBUSY elsewhere.
      final code = Platform.isWindows ? 32 : 16;
      await failWith(
        tester,
        FileSystemException('open failed', '/notes/a.md', OSError('', code)),
      );
      expect(find.text(AppStrings.noteLoadLocked), findsOneWidget);
    });

    testWidgets('anything else keeps the plain words', (tester) async {
      await failWith(tester, StateError('who knows'));
      expect(find.text(AppStrings.noteLoadFailed), findsOneWidget);
    });
  });
}
