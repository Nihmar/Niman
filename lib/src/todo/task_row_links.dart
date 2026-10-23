/// What a task row draws of the links in its task's text (#1152): a chip per
/// link, and the text with the links taken out of it.
library;

import 'package:flutter/foundation.dart';
import 'package:niman/src/links/link_query.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/preview_link.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/task_link.dart';
import 'package:niman/src/todo/task_link_label.dart';
import 'package:niman/src/todo/task_links.dart';

/// How far a link is known to name a note.
enum TaskRowLinkState {
  /// It names a note.
  live,

  /// Not asked of the resolver yet (a task just edited): drawn as a live one,
  /// from the words alone, until the answer comes.
  pending,

  /// Its target fits several notes: drawn live, and a tap offers them.
  ambiguous,

  /// It names no note.
  dead,
}

/// One link of a task, as a row draws it.
@immutable
final class TaskRowLink {
  /// The chip of [link], told [state] and shown as [label].
  const new({
    required this.link,
    required this.state,
    required this.label,
    required this.preview,
  });

  /// The link and what is known of it.
  final TaskLink link;

  /// How far it is known to name a note.
  final TaskRowLinkState state;

  /// The chip's words: the alias when one is written; else the note's name,
  /// and the heading or block after it (`Repairs › Boiler`, `Repairs › ^b7`).
  final String label;

  /// The link as the preview is asked about it.
  final PreviewLink preview;

  /// The library-relative path of the note, when the link names one.
  String? get notePath => link.notePath;
}

/// The links of one task as a row draws them.
@immutable
final class TaskRowLinks {
  /// [chips] drawn, and the [text] of the task without them.
  const new({required this.chips, required this.text});

  /// The links, in the order they are written.
  final List<TaskRowLink> chips;

  /// The task's display text (`taskDisplayText`) with the links that are
  /// chips taken out of it: no link is drawn twice.
  final String text;
}

/// The links of [task] for a row, from what [map] has resolved of them.
///
/// A task the map has not answered for yet (its words are new) is read here,
/// from its text: its links are chips from the first frame, never raw
/// `[[…]]`, and the answer changes the chip's state, not its size.
TaskRowLinks taskRowLinksOf(TodoTask task, {TaskLinkMap? map}) {
  final description = task.description;
  if (!description.contains('[')) {
    return TaskRowLinks(chips: const [], text: taskDisplayText(description));
  }
  final known = map?.linksOf(task) ?? const <TaskLink>[];
  final pending = known.isEmpty;
  final links = pending ? _read(description) : known;
  if (links.isEmpty) {
    return TaskRowLinks(chips: const [], text: taskDisplayText(description));
  }
  var text = description;
  for (final link in links.reversed) {
    text = text.replaceRange(link.link.start, link.link.end, ' ');
  }
  return TaskRowLinks(
    chips: [for (final link in links) _chip(link, description, pending)],
    text: taskDisplayText(text),
  );
}

/// The links a reader sees in [description], not resolved yet.
List<TaskLink> _read(String description) {
  return <TaskLink>[
    for (final link in parseLinks(description, includeEmbeds: true))
      if (linkTargetOf(link) != null)
        if (!_embed(link))
          TaskLink(
            link: link,
            result: UnresolvedNote(target: linkTargetOf(link)!),
          ),
  ];
}

bool _embed(ParsedLink link) => switch (link) {
  final WikiLink w => w.embed,
  final MarkdownLink m => m.embed,
};

TaskRowLink _chip(TaskLink link, String description, bool pending) {
  final state = switch (link.result) {
    ResolvedNote() => TaskRowLinkState.live,
    AmbiguousNote() => TaskRowLinkState.ambiguous,
    UnresolvedNote() when pending => TaskRowLinkState.pending,
    _ => TaskRowLinkState.dead,
  };
  final name = switch (state) {
    TaskRowLinkState.live => noteNameOf(link.notePath!),
    TaskRowLinkState.dead => writtenNoteOf(link),
    _ => noteNameOf(writtenNoteOf(link)),
  };
  final preview = switch (link.link) {
    final WikiLink w => PreviewLink.wiki(
      description.substring(w.start + 2, w.end - 2),
    ),
    final MarkdownLink m => PreviewLink.markdown(m.href),
  };
  return TaskRowLink(
    link: link,
    state: state,
    label: taskLinkLabel(link, name),
    preview: preview,
  );
}
