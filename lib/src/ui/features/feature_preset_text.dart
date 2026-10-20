/// How the presets are named on the Features screen (#1109): the chip, and
/// for a library being created the card with its line under the name.
library;

import 'package:niman/src/core/settings/feature_preset.dart';
import 'package:niman/src/ui/strings.dart';

/// [preset]'s name in the language in use.
String featurePresetName(FeaturePreset preset) => switch (preset) {
  FeaturePreset.everything => AppStrings.featurePresetEverything,
  FeaturePreset.writing => AppStrings.featurePresetWriting,
  FeaturePreset.notesOnly => AppStrings.featurePresetNotesOnly,
  FeaturePreset.tasksAndJournal => AppStrings.featurePresetTasks,
};

/// What [preset] leaves on, in a few words: the line of its card.
String featurePresetHint(FeaturePreset preset) => switch (preset) {
  FeaturePreset.everything => AppStrings.featurePresetEverythingHint,
  FeaturePreset.writing => AppStrings.featurePresetWritingHint,
  FeaturePreset.notesOnly => AppStrings.featurePresetNotesOnlyHint,
  FeaturePreset.tasksAndJournal => AppStrings.featurePresetTasksHint,
};
