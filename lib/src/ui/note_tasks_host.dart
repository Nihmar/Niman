/// What a note's task list needs of the app (#1152): the tasks that link the
/// note, and the ways to tick one, edit one and add one.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/links/resolver.dart' show ResolveResult;
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/task_links.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/todo_link_host.dart';
import 'package:niman/src/ui/todo_list_actions.dart';
import 'package:niman/src/ui/todo_task_edit.dart';

/// The shell's tasks as a note's views use them: the three places *Tasks for
/// this note* lives in (under the note, the side panel, the phone's sheet)
/// share one.
///
/// Reading is [map]; a tick and an edit go through the same [TodoController]
/// and the same dialog as the Todo tab's rows, and adding hands the text to
/// the shell's add flow, which owns the dialog's reminder health and the error
/// guard.
final class NoteTasksHost {
  /// The tasks of [links], ticked and edited through [controller]; [addTask]
  /// is the shell's Add task with the text written in.
  const new({
    required this.links,
    required this.controller,
    required this.addTask,
    this.reminders,
    this.clock,
  });

  /// The links of the tasks, and how to follow one.
  final TodoLinkHost links;

  /// The tasks' files.
  final TodoController controller;

  /// Opens the task dialog on a new task whose description is the text.
  final Future<void> Function(String text) addTask;

  /// The reminder service, for the dialog's health line.
  final ReminderService? reminders;

  /// The wall-clock source for "today" (defaults to now).
  final DateTime Function()? clock;

  /// The resolved links of the tasks: what the views listen to.
  TaskLinkMap get map => links.map;

  /// The day the due badges are told against.
  DateTime get today => todoDayOf(clock);

  /// The tasks as the controller holds them, or null before they are read.
  TodoSnapshot? get snapshot => controller.snapshot;

  /// Ticks an open task, or reopens a [done] one.
  Future<void> toggle(TodoEntry entry, {required bool done}) =>
      done ? controller.uncheck(entry) : controller.check(entry);

  /// Opens the task dialog on [entry], and writes what it returns.
  Future<void> edit(
    BuildContext context,
    TodoEntry entry, {
    required bool done,
  }) => editTodoTask(
    context,
    controller: controller,
    entry: entry,
    done: done,
    today: today,
    links: links,
    reminders: reminders,
  );

  /// Opens the task dialog on a new task that links the note at
  /// library-relative [notePath]: its description is `[[Note]]`, the shortest
  /// form that names this note alone (as the `[[` completion writes it), with
  /// [selection] — the text selected in the editor — before it.
  ///
  /// The dialog opens with the caret at the start, so a link alone is
  /// written after a space: what is typed there lands before it as its own
  /// word (`Call [[Repairs]]`, never `Call[[Repairs]]`), and the dialog's
  /// trim takes the space off when nothing is typed.
  Future<void> add(String notePath, {String selection = ''}) async {
    final link = await linkTo(notePath);
    final lead = oneLine(selection);
    await addTask(lead.isEmpty ? ' $link' : '$lead $link');
  }

  /// What the wikilink target [target], written in the note at library-relative
  /// [from], names: a `todo` block's `link: [[Note]]`.
  Future<ResolveResult?> resolveNote(String target, {required String from}) =>
      links.resolveWiki(target, from: from);

  /// The wikilink that names the note at [notePath] alone.
  Future<String> linkTo(String notePath) async {
    final suggester = links.suggester?.call();
    final target = suggester == null
        ? _withoutExtension(notePath)
        : await suggester.targetOf(notePath);
    return '[[$target]]';
  }

  /// [text] on one line: its runs of white space collapsed to one space, the
  /// ends trimmed (a task is one line of `todo.txt`).
  static String oneLine(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _withoutExtension(String path) =>
      path.toLowerCase().endsWith('.md')
      ? path.substring(0, path.length - 3)
      : path;
}
