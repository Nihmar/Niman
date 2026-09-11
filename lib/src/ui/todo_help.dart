/// The todo.txt format, explained in the app (T-TD-08).
///
/// The Todo tab writes a plain `todo.txt`, and every part of a task is a
/// piece of syntax on that line. The dialog hides most of it, but the
/// files are the source of truth and are meant to be edited anywhere —
/// so the syntax has to be discoverable without leaving the app.
///
/// Content follows the parser, not the wider todo.txt ecosystem: only
/// what Niman actually reads is documented here, and `rec:` is called
/// out precisely because it is kept but not acted on.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/help_layout.dart';
import 'package:niman/src/ui/strings.dart';

/// A read-only reference for the todo.txt syntax Niman understands.
final class TodoHelpScreen extends StatelessWidget {
  /// Creates the help screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.todoHelpTitle)),
      body: const TodoHelpBody(),
    );
  }
}

/// The reference's content alone, without the screen chrome: the desktop
/// opens it in a dialog over the tab, so the rail and the list stay on
/// screen (T-PP-22).
final class TodoHelpBody extends StatelessWidget {
  /// Creates the reference body.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        HelpParagraph(AppStrings.todoHelpIntro),
        const HelpExample('buy milk +groceries @errands due:2026-09-09'),
        HelpSection(AppStrings.todoHelpFilesTitle),
        HelpParagraph(AppStrings.todoHelpFilesBody),
        HelpSection(AppStrings.todoHelpLineTitle),
        HelpParagraph(AppStrings.todoHelpLineBody),
        const HelpExample('x 2026-09-08 2026-09-01 (A) call the plumber @home'),
        HelpRow(AppStrings.todoHelpDone, AppStrings.todoHelpDoneBody),
        HelpRow(AppStrings.todoHelpPriority, AppStrings.todoHelpPriorityBody),
        HelpRow(AppStrings.todoHelpDates, AppStrings.todoHelpDatesBody),
        HelpSection(AppStrings.todoHelpTokensTitle),
        HelpParagraph(AppStrings.todoHelpTokensBody),
        HelpRow(AppStrings.todoHelpProject, AppStrings.todoHelpProjectBody),
        HelpRow(AppStrings.todoHelpContext, AppStrings.todoHelpContextBody),
        HelpRow(AppStrings.todoHelpHashtag, AppStrings.todoHelpHashtagBody),
        HelpSection(AppStrings.todoHelpTagsTitle),
        HelpParagraph(AppStrings.todoHelpTagsBody),
        HelpRow(AppStrings.todoHelpDue, AppStrings.todoHelpDueBody),
        HelpRow(AppStrings.todoHelpRem, AppStrings.todoHelpRemBody),
        // Android fires with the app closed; the desktops cannot, so say so
        // where the syntax is explained rather than letting it be found out.
        if (Platform.isLinux || Platform.isWindows)
          HelpParagraph(AppStrings.todoHelpRemDesktop),
        HelpRow(AppStrings.todoHelpOther, AppStrings.todoHelpOtherBody),
        HelpSection(AppStrings.todoHelpEditTitle),
        HelpParagraph(AppStrings.todoHelpEditBody),
      ],
    );
  }
}
