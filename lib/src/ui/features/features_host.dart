import 'package:niman/src/core/settings/features_introduction.dart';
import 'package:niman/src/todo/reminder_cancellation.dart';

/// What the Features screen asks of the shell around it (#1109), given down
/// through the settings the way the transcription models and the spell
/// checker are.
final class FeaturesHost {
  /// A host with the [featureReconcile] of the shell's todo controller, and
  /// the [introduction] the screen opens with.
  const new({
    this.featureReconcile,
    this.introduction = FeaturesIntroduction.none,
  });

  /// The answer to *how many reminders did that cancel*, once the
  /// reminders follow a switch just flipped: the todo controller's
  /// `featureReconcile`. The screen only reads it — the controller listens
  /// to the library's features and reconciles on its own. Null where no
  /// shell is wired (a test of the screen alone): nothing is said.
  final Future<ReminderCancellation> Function()? featureReconcile;

  /// The card above the presets: the introduction a normal open of the
  /// library asked for, or none. Leaving the screen with one up records
  /// that it was seen.
  final FeaturesIntroduction introduction;

  /// This host with [introduction] set.
  FeaturesHost withIntroduction(FeaturesIntroduction introduction) =>
      FeaturesHost(
        featureReconcile: featureReconcile,
        introduction: introduction,
      );
}
