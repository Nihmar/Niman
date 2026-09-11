import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// A button the editor's formatting toolbar can show (T-TB-01).
///
/// The enum is the whole catalogue: what a button *does* stays with the
/// editor that owns the command, and what it *looks like* and is *called*
/// lives here, so the settings screen can list the buttons without
/// knowing a thing about markdown.
///
/// [id] is persisted (see `ToolbarLayout`), so it is part of the stored
/// format: renaming one is a migration. [widgetKey] is what tests and the
/// running app identify a button by, and keeps the names the toolbar has
/// always used.
enum ToolbarItem {
  /// `**bold**`.
  bold('bold', 'toolbar-bold', Icons.format_bold),

  /// `*italic*`.
  italic('italic', 'toolbar-italic', Icons.format_italic),

  /// `~~strikethrough~~`.
  strikethrough('strikethrough', 'toolbar-strike', Icons.strikethrough_s),

  /// `<sup>superscript</sup>`.
  superscript('superscript', 'toolbar-sup', Icons.superscript),

  /// `<u>underline</u>`.
  underline('underline', 'toolbar-underline', Icons.format_underline),

  /// A link in the configured format.
  link('link', 'toolbar-link', Icons.link),

  /// A fenced code block.
  code('code', 'toolbar-code', Icons.code),

  /// Pick an image, copy it into the library, link it.
  image('image', 'insert-image', Icons.add_photo_alternate_outlined),

  /// The heading-level dialog.
  heading('heading', 'toolbar-heading', Icons.title),

  /// A bulleted list.
  list('list', 'toolbar-list', Icons.format_list_bulleted),

  /// A numbered list.
  orderedList(
    'ordered_list',
    'toolbar-ordered-list',
    Icons.format_list_numbered,
  ),

  /// A block quote.
  quote('quote', 'toolbar-quote', Icons.format_quote),

  /// Outdent the selected lines.
  outdent('outdent', 'toolbar-outdent', Icons.format_indent_decrease),

  /// Indent the selected lines.
  indent('indent', 'toolbar-indent', Icons.format_indent_increase);

  new(this.id, this._key, this.icon);

  /// The persisted id.
  final String id;

  final String _key;

  /// The button's icon, in the toolbar and in the settings list.
  final IconData icon;

  /// The widget key the button carries.
  Key get widgetKey => Key(_key);

  /// The button's name: its tooltip in the editor, its row title in the
  /// settings.
  ///
  /// A getter rather than a constructor field so the label can follow the
  /// app language without the enum having to be rebuilt.
  String get label => switch (this) {
    ToolbarItem.bold => AppStrings.toolbarBold,
    ToolbarItem.italic => AppStrings.toolbarItalic,
    ToolbarItem.strikethrough => AppStrings.toolbarStrikethrough,
    ToolbarItem.superscript => AppStrings.toolbarSuperscript,
    ToolbarItem.underline => AppStrings.toolbarUnderline,
    ToolbarItem.link => AppStrings.toolbarLink,
    ToolbarItem.code => AppStrings.toolbarCode,
    ToolbarItem.image => AppStrings.toolbarImage,
    ToolbarItem.heading => AppStrings.toolbarHeading,
    ToolbarItem.list => AppStrings.toolbarList,
    ToolbarItem.orderedList => AppStrings.toolbarOrderedList,
    ToolbarItem.quote => AppStrings.toolbarQuote,
    ToolbarItem.outdent => AppStrings.toolbarOutdent,
    ToolbarItem.indent => AppStrings.toolbarIndent,
  };

  /// The item with this [id], or null when the build does not know it.
  static ToolbarItem? fromId(String id) {
    for (final item in ToolbarItem.values) {
      if (item.id == id) return item;
    }
    return null;
  }
}
