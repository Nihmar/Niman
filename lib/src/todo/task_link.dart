/// One link in a task, read and resolved (#1152).
library;

import 'package:meta/meta.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/link_path.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/todo/todo_file_names.dart';

/// Which of the two task files a line is in.
enum TaskFile {
  /// `todo.txt`: the open tasks.
  todo(todoFileName),

  /// `done.txt`: the completed ones.
  done(doneFileName);

  new(this.path);

  /// The file's library-relative path: the note a link in it is written in,
  /// for a `..` to walk from. Both sit at the library root.
  final String path;
}

/// A link in a task's description, with what it resolved to.
///
/// Only a link that can name a note is one: a wikilink with a target, or a
/// Markdown link to a file. A URL, a `#anchor` and `[[#Heading]]` are not
/// asked of the resolver and are not in the task link map.
@immutable
final class TaskLink {
  /// A [link] parsed from a task's description, resolved to [result].
  const new({required this.link, required this.result});

  /// The link as parsed: [ParsedLink.start]..[ParsedLink.end] are offsets
  /// into the task's `TodoTask.description`.
  final ParsedLink link;

  /// What the resolver made of it.
  final ResolveResult result;

  /// Whether it was written as an embed (`![[…]]`, `![…](…)`): carried by
  /// a move, but shown by nothing as a link.
  bool get embed => switch (link) {
    final WikiLink w => w.embed,
    final MarkdownLink m => m.embed,
  };

  /// The target as written: the wikilink's target, the Markdown link's href.
  String get target => switch (link) {
    final WikiLink w => w.ref.target,
    final MarkdownLink m => m.href,
  };

  /// The anchor after the `#`, as written: a heading path (`Boiler`) or a
  /// block id with its caret (`^b7`); null for a link to the note itself.
  String? get anchor => switch (link) {
    final WikiLink w => w.ref.fragment,
    final MarkdownLink m => LinkPaths.markdownTarget(m.href)?.fragment,
  };

  /// The text the writer gave the link to show: a wikilink's alias, a
  /// Markdown link's text; null when there is none.
  String? get alias => switch (link) {
    final WikiLink w => w.ref.alias,
    final MarkdownLink m => m.text.isEmpty ? null : m.text,
  };

  /// The note it resolved to, or null for a link that is dead or ambiguous.
  Note? get note => switch (result) {
    final ResolvedNote r => r.note,
    _ => null,
  };

  /// The library-relative path of [note], or null.
  String? get notePath => note?.path;

  /// Whether it names no note: a dead link.
  bool get isDead => result is UnresolvedNote;

  /// Whether the target fits several notes and names none of them.
  bool get isAmbiguous => result is AmbiguousNote;

  /// The notes an ambiguous link could name (shortest path first); empty
  /// for any other.
  List<Note> get candidates => switch (result) {
    final AmbiguousNote a => a.candidates,
    _ => const <Note>[],
  };
}
