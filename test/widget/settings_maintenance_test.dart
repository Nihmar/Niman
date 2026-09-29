// #493: "Rebuild index" tears the session down and re-reads the notes into
// a fresh index. While that runs the settings row is disabled, so a second
// tap cannot tear down and delete the index the first is opening.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_maintenance.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

void main() {
  testWidgets('a second tap during a rebuild does nothing', (tester) async {
    final session = FakeLibrarySession();
    await session.open(p.join('/fake', 'library'), create: false);
    final gate = Completer<void>();
    session.rebuildGate = gate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsMaintenanceGroup(controller: session)),
      ),
    );
    await tester.pumpAndSettle();

    final row = find.byKey(SettingsKeys.rebuildIndex);
    final tile = find.descendant(of: row, matching: find.byType(ListTile));
    await tester.tap(tile);
    await tester.pump();
    expect(session.indexRebuilds, 1);
    expect(
      tester.widget<ListTile>(tile).onTap,
      isNull,
      reason: 'the row is disabled while the rebuild runs',
    );

    await tester.tap(tile);
    await tester.pump();
    expect(session.indexRebuilds, 1, reason: 'the second tap did nothing');

    gate.complete();
    await tester.pumpAndSettle();
    expect(
      tester.widget<ListTile>(tile).onTap,
      isNotNull,
      reason: 'the row works again once the rebuild is done',
    );
  });
}
