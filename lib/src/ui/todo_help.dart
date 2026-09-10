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

import 'dart:io';

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
        _Paragraph(AppStrings.todoHelpIntro),
        const _Example('buy milk +groceries @errands due:2026-09-09'),
        _Section(AppStrings.todoHelpFilesTitle),
        _Paragraph(AppStrings.todoHelpFilesBody),
        _Section(AppStrings.todoHelpLineTitle),
        _Paragraph(AppStrings.todoHelpLineBody),
        const _Example('x 2026-09-08 2026-09-01 (A) call the plumber @home'),
        _Row(AppStrings.todoHelpDone, AppStrings.todoHelpDoneBody),
        _Row(AppStrings.todoHelpPriority, AppStrings.todoHelpPriorityBody),
        _Row(AppStrings.todoHelpDates, AppStrings.todoHelpDatesBody),
        _Section(AppStrings.todoHelpTokensTitle),
        _Paragraph(AppStrings.todoHelpTokensBody),
        _Row(AppStrings.todoHelpProject, AppStrings.todoHelpProjectBody),
        _Row(AppStrings.todoHelpContext, AppStrings.todoHelpContextBody),
        _Row(AppStrings.todoHelpHashtag, AppStrings.todoHelpHashtagBody),
        _Section(AppStrings.todoHelpTagsTitle),
        _Paragraph(AppStrings.todoHelpTagsBody),
        _Row(AppStrings.todoHelpDue, AppStrings.todoHelpDueBody),
        _Row(AppStrings.todoHelpRem, AppStrings.todoHelpRemBody),
        // Android fires with the app closed; the desktops cannot, so say so
        // where the syntax is explained rather than letting it be found out.
        if (Platform.isLinux || Platform.isWindows)
          _Paragraph(AppStrings.todoHelpRemDesktop),
        _Row(AppStrings.todoHelpOther, AppStrings.todoHelpOtherBody),
        _Section(AppStrings.todoHelpEditTitle),
        _Paragraph(AppStrings.todoHelpEditBody),
      ],
    );
  }
}

/// A section heading.
final class _Section extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// A block of prose.
final class _Paragraph extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

/// A monospaced sample line, scrollable so a long one never clips.
final class _Example extends StatelessWidget {
  const new(this.line);

  final String line;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          line,
          style: TextStyle(fontFamily: 'monospace', color: scheme.onSurface),
        ),
      ),
    );
  }
}

/// One piece of syntax and what it means.
final class _Row extends StatelessWidget {
  const new(this.syntax, this.meaning);

  final String syntax;
  final String meaning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            syntax,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            meaning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
