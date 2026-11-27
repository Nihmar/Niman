// A Windows session ending (#1364): the runner asks the app to flush before
// it lets Windows go, and the answer comes only when the disk holds the notes.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/close_guard.dart';
import 'package:niman/src/ui/session_end.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

import '../fakes/fake_window_controller.dart';

/// A note whose save is held until [release].
final class _SlowNote implements UnsavedNote {
  new(this.path);

  @override
  final String path;

  @override
  bool unsaved = true;

  final Completer<void> _gate = Completer<void>();
  int saves = 0;

  @override
  String get text => '';

  void release() => _gate.complete();

  @override
  Future<void> save() async {
    saves++;
    await _gate.future;
    unsaved = false;
  }
}

/// The runner's call: what `flutter_window.cpp` sends on the channel.
Future<Object?> runnerAsksToFlush() async {
  final reply = Completer<Object?>();
  const codec = StandardMethodCodec();
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        SessionEnd.channelName,
        codec.encodeMethodCall(const MethodCall(SessionEnd.flushMethod)),
        (data) =>
            reply.complete(data == null ? null : codec.decodeEnvelope(data)),
      );
  return await reply.future;
}

void main() {
  testWidgets('the reply comes after every pending save is written', (
    tester,
  ) async {
    final tracker = UnsavedTracker();
    final note = _SlowNote('/lib/a.md');
    tracker.register(note);
    await tester.pumpWidget(
      MaterialApp(
        home: CloseGuard(
          tracker: tracker,
          window: FakeWindowController(),
          child: const Scaffold(body: Text('body')),
        ),
      ),
    );
    await tester.pump();

    var replied = false;
    final answer = runnerAsksToFlush().then((value) {
      replied = true;
      return value;
    });
    await tester.pump();
    expect(note.saves, 1, reason: 'the pending save is started at once');
    expect(replied, isFalse, reason: 'and Windows waits for it');

    note.release();
    expect(await answer, isTrue);
    expect(note.unsaved, isFalse, reason: 'the disk had the note by then');
  });

  testWidgets('a clean app answers at once', (tester) async {
    final tracker = UnsavedTracker();
    await tester.pumpWidget(
      MaterialApp(
        home: CloseGuard(
          tracker: tracker,
          window: FakeWindowController(),
          child: const Scaffold(body: Text('body')),
        ),
      ),
    );
    await tester.pump();
    expect(await runnerAsksToFlush(), isTrue);
  });

  testWidgets('a write that fails still answers, with false', (tester) async {
    final tracker = UnsavedTracker();
    final note = _FailingNote('/lib/a.md');
    tracker.register(note);
    final end = SessionEnd(tracker: tracker);
    expect(await end.flush(), isFalse);
    expect(note.saves, 1);
  });

  testWidgets('once the guard is gone nobody answers the runner', (
    tester,
  ) async {
    final tracker = UnsavedTracker();
    await tester.pumpWidget(
      MaterialApp(
        home: CloseGuard(
          tracker: tracker,
          window: FakeWindowController(),
          child: const Scaffold(body: Text('body')),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: Text('gone')));
    // No handler: the runner is told "not implemented", and goes on.
    expect(await runnerAsksToFlush(), isNull);
  });
}

/// A note whose save throws.
final class _FailingNote implements UnsavedNote {
  new(this.path);

  @override
  final String path;

  @override
  bool unsaved = true;

  int saves = 0;

  @override
  String get text => '';

  @override
  Future<void> save() async {
    saves++;
    throw StateError('disk full');
  }
}
