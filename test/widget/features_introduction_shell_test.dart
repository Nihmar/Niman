// #1109, the introduction in a built shell: a library that has not been
// through it opens Settings → Features once on a normal open — the floating
// window on a wide screen, the screen itself on a phone — and the flag is
// written when the screen is left, never when it opens. A share, a widget
// tap, a notification, a launcher action leave the flag as it was, and a
// widget's "Open Features" opens the screen without recording anything.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/feature_preset.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/features_introduction.dart';
import 'package:niman/src/core/share_in.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/core/welcome.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/features/settings_features.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/widget/widget_target.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_reminder_service.dart';
import '../fakes/fake_share_service.dart';
import '../fakes/fake_shortcut_service.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_widget_target_service.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;
  late FakeShareInService shares;
  late FakeShortcutService shortcuts;
  late FakeWidgetTargetService targets;
  late FakeReminderService reminders;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    shares = FakeShareInService();
    shortcuts = FakeShortcutService();
    targets = FakeWidgetTargetService();
    reminders = FakeReminderService();
  });

  Future<void> pumpAt(
    WidgetTester tester,
    Size size, {
    FeaturesIntroduction introduction = FeaturesIntroduction.existing,
  }) async {
    controller.pendingIntroduction = introduction;
    setSurfaceSize(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          shareInServiceProvider.overrideWithValue(shares),
          shortcutServiceProvider.overrideWithValue(shortcuts),
          widgetTargetServiceProvider.overrideWithValue(targets),
          reminderServiceProvider.overrideWithValue(reminders),
          welcomeStoreProvider.overrideWith(
            (ref) async => MemoryWelcomeStore()..deckSeen = true,
          ),
          todoSourceFactoryProvider.overrideWithValue(
            (_) => FakeTodoSource(todo: const <String>[]),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    // The introduction is offered once the launch requests have answered,
    // and its window opens on the frame after.
    await settle(tester);
  }

  Finder window() => find.byKey(const Key('settings-window'));
  Finder card(FeaturesIntroduction introduction) =>
      find.byKey(Key('features-introduction-${introduction.name}'));

  const wide = Size(1400, 900);
  const phone = Size(390, 844);

  group('a normal open', () {
    testWidgets('on a wide screen opens the floating window at Features with '
        'the card, and writes nothing', (tester) async {
      await pumpAt(tester, wide);

      expect(window(), findsOneWidget);
      expect(find.byType(SettingsFeaturesScreen), findsOneWidget);
      expect(card(FeaturesIntroduction.existing), findsOneWidget);
      expect(find.text(AppStrings.featuresIntroBody), findsOneWidget);
      expect(controller.featuresReviewed, isFalse);
    });

    testWidgets('Done closes it and records it', (tester) async {
      await pumpAt(tester, wide);
      await tester.tap(find.byKey(const Key('features-introduction-done')));
      await settle(tester);

      expect(window(), findsNothing);
      expect(controller.featuresReviewed, isTrue);
    });

    testWidgets('Esc closes it and records it', (tester) async {
      await pumpAt(tester, wide);
      expect(controller.featuresReviewed, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);

      expect(window(), findsNothing);
      expect(controller.featuresReviewed, isTrue);
    });

    testWidgets('a library already through it opens plain', (tester) async {
      controller.featuresReviewed = true;
      await pumpAt(tester, wide);
      expect(window(), findsNothing);
    });

    testWidgets('on a phone it is the Features screen, and back records it', (
      tester,
    ) async {
      await pumpAt(tester, phone);

      expect(find.byType(SettingsFeaturesScreen), findsOneWidget);
      expect(card(FeaturesIntroduction.existing), findsOneWidget);
      expect(controller.featuresReviewed, isFalse);

      await tester.pageBack();
      await settle(tester);
      expect(find.byType(SettingsFeaturesScreen), findsNothing);
      expect(controller.featuresReviewed, isTrue);
    });

    testWidgets('a library being created asks what it is for, with the '
        'presets as cards, and a pick applies live', (tester) async {
      await pumpAt(tester, wide, introduction: FeaturesIntroduction.created);

      expect(card(FeaturesIntroduction.created), findsOneWidget);
      expect(find.text(AppStrings.featuresCreatedTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('feature-preset-card-notesOnly')));
      await settle(tester);
      expect(
        controller.features.value,
        const Features().withPreset(FeaturePreset.notesOnly),
      );
      expect(controller.featuresReviewed, isFalse);

      await tester.tap(find.byKey(const Key('features-introduction-done')));
      await settle(tester);
      expect(controller.featuresReviewed, isTrue);
    });
  });

  group('a request from outside leaves the flag as it was', () {
    testWidgets('a share', (tester) async {
      shares.launchRequest = const SharedText('shared words');
      await pumpAt(tester, wide);
      expect(window(), findsNothing);
      expect(controller.featuresReviewed, isFalse);
    });

    testWidgets('a widget tap', (tester) async {
      targets.launchTarget = WidgetTarget(
        kind: WidgetTargetKind.todo,
        libraryPath: p.join('/fake', 'library'),
      );
      await pumpAt(tester, phone);
      expect(find.byType(SettingsFeaturesScreen), findsNothing);
      expect(controller.featuresReviewed, isFalse);
    });

    testWidgets('a notification', (tester) async {
      reminders = FakeReminderService(launchPayload: todoReminderPayload);
      await pumpAt(tester, wide);
      expect(window(), findsNothing);
      expect(controller.featuresReviewed, isFalse);
    });

    testWidgets('a launcher action', (tester) async {
      shortcuts.launchAction = ShortcutAction.quickNote;
      await pumpAt(tester, wide);
      expect(window(), findsNothing);
      expect(controller.featuresReviewed, isFalse);
    });

    testWidgets('the next normal open still shows it', (tester) async {
      shares.launchRequest = const SharedText('shared words');
      await pumpAt(tester, wide);
      expect(window(), findsNothing);
      expect(
        await controller.featuresIntroduction,
        FeaturesIntroduction.existing,
      );
    });
  });

  group("a widget's Open Features", () {
    testWidgets('opens the screen without the card and records nothing', (
      tester,
    ) async {
      targets.launchTarget = WidgetTarget(
        kind: WidgetTargetKind.features,
        libraryPath: p.join('/fake', 'library'),
      );
      await pumpAt(tester, wide);

      expect(window(), findsOneWidget);
      expect(find.byType(SettingsFeaturesScreen), findsOneWidget);
      expect(card(FeaturesIntroduction.existing), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(window(), findsNothing);
      expect(controller.featuresReviewed, isFalse);
    });

    testWidgets('on a phone opens Settings at Features', (tester) async {
      targets.launchTarget = WidgetTarget(
        kind: WidgetTargetKind.features,
        libraryPath: p.join('/fake', 'library'),
      );
      await pumpAt(tester, phone);

      expect(find.byType(SettingsFeaturesScreen), findsOneWidget);
      expect(card(FeaturesIntroduction.existing), findsNothing);
      expect(controller.featuresReviewed, isFalse);
    });
  });
}
