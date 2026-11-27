// #1375: the list count's sheet is not modal to the note's text. The tally is
// worked out on the text read before it opens, so one applied after the note
// changed — an outside change adopted, a sync — would put that text back over
// the change.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/ui/note_edit_commands.dart';
import 'package:niman/src/ui/note_mind_map.dart';
import 'package:niman/src/ui/note_task_items.dart';

const String _note = '- a\n- b\n- c\n';

/// Commands over [surface], whose Tools button opens its sheet on [context].
NoteEditCommands _commands(
  MarkdownSurfaceController surface,
  BuildContext Function() context,
) => NoteEditCommands(
  surface: () => surface,
  focus: () {},
  context: context,
  mounted: () => true,
  canInsert: () => true,
  text: () => surface.buffer.substring(0, surface.buffer.length),
  sourceView: () => null,
  readView: () => null,
  activeFormats: ValueNotifier(const {}),
  linkType: () => LinkType.wikilink,
  notePath: () => null,
  indentWidth: () => 2,
  toolbarLayout: () => ToolbarLayout.defaults,
  pasteAsMarkdown: () => null,
  taskItems: NoteTaskItems(
    surface: () => surface,
    sourceView: () => null,
    canInsert: () => true,
    focus: () {},
  ),
  moveToTasks: () => null,
  libraryRoot: () => null,
  pickImage: () async => null,
  importImage: (_, _) async => '',
  onInserted: () {},
  mindMap: NoteMindMap(
    surface: () => surface,
    canInsert: () => true,
    context: context,
    focus: () {},
    sourceView: () => null,
  ),
);

/// Opens the count's sheet over a note, runs [whileOpen] against it, and
/// applies the tally; answers what the note says then.
Future<String> _count(
  WidgetTester tester,
  Future<void> Function(MarkdownSurfaceController surface) whileOpen,
) async {
  final surface = MarkdownSurfaceController(SourceBuffer.fromText(_note));
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  final commands = _commands(surface, () => context);
  commands.toolbarMenus()[ToolbarItem.tools]!(null);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('editor-tool-countList')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('list-tally-sheet')), findsOneWidget);
  await whileOpen(surface);
  await tester.tap(find.byKey(const Key('tally-apply')));
  await tester.pumpAndSettle();
  return surface.buffer.text;
}

void main() {
  testWidgets('the tally is applied to the note it was worked out on', (
    tester,
  ) async {
    final text = await _count(tester, (_) async {});
    expect(text, isNot(_note), reason: 'the count went into the note');
  });

  testWidgets('a note that changed while the sheet was open is left alone', (
    tester,
  ) async {
    final text = await _count(tester, (surface) async {
      surface.replaceRange(0, 0, 'NEW ');
    });
    expect(text, 'NEW $_note');
  });
}
