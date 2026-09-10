/// The todo.txt format, explained in the app (plan/todo-tab.md T-TD-08).
///
/// The Todo tab writes a plain `todo.txt`, and every part of a task is a
/// piece of syntax on that line. The dialog hides most of it, but the
/// files are the source of truth and are meant to be edited anywhere —
/// so the syntax has to be discoverable without leaving the app.
///
/// Content follows the parser, not the wider todo.txt ecosystem: only
/// what Copist actually reads is documented here, and `rec:` is called
/// out precisely because it is kept but not acted on.
library;

import 'package:copist/src/ui/help_layout.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// A read-only reference for the todo.txt syntax Copist understands.
final class TodoHelpScreen extends StatelessWidget {
  /// Creates the help screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.todoHelpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          HelpParagraph(AppStrings.todoHelpIntro),
          const HelpExample('buy milk +groceries @errands due:2026-09-09'),
          HelpSection(AppStrings.todoHelpFilesTitle),
          HelpParagraph(AppStrings.todoHelpFilesBody),
          HelpSection(AppStrings.todoHelpLineTitle),
          HelpParagraph(AppStrings.todoHelpLineBody),
          const HelpExample(
            'x 2026-09-08 2026-09-01 (A) call the plumber @home',
          ),
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
          HelpRow(AppStrings.todoHelpOther, AppStrings.todoHelpOtherBody),
          HelpSection(AppStrings.todoHelpEditTitle),
          HelpParagraph(AppStrings.todoHelpEditBody),
        ],
      ),
    );
  }
}
