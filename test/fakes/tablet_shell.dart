// The app on a tablet (#1266): an Android window wide enough for the wide
// shell, its density a thumb's, and a library with two notes in it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/window_controller.dart';

import 'fake_library_session.dart';
import 'fake_todo_source.dart';
import 'fake_window_controller.dart';
import 'shell_harness.dart';

/// An 11″ tablet in landscape.
const Size tabletLandscape = Size(1194, 834);

/// The same tablet in portrait.
const Size tabletPortrait = Size(834, 1194);

/// Only Android: a touch device's density.
final TargetPlatformVariant tabletPlatform = TargetPlatformVariant.only(
  TargetPlatform.android,
);

/// Pumps the app at [size] over [controller], its tasks [todo], opens the
/// library through [filePicker] and makes `alpha.md` and `beta.md`.
Future<void> pumpTabletShell(
  WidgetTester tester, {
  required FakeLibrarySession controller,
  required FakeFilePicker filePicker,
  Size size = tabletLandscape,
  FakeTodoSource? todo,
}) async {
  setSurfaceSize(tester, size);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(controller),
        todoSourceFactoryProvider.overrideWithValue(
          (_) => todo ?? FakeTodoSource(),
        ),
        windowControllerProvider.overrideWithValue(FakeWindowController()),
      ],
      child: const NimanApp(),
    ),
  );
  await tester.pump();
  await openLibrary(tester, filePicker);
  await controller.createNote(parentPath: '', name: 'alpha');
  await controller.createNote(parentPath: '', name: 'beta');
  await settle(tester);
}

/// Raises the software keyboard to [height] dp, as a field being tapped
/// does.
Future<void> raiseTabletKeyboard(WidgetTester tester, double height) async {
  tester.view.viewInsets = FakeViewPadding(bottom: height);
  addTearDown(tester.view.resetViewInsets);
  await settle(tester);
}
