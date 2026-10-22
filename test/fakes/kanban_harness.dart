// A note window and a body harness the kanban board tests (#1167, #1168) share.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_kind.dart';

/// A note window over a text the board edits; it rebuilds the board as the
/// shell does.
final class KanbanTestHost implements NoteKindHost {
  /// A window over [value].
  new(this.value);

  /// The note's text now.
  String value;

  /// Every text the board wrote, in order.
  final List<String> edits = [];

  /// Called after an edit, to rebuild the body.
  VoidCallback? changed;

  @override
  String get text => value;

  @override
  void applyEdit(String newText) {
    edits.add(newText);
    value = newText;
    changed?.call();
  }

  @override
  String? get libraryRoot => null;

  @override
  String get notePath => 'board.md';

  @override
  String get attachmentsFolder => '';

  @override
  LinkType get linkType => LinkType.wikilink;

  @override
  Future<String?> resolveEmbed(String target) async => null;

  @override
  void openLink(BuildContext context, String href) {}

  @override
  void openWikiLink(BuildContext context, String inner) {}

  @override
  VoidCallback? get showMarkdown => null;
}

final class _Harness extends StatefulWidget {
  const new(this.host);

  final KanbanTestHost host;

  @override
  State<_Harness> createState() => _HarnessState();
}

final class _HarnessState extends State<_Harness> {
  @override
  void initState() {
    super.initState();
    widget.host.changed = () => setState(() {});
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => KanbanKindGui().buildBody(context, widget.host),
      ),
    ),
  );
}

/// Shows the board of [text] in a window of [size].
Future<KanbanTestHost> showKanbanBoard(
  WidgetTester tester,
  String text, {
  Size size = const Size(1400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final host = KanbanTestHost(text);
  await tester.pumpWidget(_Harness(host));
  await tester.pumpAndSettle();
  return host;
}
