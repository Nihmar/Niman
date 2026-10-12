/// The notes that belong to the file or folder a delete is about (#717):
/// the **companion notes** naming it — anywhere in the library — and, for
/// a file, its **OCR sidecar** beside it.
///
/// What the delete offers to take along are exactly the notes that would
/// otherwise stay behind pointing at a path that is gone. A folder takes
/// everything inside it already, so only the companions living outside it
/// are carried: its files' sidecars, and the companions inside, go with
/// the folder itself and are not offered as a choice.
library;

import 'package:niman/src/annotations/companion_notes.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/ocr/ocr_sidecar_finder.dart';

/// Finds the notes about a path, for the delete that may carry them.
final class CarriedNotes {
  /// Creates the finder over the library's own sources.
  const new({
    required this.ops,
    required this.fields,
    required this.links,
    this.root,
    this.annotationsFolder = '',
  });

  /// The file operations the sidecar is looked up through.
  final NoteOperations ops;

  /// The frontmatter the companions declare `annotates` in.
  final FieldSource fields;

  /// Resolves those declarations the way every link is resolved.
  final LinkSource links;

  /// The library root, for the on-disk look at the annotations folder;
  /// null when there is no open library.
  final String? root;

  /// The folder companions are written to (default `Annotations`): read
  /// on disk too, so one written a moment ago — not indexed yet — is
  /// still counted (#717).
  final String annotationsFolder;

  /// The notes about [path], in path order.
  ///
  /// None of them is inside [path] when it is a folder: those go with the
  /// delete itself. The lookup goes through the index, plus the
  /// annotations folder read on disk for the companions it may not know
  /// yet.
  Future<List<String>> of(String path, {required bool isDir}) async {
    final out = <String>{};
    if (!isDir) {
      final sidecar = await findOcrSidecar(ops, path);
      if (sidecar != null) out.add(sidecar.path);
    }
    final companions = CompanionNotes(fields: fields, links: links, ops: ops);
    final fresh = switch (root) {
      final root? => await companions.freshIn(annotationsFolder, root: root),
      null => const <String, List<String>>{},
    };
    final all = {...await companions.all(), ...fresh};
    for (final entry in all.entries) {
      final names = entry.key == path || (isDir && _inside(entry.key, path));
      if (!names) continue;
      for (final note in entry.value) {
        if (note == path || (isDir && _inside(note, path))) continue;
        out.add(note);
      }
    }
    return out.toList()..sort();
  }

  /// Whether [path] sits in the folder [folder].
  static bool _inside(String path, String folder) =>
      path.startsWith('$folder/');
}
