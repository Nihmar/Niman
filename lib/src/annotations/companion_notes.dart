/// The notes annotating a PDF or a book (#284): its **companion notes**.
///
/// A companion is a plain note that names its file in its frontmatter,
///
/// ```markdown
/// ---
/// annotates: "[[Books/Dune.epub]]"
/// ---
/// ```
///
/// the link, not the note's name or folder, saying what it annotates: it
/// can live anywhere, be renamed, and a file can have more than one. So
/// nothing about annotations is kept anywhere but in notes; the index only
/// answers which notes declare `annotates`, and their links are resolved
/// as any link is.
///
/// Annotating a file appends to its first companion, in path order, and
/// makes one when it has none: in the library's annotations folder, named
/// after the file — `Annotations/Dune - Annotation.md`.
library;

import 'dart:isolate';

import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/markdown/note_load.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';
import 'package:niman/src/markdown/text_escape.dart';
import 'package:path/path.dart' as p;

/// Where an annotation was written: the note, and the offset its text
/// starts at, for the note to open there.
typedef WrittenAnnotation = ({String path, int offset});

/// The companion notes of the open library's files.
final class CompanionNotes {
  /// Companions found through [fields] and [links], written through
  /// [ops].
  const new({required this.fields, required this.links, required this.ops});

  /// The frontmatter key naming the annotated file.
  static const String key = 'annotates';

  /// Answers which notes declare [key], and what.
  final FieldSource fields;

  /// Resolves what they declare.
  final LinkSource links;

  /// Writes the notes.
  final NoteOperations ops;

  /// The companion notes of the file at library-relative [path], in path
  /// order.
  Future<List<String>> of(String path) async {
    final out = <String>[];
    for (final (:note, :value) in await fields.fieldValues(key)) {
      if (out.contains(note.path)) continue;
      final resolved = await _resolve(value, from: note.path);
      if (resolved is ResolvedNote && resolved.note.path == path) {
        out.add(note.path);
      }
    }
    return out;
  }

  /// Where the file at library-relative [path] was annotated (#285): every
  /// link of its companions to a place of it, in the companions' order and
  /// then their text's.
  Future<List<AnnotationMark>> marksOf(String path) async {
    final out = <AnnotationMark>[];
    final pointsHere = <String, bool>{};
    for (final note in await of(path)) {
      // The note as the editor opens it, which is the text its offsets are
      // for: a CRLF companion read as it is on disk put every mark one
      // character late per `\r` before it (#374).
      final text = normalizedLineEndings(await ops.readNote(note));
      final links = await Isolate.run(() => annotationLinksIn(text));
      for (final link in links) {
        // A path is read from the note it is written in, so the answer is
        // that note's own.
        final key = '$note:${link.markdown}:${link.target}';
        final here = pointsHere[key] ??= await _pointsAt(
          link,
          path,
          from: note,
        );
        if (!here) continue;
        out.add(
          AnnotationMark(
            note: note,
            offset: link.offset,
            place: link.place,
            title: link.title,
            highlight: link.highlight,
            end: link.end,
            quote: link.quote,
            label: link.label,
          ),
        );
      }
    }
    return out;
  }

  /// Takes the highlight [mark] out of its note (#626): its quote, and the
  /// blank line that kept it apart. Throws a [StateError] when the note no
  /// longer has it where [mark] says — it was edited since.
  Future<void> removeHighlight(AnnotationMark mark) =>
      _rewrite(mark, (text, start, end) {
        var before = text.substring(0, start);
        var after = text.substring(end);
        if (after.isEmpty) {
          before = before.replaceFirst(RegExp(r'\n+$'), '\n');
        } else if (before.isEmpty || before.endsWith('\n\n')) {
          after = after.replaceFirst(RegExp(r'^\n+'), '');
        }
        return '$before$after';
      });

  /// Turns the highlight [mark] into an annotation saying [comment], where
  /// it is: its quote gains the heading an annotation has, named [label],
  /// and the comment under it, and its link loses its colour. Throws a
  /// [StateError] when the note no longer has it where [mark] says.
  Future<void> annotateHighlight(
    AnnotationMark mark, {
    required String label,
    required String comment,
  }) => _rewrite(mark, (text, start, end) {
    final quote = text
        .substring(start, end)
        .replaceFirstMapped(
          _highlightPair(mark.highlight!),
          // The pair goes with one `&` of the two around it; first in the
          // fragment, it leaves the `#` only when more follows.
          (m) => m[1] == '#' && m[2]!.isNotEmpty ? '#' : m[2]!,
        );
    final said = comment.trim();
    final heading = escapeMarkdownText(label.replaceAll(RegExp(r'\s+'), ' '));
    return '${text.substring(0, start)}## ${heading.trim()}\n\n$quote'
        '${said.isEmpty ? '' : '\n$said\n'}${text.substring(end)}';
  });

  /// Gives the highlight [mark] the colour [colour]. Throws a [StateError]
  /// when the note no longer has it where [mark] says.
  Future<void> recolour(AnnotationMark mark, HighlightColour colour) =>
      _rewrite(
        mark,
        (text, start, end) =>
            text.substring(0, start) +
            text
                .substring(start, end)
                .replaceFirstMapped(
                  _highlightPair(mark.highlight!),
                  (m) => '${m[1]}highlight=${colour.id}${m[2]}',
                ) +
            text.substring(end),
      );

  /// Rewrites the note of the highlight [mark] with [change], given its
  /// text and where the highlight is in it; the note's line endings are
  /// kept.
  Future<void> _rewrite(
    AnnotationMark mark,
    String Function(String text, int start, int end) change,
  ) async {
    final end = mark.end;
    if (!mark.isHighlight || end == null) {
      throw StateError('$mark is not a highlight');
    }
    final raw = await ops.readNote(mark.note);
    final text = normalizedLineEndings(raw);
    final links = await Isolate.run(() => annotationLinksIn(text));
    final still = links.any(
      (link) =>
          link.highlight == mark.highlight &&
          link.offset == mark.offset &&
          link.end == end &&
          link.place == mark.place,
    );
    if (!still) throw StateError('${mark.note} changed under $mark');
    final changed = change(text, mark.offset, end);
    await ops.saveNote(
      mark.note,
      raw.contains('\r\n') ? changed.replaceAll('\n', '\r\n') : changed,
    );
  }

  /// Whether [link], written in the note at [from], resolves to the file at
  /// [path].
  Future<bool> _pointsAt(
    AnnotationLink link,
    String path, {
    required String from,
  }) async {
    final resolved = link.markdown
        ? await links.resolveMarkdown(link.target, from: from)
        : await links.resolveWiki(link.target, from: from);
    return resolved is ResolvedNote && resolved.note.path == path;
  }

  /// What a frontmatter [value] of the note at [from] names: a wikilink
  /// (`[[Books/Dune.epub]]`, as Obsidian writes a link in a property), a
  /// Markdown link, or a bare path.
  Future<ResolveResult> _resolve(String value, {required String from}) {
    final text = value.trim();
    if (text.startsWith('[[') && text.endsWith(']]')) {
      return links.resolveWiki(
        parseWikiRef(text.substring(2, text.length - 2)).target,
        from: from,
      );
    }
    final markdown = _markdownLink.firstMatch(text);
    if (markdown != null) {
      return links.resolveMarkdown(markdown[1]!, from: from);
    }
    return links.resolveWiki(text, from: from);
  }

  static final RegExp _markdownLink = RegExp(r'^\[[^\]]*\]\(([^)]+)\)$');

  /// Writes [annotation] into the file's first companion, or into a new
  /// one in [folder] named after the file and [suffix]; links written as
  /// [linkType] says.
  Future<WrittenAnnotation> write(
    Annotation annotation, {
    required String folder,
    required String suffix,
    required LinkType linkType,
  }) async {
    final text = annotation.toMarkdown(linkType: linkType);
    final companions = await of(annotation.path);
    final String path;
    if (companions.isNotEmpty) {
      path = companions.first;
      await ops.appendToNote(path, text);
    } else {
      if (folder.isNotEmpty) await ops.ensureFolder(folder);
      final note = await ops.createNote(
        parentPath: folder,
        name: '${p.url.basenameWithoutExtension(annotation.path)} - $suffix',
        content: '${companionHead(annotation.path)}\n$text',
      );
      path = note.path;
    }
    // The same text the editor opens the note with, so the offset is where
    // its caret goes: the raw file's would be one character late per `\r`
    // before the annotation when the companion is CRLF (#374).
    final written = normalizedLineEndings(await ops.readNote(path));
    final at = written.lastIndexOf(text);
    return (path: path, offset: at == -1 ? written.length : at);
  }

  /// The frontmatter of a new companion of the file at library-relative
  /// [path].
  static String companionHead(String path) {
    final link = '[[$path]]'.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '---\n$key: "$link"\n---\n';
  }
}

/// The `highlight=` pair of [colour] in a link's fragment, with the `#` or
/// `&` before it and the `&` after it, if any: in any case and anywhere in
/// the fragment, as `annotationLinksIn` reads it.
RegExp _highlightPair(HighlightColour colour) =>
    RegExp('([#&])highlight=${colour.id}\\b(&?)', caseSensitive: false);
