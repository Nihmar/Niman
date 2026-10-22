/// Which note an export draws as a board (#1170): the one rule, shared by
/// the page the engines print and the raster fallback.
library;

import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/kanban/board_parser.dart';
import 'package:niman/src/kanban/kanban_board.dart';

/// The board [text] is, or null for any other note: a `type: kanban` note
/// with the Kanban feature [kanban] on. With the feature off a board stays
/// the sections and tasks it is in the file.
KanbanBoard? exportedBoard(String text, {required bool kanban}) =>
    kanban && parseFrontmatter(text)?.type == 'kanban'
    ? parseKanban(text)
    : null;
