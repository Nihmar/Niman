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
      final resolved = await _resolve(value);
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
      final text = await ops.readNote(note);
      final links = await Isolate.run(() => annotationLinksIn(text));
      for (final link in links) {
        final key = '${link.markdown}:${link.target}';
        final here = pointsHere[key] ??= await _pointsAt(link, path);
        if (!here) continue;
        out.add(
          AnnotationMark(
            note: note,
            offset: link.offset,
            place: link.place,
            title: link.title,
          ),
        );
      }
    }
    return out;
  }

  /// Whether [link] resolves to the file at [path].
  Future<bool> _pointsAt(AnnotationLink link, String path) async {
    final resolved = link.markdown
        ? await links.resolveMarkdown(link.target)
        : await links.resolveWiki(link.target);
    return resolved is ResolvedNote && resolved.note.path == path;
  }

  /// What a frontmatter [value] names: a wikilink (`[[Books/Dune.epub]]`,
  /// as Obsidian writes a link in a property), a Markdown link, or a bare
  /// path.
  Future<ResolveResult> _resolve(String value) {
    final text = value.trim();
    if (text.startsWith('[[') && text.endsWith(']]')) {
      return links.resolveWiki(
        parseWikiRef(text.substring(2, text.length - 2)).target,
      );
    }
    final markdown = _markdownLink.firstMatch(text);
    if (markdown != null) return links.resolveMarkdown(markdown[1]!);
    return links.resolveWiki(text);
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
    final written = await ops.readNote(path);
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
