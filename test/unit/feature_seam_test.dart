// #1109, the seam: what each catalogue says about the features. A command,
// a destination and a settings area answer the feature they belong to, and
// the destinations keep the layout out of it — a feature that is off hides
// a destination without writing to Navigation, and on again restores it.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/feature_names.dart';
import 'package:niman/src/ui/palette/command_features.dart';
import 'package:niman/src/ui/settings_area_features.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/shell_navigation.dart';

Features off(Iterable<LibraryFeature> features) =>
    [for (final feature in features) feature]
        .fold(const Features(), (all, f) => all.withSwitch(f, on: false));

void main() {
  group('commands', () {
    test('the commands of a feature answer it', () {
      expect(featureOf(AppCommand.newTodo), LibraryFeature.todo);
      expect(featureOf(AppCommand.tabTodo), LibraryFeature.todo);
      expect(featureOf(AppCommand.journalToday), LibraryFeature.journal);
      expect(featureOf(AppCommand.journalCalendar), LibraryFeature.journal);
      expect(featureOf(AppCommand.focusSearch), LibraryFeature.search);
      expect(featureOf(AppCommand.tabSearch), LibraryFeature.search);
      expect(featureOf(AppCommand.quickNote), LibraryFeature.quickNote);
      expect(featureOf(AppCommand.captureWebPage), LibraryFeature.capture);
      expect(featureOf(AppCommand.pasteAsMarkdown), LibraryFeature.capture);
      expect(featureOf(AppCommand.recognizeText), LibraryFeature.ocr);
      expect(featureOf(AppCommand.newListNote), LibraryFeature.kindList);
      expect(featureOf(AppCommand.newAudioNote), LibraryFeature.kindAudio);
      expect(featureOf(AppCommand.presentSlides), LibraryFeature.kindSlides);
      expect(featureOf(AppCommand.presenterView), LibraryFeature.kindSlides);
      expect(featureOf(AppCommand.studyDeck), LibraryFeature.kindFlashcards);
      expect(featureOf(AppCommand.tabStudy), LibraryFeature.kindFlashcards);
      expect(featureOf(AppCommand.tabHome), LibraryFeature.home);
    });

    test('files, the editor, export, trash and settings are core', () {
      for (final command in [
        AppCommand.newNote,
        AppCommand.renameNote,
        AppCommand.deleteNote,
        AppCommand.noteHistory,
        AppCommand.exportNote,
        AppCommand.exportLibrary,
        AppCommand.togglePreview,
        AppCommand.openPalette,
        AppCommand.goToNote,
        AppCommand.tabFiles,
        AppCommand.tabSettings,
        AppCommand.switchLibrary,
      ]) {
        expect(featureOf(command), isNull, reason: '$command');
      }
    });

    test('a command is on while its feature is, and a core one always', () {
      final noTodo = off([LibraryFeature.todo]);
      expect(commandFeatureOn(AppCommand.newTodo, noTodo), isFalse);
      expect(commandFeatureOn(AppCommand.newTodo, const Features()), isTrue);
      expect(commandFeatureOn(AppCommand.newNote, noTodo), isTrue);
      // A child follows its parent: shopping lists have no command, but
      // transcription's parent is the audio notes.
      expect(
        off([LibraryFeature.kindAudio]).isOn(LibraryFeature.transcription),
        isFalse,
      );
    });

    test('every feature has a name', () {
      final names = {for (final f in LibraryFeature.values) featureName(f)};
      expect(names, hasLength(LibraryFeature.values.length));
      expect(names, isNot(contains('')));
    });
  });

  group('settings areas', () {
    test('the areas of a feature answer it', () {
      expect(featureOfArea(SettingsAreaId.journal), LibraryFeature.journal);
      expect(
        featureOfArea(SettingsAreaId.study),
        LibraryFeature.kindFlashcards,
      );
      expect(
        featureOfArea(SettingsAreaId.transcription),
        LibraryFeature.transcription,
      );
      expect(featureOfArea(SettingsAreaId.textRecognition), LibraryFeature.ocr);
      expect(featureOfArea(SettingsAreaId.navigation), isNull);
      expect(featureOfArea(SettingsAreaId.sync), isNull);
    });

    test('an area is shown while its feature is on', () {
      final noJournal = off([LibraryFeature.journal]);
      expect(areaShown(SettingsAreaId.journal, noJournal), isFalse);
      expect(areaShown(SettingsAreaId.journal, const Features()), isTrue);
      expect(areaShown(SettingsAreaId.folders, noJournal), isTrue);
      // The audio notes take transcription with them.
      expect(
        areaShown(
          SettingsAreaId.transcription,
          off([LibraryFeature.kindAudio]),
        ),
        isFalse,
      );
    });

    test('Reminders goes only when todo and the calendar are both off', () {
      expect(
        areaShown(SettingsAreaId.reminders, off([LibraryFeature.todo])),
        isTrue,
      );
      expect(
        areaShown(SettingsAreaId.reminders, off([LibraryFeature.calendar])),
        isTrue,
      );
      expect(
        areaShown(
          SettingsAreaId.reminders,
          off([LibraryFeature.todo, LibraryFeature.calendar]),
        ),
        isFalse,
      );
    });
  });

  group('destinations', () {
    List<String> shown(NavigationLayout layout, Features features) => [
      for (final d in visibleDestinations(layout, features: features)) d.name,
    ];

    test('a feature that is off hides its destination', () {
      const layout = NavigationLayout();
      expect(shown(layout, const Features()), contains('todo'));
      expect(
        shown(layout, off([LibraryFeature.todo])),
        isNot(contains('todo')),
      );
      expect(
        shown(layout, off([LibraryFeature.search])),
        isNot(contains('search')),
      );
      expect(
        shown(layout, off([LibraryFeature.home])),
        isNot(contains('home')),
      );
    });

    test('Files and Settings are never switched off', () {
      final everything = off(LibraryFeature.values);
      expect(shown(const NavigationLayout(), everything), [
        'files',
        'settings',
      ]);
    });

    test('nothing is written: on again restores the order and the hidden', () {
      const layout = NavigationLayout(
        order: ['search', 'files', 'settings', 'todo', 'quicknote'],
        hidden: {'quicknote'},
      );
      final before = shown(layout, const Features());
      final during = shown(layout, off([LibraryFeature.todo]));

      expect(during, [
        for (final name in before)
          if (name != 'todo') name,
      ]);
      // The layout is a value nothing touched, and it still says the same.
      expect(layout.order.first, 'search');
      expect(layout.hidden, {'quicknote'});
      expect(shown(layout, const Features()), before);
    });

    test('a destination off is kept in place, flagged, for Navigation', () {
      final placed = placedDestinations(
        NavigationLayout(
          order: [for (final d in shellDestinations()) d.name],
          hidden: const {'todo'},
        ),
        features: off([LibraryFeature.todo, LibraryFeature.search]),
      );
      final todo = placed.firstWhere((p) => p.destination.name == 'todo');
      final search = placed.firstWhere((p) => p.destination.name == 'search');
      final files = placed.firstWhere((p) => p.destination.name == 'files');
      // Navigation's own choice is kept apart from the feature's.
      expect((todo.hidden, todo.off), (true, true));
      expect((search.hidden, search.off), (false, true));
      expect((files.hidden, files.off), (false, false));
      expect(placed.map((p) => p.destination.name), [
        for (final d in shellDestinations()) d.name,
      ]);
    });

    test('Opens on follows the destinations shown', () {
      const layout = NavigationLayout(start: 'todo');
      expect(startDestination(layout), ShellTab.todo);
      expect(
        startDestination(layout, features: off([LibraryFeature.todo])),
        ShellTab.files,
      );
      expect(
        startDestinations(
          layout,
          features: off([LibraryFeature.todo]),
        ).map((d) => d.name),
        isNot(contains('todo')),
      );
      expect(
        startLabel(layout, features: off([LibraryFeature.todo])),
        isNotNull,
      );
    });

    test('the bar keeps two destinations whatever the features say', () {
      // Hidden by hand all but Settings, and Files off by nothing: the
      // first hidden one is shown back, as before the features existed.
      final names = [for (final d in shellDestinations()) d.name];
      final layout = NavigationLayout(
        order: names,
        hidden: {
          for (final n in names)
            if (!lockedDestinations.contains(n)) n,
        },
      );
      expect(shown(layout, off([LibraryFeature.todo])).length, 2);
      // A feature that is off is not the one shown back.
      final back = shown(layout, off([LibraryFeature.todo]));
      expect(back, isNot(contains('todo')));
    });
  });
}
