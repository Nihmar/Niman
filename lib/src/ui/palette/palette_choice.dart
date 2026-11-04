import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/palette/palette_setting.dart';

/// What was picked.
sealed class PaletteChoice {
  const new();
}

/// A command, to run.
final class PaletteCommandChoice extends PaletteChoice {
  /// Picked [command].
  const new(this.command);

  /// The command.
  final AppCommand command;
}

/// A note, to open.
final class PaletteNoteChoice extends PaletteChoice {
  /// Picked the note at library-relative [path].
  const new(this.path);

  /// The note.
  final String path;
}

/// A settings row, to open the settings at (#229).
final class PaletteSettingChoice extends PaletteChoice {
  /// Picked [setting].
  const new(this.setting);

  /// Which row.
  final PaletteSetting setting;
}

/// A Home action, to run (#535).
final class PaletteActionChoice extends PaletteChoice {
  /// Picked [action].
  const new(this.action);

  /// The action.
  final HomeAction action;
}

/// The link of the quiet line: Settings → Features (#1109).
final class PaletteFeaturesChoice extends PaletteChoice {
  /// Picked the link to Features.
  const new();
}
