/// The editor's extra tools (#136).
///
/// One toolbar button opens a sheet listing these, rather than one
/// button per feature (user, 2026-09-18): the formatting toolbar is a
/// row of formats, and a document operation that happens to live near it
/// should not have to argue for a slot. Adding the next tool is a value
/// here, a label, and an arm in the owner's dispatch — the toolbar keeps
/// the one persisted id it already has.
///
/// The enum is the whole catalogue. What a tool *does* stays with the
/// editor that owns the command, because each one has to work on both
/// writing surfaces; what it *looks like* and is *called* lives here.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// A tool the editor's Tools sheet can offer.
enum EditorTool {
  /// Count the values of a list into a checklist of totals.
  countList(Icons.functions);

  new(this.icon);

  /// The tool's icon in the sheet.
  final IconData icon;

  /// The tool's name.
  ///
  /// A getter rather than a constructor field, as `ToolbarItem.label`
  /// is, so the label follows the app language without the enum having
  /// to be rebuilt.
  String get label => switch (this) {
    EditorTool.countList => AppStrings.toolCountListTitle,
  };

  /// What the tool does, under its name.
  String get description => switch (this) {
    EditorTool.countList => AppStrings.toolCountListSubtitle,
  };

  /// Why the tool cannot run on this note right now.
  ///
  /// The sheet shows the row greyed with this under it rather than
  /// dropping it: a tool that is sometimes missing is a tool nobody
  /// learns is there (`docs/dev/conventions.md`, the keep-its-place
  /// rule).
  String get unavailableReason => switch (this) {
    EditorTool.countList => AppStrings.toolCountListNeedsList,
  };
}
