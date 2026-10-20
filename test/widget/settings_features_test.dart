// #1109, Settings → Library → Features: the presets pinned over the list
// with Custom always last, a switch written as it is flipped, a child
// greyed with "Needs …" while its parent is off and keeping its own value,
// the snackbar with Undo after a switch that cancelled reminders, the
// introduction above the presets (recorded when the screen is left, never
// when it opens), and *Show this introduction again*.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/feature_preset.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/features_introduction.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/todo/reminder_cancellation.dart';
import 'package:niman/src/ui/feature_names.dart';
import 'package:niman/src/ui/features/features_host.dart';
import 'package:niman/src/ui/features/settings_features.dart';
import 'package:niman/src/ui/features_link.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/settings_area_features.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession controller;

  setUp(() async {
    controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
  });

  Features off(Iterable<LibraryFeature> features) => features.fold(
    const Features(),
    (all, feature) => all.withSwitch(feature, on: false),
  );

  /// Pumps the screen over a home route, so leaving it has a place to go.
  Future<void> pump(
    WidgetTester tester, {
    FeaturesHost host = const FeaturesHost(),
    Size size = const Size(900, 1800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open-features'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsFeaturesScreen(
                      controller: controller,
                      host: host,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-features')));
    await tester.pumpAndSettle();
  }

  Finder rowOf(LibraryFeature feature) =>
      find.byKey(SettingsKeys.featureRow(feature));

  Finder switchOf(LibraryFeature feature) =>
      find.descendant(of: rowOf(feature), matching: find.byType(Switch));

  ChoiceChip chip(WidgetTester tester, String key) =>
      tester.widget<ChoiceChip>(find.byKey(Key(key)));

  Future<void> flip(WidgetTester tester, LibraryFeature feature) async {
    await tester.ensureVisible(switchOf(feature));
    await tester.tap(switchOf(feature));
    await tester.pumpAndSettle();
  }

  group('the screen', () {
    testWidgets('lists every feature under its section, in cards', (
      tester,
    ) async {
      await pump(tester);
      for (final heading in [
        AppStrings.featuresSectionFinding,
        AppStrings.featuresSectionPlanning,
        AppStrings.featuresSectionKinds,
        AppStrings.featuresSectionReading,
        AppStrings.featuresSectionAround,
      ]) {
        expect(find.text(heading), findsOneWidget);
      }
      for (final feature in LibraryFeature.values) {
        await tester.ensureVisible(rowOf(feature));
        expect(rowOf(feature), findsOneWidget);
        expect(
          find.descendant(
            of: rowOf(feature),
            matching: find.text(featureName(feature)),
          ),
          findsOneWidget,
        );
        expect(tester.widget<Switch>(switchOf(feature)).value, isTrue);
      }
    });

    testWidgets('the widgets row is tagged Android, on every platform', (
      tester,
    ) async {
      await pump(tester);
      await tester.ensureVisible(rowOf(LibraryFeature.widgets));
      expect(
        find.descendant(
          of: rowOf(LibraryFeature.widgets),
          matching: find.text('Android'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: rowOf(LibraryFeature.search),
          matching: find.text('Android'),
        ),
        findsNothing,
      );
    });

    testWidgets('a switch is written as it is flipped', (tester) async {
      await pump(tester);

      await flip(tester, LibraryFeature.journal);
      expect(controller.features.value.own(LibraryFeature.journal), isFalse);
      expect(controller.features.value.own(LibraryFeature.todo), isTrue);
      expect(
        tester.widget<Switch>(switchOf(LibraryFeature.journal)).value,
        isFalse,
      );

      await flip(tester, LibraryFeature.journal);
      expect(controller.features.value, const Features());
    });

    testWidgets('a child of an off parent is greyed, says what it needs, and '
        'keeps its own value', (tester) async {
      await pump(tester);

      await flip(tester, LibraryFeature.kindAudio);
      await tester.ensureVisible(rowOf(LibraryFeature.transcription));
      final child = tester.widget<Switch>(
        switchOf(LibraryFeature.transcription),
      );
      expect(child.onChanged, isNull);
      expect(child.value, isTrue);
      expect(
        find.descendant(
          of: rowOf(LibraryFeature.transcription),
          matching: find.text(
            AppStrings.featureNeeds(featureName(LibraryFeature.kindAudio)),
          ),
        ),
        findsOneWidget,
      );

      // A tap on the greyed row changes nothing.
      await tester.tap(rowOf(LibraryFeature.transcription));
      await tester.pumpAndSettle();
      expect(
        controller.features.value.own(LibraryFeature.transcription),
        isTrue,
      );

      // The parent back on: the child is back as it was, and flippable.
      await flip(tester, LibraryFeature.kindAudio);
      final back = tester.widget<Switch>(
        switchOf(LibraryFeature.transcription),
      );
      expect(back.onChanged, isNotNull);
      expect(back.value, isTrue);
      expect(
        find.descendant(
          of: rowOf(LibraryFeature.transcription),
          matching: find.text(AppStrings.featureOffTranscription),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an off child stays off when its parent comes back', (
      tester,
    ) async {
      await pump(tester);
      await flip(tester, LibraryFeature.transcription);
      await flip(tester, LibraryFeature.kindAudio);
      await flip(tester, LibraryFeature.kindAudio);
      expect(
        tester.widget<Switch>(switchOf(LibraryFeature.transcription)).value,
        isFalse,
      );
    });
  });

  group('the presets', () {
    testWidgets('Everything is selected on a library that never touched the '
        'screen, and Custom is dimmed and last', (tester) async {
      await pump(tester);
      expect(chip(tester, 'feature-preset-everything').selected, isTrue);
      expect(chip(tester, 'feature-preset-custom').selected, isFalse);
      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byKey(const Key('feature-preset-custom')),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, lessThan(1));

      // Custom is the strip's last chip.
      final custom = tester.getTopLeft(
        find.byKey(const Key('feature-preset-custom')),
      );
      for (final preset in FeaturePreset.values) {
        expect(
          tester
              .getTopLeft(find.byKey(Key('feature-preset-${preset.name}')))
              .dx,
          lessThan(custom.dx),
        );
      }
    });

    testWidgets('a preset writes every switch', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('feature-preset-notesOnly')));
      await tester.pumpAndSettle();

      expect(
        controller.features.value,
        const Features().withPreset(FeaturePreset.notesOnly),
      );
      expect(chip(tester, 'feature-preset-notesOnly').selected, isTrue);
      expect(chip(tester, 'feature-preset-everything').selected, isFalse);
      await tester.ensureVisible(switchOf(LibraryFeature.todo));
      expect(
        tester.widget<Switch>(switchOf(LibraryFeature.todo)).value,
        isFalse,
      );
    });

    testWidgets('Custom is selected when the switches match no preset, and '
        'tapping it is not an action', (tester) async {
      await pump(tester);
      await flip(tester, LibraryFeature.capture);

      expect(chip(tester, 'feature-preset-custom').selected, isTrue);
      for (final preset in FeaturePreset.values) {
        expect(chip(tester, 'feature-preset-${preset.name}').selected, isFalse);
      }
      final before = controller.features.value;
      await tester.tap(
        find.byKey(const Key('feature-preset-custom')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(controller.features.value, before);
    });

    testWidgets('the strip stays pinned while the list scrolls', (
      tester,
    ) async {
      await pump(tester, size: const Size(600, 500));
      final at = tester.getTopLeft(
        find.byKey(const Key('feature-preset-everything')),
      );
      await tester.drag(
        find.byKey(const Key('features-list')),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const Key('feature-preset-everything'))),
        at,
      );
    });
  });

  group('the snackbar', () {
    Future<ReminderCancellation> three() async =>
        const ReminderCancellation(todo: 2, calendar: 1);

    testWidgets('a switch that cancelled reminders says how many, and Undo '
        'turns it back on', (tester) async {
      await pump(tester, host: FeaturesHost(featureReconcile: three));

      await flip(tester, LibraryFeature.todo);
      expect(controller.features.value.isOn(LibraryFeature.todo), isFalse);
      expect(
        find.text(AppStrings.featuresRemindersCancelled(3)),
        findsOneWidget,
      );

      await tester.tap(find.text(AppStrings.actionUndo));
      await tester.pumpAndSettle();
      expect(controller.features.value, const Features());
      expect(
        tester.widget<Switch>(switchOf(LibraryFeature.todo)).value,
        isTrue,
      );
    });

    testWidgets('Undo leaves the switches changed since as they are', (
      tester,
    ) async {
      await pump(tester, host: FeaturesHost(featureReconcile: three));
      await flip(tester, LibraryFeature.todo);
      await flip(tester, LibraryFeature.capture);

      await tester.tap(find.text(AppStrings.actionUndo));
      await tester.pumpAndSettle();
      expect(controller.features.value, off([LibraryFeature.capture]));
    });

    testWidgets('a preset that turned Todo off says it too', (tester) async {
      await pump(tester, host: FeaturesHost(featureReconcile: three));
      await tester.tap(find.byKey(const Key('feature-preset-notesOnly')));
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.featuresRemindersCancelled(3)),
        findsOneWidget,
      );
    });

    testWidgets('no reminders cancelled, no snackbar; a switch that is not '
        'Todo or Calendar never asks', (tester) async {
      var asked = 0;
      await pump(
        tester,
        host: FeaturesHost(
          featureReconcile: () async {
            asked++;
            return ReminderCancellation.none;
          },
        ),
      );
      await flip(tester, LibraryFeature.calendar);
      expect(asked, 1);
      expect(find.byType(SnackBar), findsNothing);

      await flip(tester, LibraryFeature.capture);
      await flip(tester, LibraryFeature.calendar);
      expect(asked, 1);
    });

    testWidgets('one reminder is said in the singular', (tester) async {
      await pump(
        tester,
        host: FeaturesHost(
          featureReconcile: () async => const ReminderCancellation(todo: 1),
        ),
      );
      await flip(tester, LibraryFeature.todo);
      expect(
        find.text(AppStrings.featuresRemindersCancelled(1)),
        findsOneWidget,
      );
      expect(
        AppStrings.featuresRemindersCancelled(1),
        isNot(AppStrings.featuresRemindersCancelled(2)),
      );
    });
  });

  group('the introduction', () {
    testWidgets('opening it writes nothing; Done leaves and records it', (
      tester,
    ) async {
      await pump(
        tester,
        host: const FeaturesHost(introduction: FeaturesIntroduction.existing),
      );
      expect(find.text(AppStrings.featuresIntroTitle), findsOneWidget);
      expect(find.text(AppStrings.featuresIntroBody), findsOneWidget);
      expect(controller.featuresReviewed, isFalse);
      expect(controller.features.value, const Features());

      await tester.tap(find.byKey(const Key('features-introduction-done')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsFeaturesScreen), findsNothing);
      expect(controller.featuresReviewed, isTrue);
    });

    testWidgets('back records it', (tester) async {
      await pump(
        tester,
        host: const FeaturesHost(introduction: FeaturesIntroduction.existing),
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(controller.featuresReviewed, isTrue);
    });

    testWidgets('a screen still open has recorded nothing, so a kill shows '
        'the introduction again', (tester) async {
      controller.pendingIntroduction = FeaturesIntroduction.existing;
      await pump(
        tester,
        host: const FeaturesHost(introduction: FeaturesIntroduction.existing),
      );
      await flip(tester, LibraryFeature.capture);
      await tester.pump(const Duration(seconds: 5));
      expect(controller.featuresReviewed, isFalse);
      expect(
        await controller.featuresIntroduction,
        FeaturesIntroduction.existing,
      );
    });

    testWidgets('without an introduction, leaving records nothing', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byKey(const Key('features-introduction-done')), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(controller.featuresReviewed, isFalse);
    });

    testWidgets('a library being created asks what it is for: the presets '
        'are large cards, Everything preselected, and a pick applies live', (
      tester,
    ) async {
      await pump(
        tester,
        host: const FeaturesHost(introduction: FeaturesIntroduction.created),
      );
      expect(find.text(AppStrings.featuresCreatedTitle), findsOneWidget);
      expect(find.text(AppStrings.featuresCreatedBody), findsOneWidget);
      // The cards replace the chip row.
      expect(find.byKey(const Key('feature-preset-custom')), findsNothing);
      expect(find.byKey(const Key('feature-preset-everything')), findsNothing);
      for (final preset in FeaturePreset.values) {
        expect(
          find.byKey(Key('feature-preset-card-${preset.name}')),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: find.byKey(const Key('feature-preset-card-everything')),
          matching: find.byIcon(Icons.radio_button_checked),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('feature-preset-card-notesOnly')));
      await tester.pumpAndSettle();
      expect(
        controller.features.value,
        const Features().withPreset(FeaturePreset.notesOnly),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('feature-preset-card-notesOnly')),
          matching: find.byIcon(Icons.radio_button_checked),
        ),
        findsOneWidget,
      );
      // The switches below follow it.
      await tester.ensureVisible(switchOf(LibraryFeature.todo));
      expect(
        tester.widget<Switch>(switchOf(LibraryFeature.todo)).value,
        isFalse,
      );
      expect(controller.featuresReviewed, isFalse);

      await tester.tap(find.byKey(const Key('features-introduction-done')));
      await tester.pumpAndSettle();
      expect(controller.featuresReviewed, isTrue);
    });

    testWidgets('Show this introduction again shows the card and changes '
        'nothing', (tester) async {
      controller.features.value = off([LibraryFeature.journal]);
      await pump(tester);
      expect(
        find.byKey(const Key('features-introduction-existing')),
        findsNothing,
      );
      final before = controller.features.value;

      await tester.ensureVisible(find.text(AppStrings.featuresShowIntroAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.featuresShowIntroAction));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('features-introduction-existing')),
        findsOneWidget,
      );
      expect(controller.features.value, before);
      expect(controller.featuresReviewed, isFalse);

      // Leaving a screen that was opened for its own sake records nothing,
      // even after the card was asked for.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(controller.featuresReviewed, isFalse);
    });
  });

  group('in the settings', () {
    testWidgets('the area is always listed and its rows are found by search', (
      tester,
    ) async {
      expect(featureOfArea(SettingsAreaId.features), isNull);
      expect(
        areaShown(SettingsAreaId.features, off(LibraryFeature.values)),
        isTrue,
      );

      tester.view.physicalSize = const Size(900, 2800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      controller.features.value = off(LibraryFeature.values);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SettingsBody(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-area-features')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('settings-search-field')),
        featureName(LibraryFeature.search),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          Key('settings-search-feature-row-${LibraryFeature.search.id}'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('featuresTarget opens the Features area', (tester) async {
      expect(featuresTarget.area, SettingsAreaId.features);
      tester.view.physicalSize = const Size(900, 2800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsBody(controller: controller, target: featuresTarget),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SettingsFeaturesScreen), findsOneWidget);
      expect(controller.featuresReviewed, isFalse);
    });
  });
}
