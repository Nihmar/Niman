import 'package:meta/meta.dart';
import 'package:niman/src/export/printed_todo_block.dart';

/// What a note's page is made from (#24), everything the disk and the index
/// had to say already read, so building the page reads nothing and can run
/// on any isolate.
@immutable
final class NoteHtmlSource {
  /// A note's [text], titled [title].
  const new({
    required this.text,
    required this.title,
    this.images = const <String, String>{},
    this.links = const <String, String>{},
    this.anchors = const <String, String>{},
    this.todoBlocks = const <String, PrintedTodoBlock>{},
    this.kanban = false,
  });

  /// The note, as written.
  final String text;

  /// What the page is called: the note's own title, or its file name.
  final String title;

  /// `data:` URIs for the pictures the note shows, by the target as written:
  /// an embed's (`![[photo.png]]`) and an image's (`![](img/photo.png)`). A
  /// picture that is not here is shown as the note writes it.
  final Map<String, String> images;

  /// Where a link goes on an exported page, by the target as written: a
  /// wikilink's (`[[Other note]]`) and a Markdown link's (`[x](Other.md)`).
  /// Exporting many notes fills it with the other pages; exporting one
  /// leaves it empty, and a wikilink is then highlighted text, since a page
  /// on its own has nothing to point to.
  final Map<String, String> links;

  /// The id a link into a heading with a `#` in its fragment lands on, by
  /// `ExportAnchors.keyOf`: `Issue #12` is a path or one heading, which only
  /// the target's headings tell. An empty id is a heading the target lacks.
  /// A fragment that is not here is read as a heading path.
  final Map<String, String> anchors;

  /// The lists the note's `todo` fences are, as they are at the moment of the
  /// export, by `todoBlockKey` of the fence's source (#1152). A fence that is
  /// not here is printed as the code it is on disk.
  final Map<String, PrintedTodoBlock> todoBlocks;

  ///
  /// Whether the Kanban feature is on (#1170): a `type: kanban` note is then
  /// drawn as a board. Off, it is the sections and tasks it is in any other
  /// editor.
  final bool kanban;
}
