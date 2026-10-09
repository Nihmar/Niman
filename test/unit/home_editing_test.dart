// #535: editing the Home — a tile moved a cell at a time, hidden and shown
// again, and every change written where the Home is kept.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/home/home_tile_move.dart';
import 'package:niman/src/ui/home/home_editing.dart';

import '../fakes/fake_library_session.dart';

void main() {
  group('HomeTileMove', () {
    const cell = (x: 1, y: 1, w: 2, h: 2);

    test('steps one cell, and stays on the grid', () {
      expect(HomeTileMove.left.apply(cell), (x: 0, y: 1, w: 2, h: 2));
      expect(HomeTileMove.right.apply(cell), (x: 2, y: 1, w: 2, h: 2));
      expect(HomeTileMove.right.apply((x: 2, y: 0, w: 2, h: 1)), (
        x: 2,
        y: 0,
        w: 2,
        h: 1,
      ), reason: 'already at the right edge');
      expect(HomeTileMove.up.apply((x: 0, y: 0, w: 1, h: 1)).y, 0);
      expect(HomeTileMove.down.apply(cell).y, 2);
      expect(HomeTileMove.wider.apply(cell).w, 3);
      expect(HomeTileMove.wider.apply((x: 2, y: 0, w: 2, h: 1)).w, 2);
      expect(HomeTileMove.narrower.apply((x: 0, y: 0, w: 1, h: 1)).w, 1);
      expect(HomeTileMove.taller.apply((x: 0, y: 0, w: 1, h: 4)).h, 4);
      expect(HomeTileMove.shorter.apply(cell).h, 1);
    });
  });

  group('show and hide', () {
    test('hide keeps the tile and its settings; show puts it at the foot', () {
      final hidden = HomeLayout.defaults.hide('recent');
      expect(hidden['recent']!.hidden, isTrue);
      expect(hidden.column.map((t) => t.id), isNot(contains('recent')));

      final shown = hidden.show('recent');
      final recent = shown['recent']!;
      expect(recent.hidden, isFalse);
      expect(recent.cell.y, hidden.bottom);
      expect(recent.cell.h, HomeLayout.defaults['recent']!.cell.h);
      expect(shown.column.last.id, 'recent');
    });

    test('are no-ops on a tile already so, or not there', () {
      expect(
        identical(HomeLayout.defaults.show('recent'), HomeLayout.defaults),
        isTrue,
      );
      final hidden = HomeLayout.defaults.hide('recent');
      expect(identical(hidden.hide('recent'), hidden), isTrue);
      expect(identical(hidden.show('nope'), hidden), isTrue);
    });
  });

  group('HomeEditing', () {
    late FakeLibrarySession session;
    late HomeEditing editing;

    setUp(() async {
      session = FakeLibrarySession();
      await session.open('/lib', create: true);
      editing = HomeEditing(session);
    });

    tearDown(() {
      editing.dispose();
      return session.dispose();
    });

    test('a read waits for the write before it (#684)', () async {
      final landed = Completer<void>();
      session.holdHomeWrites = landed.future;
      unawaited(editing.change(HomeLayout.defaults.hide('recent')));

      final read = editing.load();
      landed.complete();
      await read;

      expect(editing.layout['recent']!.hidden, isTrue);
      expect(session.libraryHome!['recent']!.hidden, isTrue);
    });

    test(
      'a read that ends after the Home is gone notifies no one (#689)',
      () async {
        final gone = HomeEditing(session);
        final read = gone.load();
        gone.dispose();

        await expectLater(read, completes);
      },
    );

    test('shows the defaults until the Home is edited', () async {
      await editing.load();
      expect(editing.layout, HomeLayout.defaults);
      expect(editing.onDevice, isFalse);
      expect(session.libraryHome, isNull, reason: 'nothing written');
    });

    test('writes a change into the library', () async {
      await editing.load();
      await editing.change(HomeLayout.defaults.hide('pinned'));
      expect(session.libraryHome!['pinned']!.hidden, isTrue);
      expect(session.deviceHome, isNull);
    });

    test(
      'only on this device starts from the Home shown, then keeps to it',
      () async {
        session.libraryHome = HomeLayout.defaults.hide('pinned');
        await editing.load();
        await editing.keepOnDevice();
        expect(session.deviceHome, session.libraryHome);

        await editing.change(editing.layout.add(HomeTileKind.topTags));
        expect(session.deviceHome!['topTags'], isNotNull);
        expect(
          session.libraryHome!['topTags'],
          isNull,
          reason: 'library untouched',
        );

        await editing.useLibrary();
        expect(session.deviceHome, isNull);
        expect(editing.layout, session.libraryHome);
        expect(editing.onDevice, isFalse);
      },
    );

    test('reset puts the defaults back where the Home is kept', () async {
      session.libraryHome = HomeLayout.defaults.hide('pinned');
      await editing.load();
      await editing.reset();
      expect(session.libraryHome, HomeLayout.defaults);
    });
  });
}
