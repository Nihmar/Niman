// #1166: the `kanban` note kind: its template is a board of three empty
// columns, in the language of the app, and the kind is registered behind
// its feature.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/kanban/board_parser.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_kind.dart';
import 'package:niman/src/ui/strings.dart';

void main() {
  test('a new board is type: kanban over three empty columns', () {
    final text = kanbanNoteContent();
    expect(parseFrontmatter(text)?.type, 'kanban');
    final board = parseKanban(text);
    expect(
      [for (final column in board.columns) column.name],
      [
        AppStrings.kanbanColumnTodo,
        AppStrings.kanbanColumnDoing,
        AppStrings.kanbanColumnDone,
      ],
    );
    for (final column in board.columns) {
      expect(column.cards, isEmpty, reason: column.name);
    }
    expect(board.hasSettings, isFalse);
  });

  test('the kind is registered, and gone while its feature is off', () {
    const on = Features();
    expect(NoteKinds.forType('kanban', on)?.type, 'kanban');
    expect(featureOfKind('kanban'), LibraryFeature.kindKanban);
    final off = on.withSwitch(LibraryFeature.kindKanban, on: false);
    expect(NoteKinds.forType('kanban', off), isNull);
    // The others stay as they were.
    expect(NoteKinds.forType('slides', off), isNotNull);
  });
}
