/// *Look up* in the menus of the surfaces that select text (#1383): one
/// entry, built the same way for a book, a PDF and a scan's text.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/markdown/render/read_selection.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/dictionary_lookup_flow.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/strings.dart';

/// The key *Look up* runs on while a selection exists: `Ctrl+D`, `⌘D` on a
/// Mac. It is the readers' own, like the page keys, not an app command: it
/// needs the selection of the pane that has the keyboard. Null when the
/// reader has bound a command of the app to it, which keeps it.
SingleActivator? lookUpShortcut() {
  final keys = hostKeys(
    const SingleActivator(LogicalKeyboardKey.keyD, control: true),
  );
  return AppKeyMap.current.value.commandsOn(keys).isEmpty ? keys : null;
}

/// *Look up* as an entry of a read selection's menu, with its key.
///
/// [surface] and [language] say what the language comes from (a book's
/// `dc:language`, a PDF's choice); [annotate] gives, for the selection, what
/// annotates its passage with a definition, or null where it cannot;
/// [onLanguage] hears the language chosen in the panel.
ReadSelectionAction lookUpReadAction(
  BuildContext context, {
  required DictionarySurface surface,
  String? language,
  DictionaryAnnotate? Function(ReadSelection selection)? annotate,
  ValueChanged<String>? onLanguage,
}) => ReadSelectionAction(
  label: AppStrings.lookUpAction,
  shortcut: lookUpShortcut(),
  onPressed: (selection) => unawaited(
    showDictionaryLookup(
      context,
      selection: selection.text,
      surface: surface,
      language: language,
      anchor: selection.anchor,
      annotate: annotate?.call(selection),
      onLanguage: onLanguage,
    ),
  ),
);
