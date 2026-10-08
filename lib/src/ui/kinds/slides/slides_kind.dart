import 'package:flutter/widgets.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/ui/kinds/slides/slides_view.dart';
import 'package:niman/src/ui/strings.dart';

/// The text a new slides note is created with: two slides, the second
/// with a point and a speaker note, so the format shows itself.
String slidesNoteContent(String title) =>
    '---\ntype: slides\n---\n\n# $title\n\n---\n\n'
    '## ${AppStrings.slidesTemplateSecond}\n\n'
    '- ${AppStrings.slidesTemplatePoint}\n\n'
    'Note: ${AppStrings.slidesTemplateNote}\n';

/// The `slides` note kind (#534): a deck, one slide per thematic break.
final class SlidesKindGui implements NoteKindGUI {
  @override
  String get type => 'slides';

  @override
  Widget buildBody(BuildContext context, NoteKindHost host) =>
      SlidesNoteView(text: host.text, host: host);
}
