// #846: hovering a link in the read view shows what it points at — a card at
// the pointer, the note rendered, fixed in size and scrollable, scrolled to
// the heading or block the link names — and closes without navigating.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart' show isTest;
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/link_preview/link_preview_card.dart';
import 'package:niman/src/ui/link_preview/link_preview_controller.dart';
import 'package:niman/src/ui/link_preview/link_preview_host.dart';

import '../fakes/fake_link_source.dart';

const String _page = 'See [[Newton]] and [[Gone]] and [x](Optics.md#Light).';

/// What the page reads as: the links shown by their text.
const String _shown = 'See Newton and Gone and x.';

final Finder _card = find.byKey(const Key('link-preview-card'));

/// A widget test that leaves the page and closes the card when it ends: the
/// pointer's exit as the tree goes is the controller's to hear, and owes no
/// timer to the test.
@isTest
void _cardTest(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

void main() {
  late FakeLinkSource links;
  late LinkPreviewController controller;
  late ScrollController scroll;
  String? Function(String path)? unsavedText;
  var enabled = true;

  setUp(() {
    enabled = true;
    unsavedText = null;
    links = FakeLinkSource(notes: ['Newton.md', 'Optics.md', 'Here.md']);
    links.previews['Newton.md'] =
        '# Newton\n\nGravity, and the laws of motion.';
    final filler = List.generate(80, (i) => 'Filler paragraph $i.\n');
    links.previews['Optics.md'] =
        '# Optics\n\n${filler.join('\n')}'
        '\n## Light\n\nLight travels at a finite speed.\n';
    controller = LinkPreviewController(
      source: () => links,
      notePath: () => 'Here.md',
      enabled: () => enabled,
      unsavedText: (path) => unsavedText?.call(path),
    );
    scroll = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(scroll.dispose);
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(800, 600),
    String text = _page,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _Page(controller: controller, scroll: scroll, text: text),
        ),
      ),
    );
    await tester.pump();
  }

  /// The pointer, over the text [word] of the page.
  Future<TestGesture> hover(WidgetTester tester, String word) async {
    final paragraph = tester.renderObject<RenderParagraph>(
      find.textContaining('See ', findRichText: true).first,
    );
    final offset = _shown.indexOf(word);
    final at = paragraph.localToGlobal(
      paragraph.getOffsetForCaret(TextPosition(offset: offset), Rect.zero) +
          const Offset(4, 8),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(700, 580));
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(at);
    return gesture;
  }

  Future<void> settleHover(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    await tester.pump();
  }

  _cardTest('a pointer resting on a link opens the card, not before', (
    tester,
  ) async {
    await pumpPage(tester);
    await hover(tester, 'Newton');

    await tester.pump(const Duration(milliseconds: 100));
    expect(_card, findsNothing, reason: 'sweeping across a page opens none');
    expect(links.previewReads, isEmpty);

    await settleHover(tester);
    expect(_card, findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('link-preview-title'))).data,
      'Newton',
      reason: "the card's title is the note's name",
    );
    expect(
      find.textContaining('Gravity, and the laws of motion.'),
      findsOneWidget,
      reason: 'the note, rendered',
    );
    expect(links.previewReads, ['Newton.md']);
  });

  _cardTest('moving off the link closes it once the pointer cannot reach '
      'the card', (tester) async {
    await pumpPage(tester);
    final gesture = await hover(tester, 'Newton');
    await settleHover(tester);
    expect(_card, findsOneWidget);

    await gesture.moveTo(const Offset(700, 580));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_card, findsOneWidget, reason: 'the grace to cross onto it');

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(_card, findsNothing);
  });

  _cardTest('the card stays while the pointer is on it, and goes when it '
      'leaves', (tester) async {
    await pumpPage(tester);
    final gesture = await hover(tester, 'Newton');
    await settleHover(tester);
    expect(_card, findsOneWidget);

    await gesture.moveTo(tester.getCenter(_card));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_card, findsOneWidget, reason: 'it scrolls, so it stays');

    await gesture.moveTo(const Offset(700, 580));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(_card, findsNothing);
  });

  _cardTest("Esc closes it, and the key is still the note's", (tester) async {
    await pumpPage(tester);
    await hover(tester, 'Newton');
    await settleHover(tester);
    expect(_card, findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(_card, findsNothing);
  });

  _cardTest('scrolling the note closes it', (tester) async {
    await pumpPage(
      tester,
      text: '$_page\n\n${List.generate(100, (i) => 'Line $i\n').join('\n')}',
    );
    await hover(tester, 'Newton');
    await settleHover(tester);
    expect(_card, findsOneWidget);

    scroll.jumpTo(120);
    await tester.pump();

    expect(_card, findsNothing);
  });

  _cardTest('a press anywhere closes it without navigating', (tester) async {
    await pumpPage(tester);
    final gesture = await hover(tester, 'Newton');
    await settleHover(tester);
    expect(_card, findsOneWidget);

    await gesture.moveTo(const Offset(700, 580));
    await gesture.down(const Offset(700, 580));
    await gesture.up();
    await tester.pump();

    expect(_card, findsNothing);
  });

  _cardTest('a dead link shows no card, and costs no repeated reads', (
    tester,
  ) async {
    await pumpPage(tester);
    final gesture = await hover(tester, 'Gone');
    await settleHover(tester);
    expect(_card, findsNothing);

    await gesture.moveBy(const Offset(3, 0));
    await settleHover(tester);
    expect(_card, findsNothing);
    expect(links.previewReads, isEmpty, reason: 'nothing to read for it');
  });

  _cardTest('the same link hovered again reads nothing twice', (tester) async {
    await pumpPage(tester);
    final gesture = await hover(tester, 'Newton');
    await settleHover(tester);
    await gesture.moveBy(const Offset(2, 0));
    await tester.pump(const Duration(milliseconds: 100));

    expect(links.previewReads, ['Newton.md']);
    expect(_card, findsOneWidget);
  });

  _cardTest('a note open with unsaved edits shows its buffer, not the disk', (
    tester,
  ) async {
    unsavedText = (path) =>
        path == 'Newton.md' ? '# Newton\n\nEdited, not saved.' : null;
    await pumpPage(tester);
    await hover(tester, 'Newton');
    await settleHover(tester);

    expect(_card, findsOneWidget);
    expect(find.textContaining('Edited, not saved.'), findsOneWidget);
    expect(
      find.textContaining('Gravity, and the laws of motion.'),
      findsNothing,
      reason: 'the disk is not what the note says now',
    );
    expect(links.previewReads, isEmpty, reason: 'the disk was never read');
  });

  _cardTest('the setting off, no card opens', (tester) async {
    enabled = false;
    await pumpPage(tester);
    await hover(tester, 'Newton');
    await settleHover(tester);

    expect(_card, findsNothing);
    expect(links.previewReads, isEmpty);
  });

  _cardTest("a heading link's card is scrolled to the heading", (tester) async {
    await pumpPage(tester);
    await hover(tester, 'x');
    await settleHover(tester);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(_card, findsOneWidget);
    expect(find.text('#Light'), findsOneWidget, reason: 'the place it names');
    final scrollable = find.descendant(
      of: _card,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable.first).position;
    expect(position.pixels, greaterThan(100), reason: 'down to the heading');
    expect(
      find.textContaining('Light travels at a finite speed.'),
      findsOneWidget,
    );
  });

  _cardTest('a link to a note without the heading shows its top', (
    tester,
  ) async {
    links.previews['Optics.md'] = '# Optics\n\nShort note.\n';
    await pumpPage(tester);
    await hover(tester, 'x');
    await settleHover(tester);

    final scrollable = find.descendant(
      of: _card,
      matching: find.byType(Scrollable),
    );
    expect(tester.state<ScrollableState>(scrollable.first).position.pixels, 0);
    expect(find.textContaining('Short note.'), findsOneWidget);
  });

  _cardTest('the card has a fixed size and stays inside the window', (
    tester,
  ) async {
    await pumpPage(tester, size: const Size(500, 400));
    await hover(tester, 'Newton');
    await settleHover(tester);

    final rect = tester.getRect(_card);
    expect(rect.size, LinkPreviewCard.size.clampedTo(const Size(484, 384)));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(500));
    expect(rect.bottom, lessThanOrEqualTo(400));
  });

  _cardTest("a short note's card is the same size as a long one's", (
    tester,
  ) async {
    links.previews['Newton.md'] = 'One line.';
    await pumpPage(tester);
    await hover(tester, 'Newton');
    await settleHover(tester);

    expect(tester.getSize(_card), LinkPreviewCard.size);
  });

  _cardTest("a long note's card is that size too, and scrolls", (tester) async {
    await pumpPage(tester);
    await hover(tester, 'x');
    await settleHover(tester);

    expect(tester.getSize(_card), LinkPreviewCard.size);
  });
}

/// A read view over [text] under the preview host, as the note view has it.
final class _Page extends StatefulWidget {
  const new({
    required this.controller,
    required this.scroll,
    required this.text,
  });

  final LinkPreviewController controller;
  final ScrollController scroll;
  final String text;

  @override
  State<_Page> createState() => _PageState();
}

final class _PageState extends State<_Page> {
  final ReadParser _parser = ReadParser();
  late final MathCache _math = MathCache(
    renderer: (tex, {required displayMode}) => throw UnimplementedError(),
  );
  late SourceBuffer _buffer = SourceBuffer.fromText(widget.text);

  @override
  void didUpdateWidget(_Page oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _buffer = SourceBuffer.fromText(widget.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LinkPreviewHost(
      controller: widget.controller,
      mathCache: _math,
      closeOn: widget.scroll,
      child: MarkdownReadView(
        buffer: _buffer,
        parser: _parser,
        mathCache: _math,
        controller: widget.scroll,
        linkPreview: (
          onEnter: widget.controller.enter,
          onExit: widget.controller.leave,
          onLongPress: null,
        ),
      ),
    );
  }
}

extension on Size {
  /// This size, each side no larger than [limit]'s.
  Size clampedTo(Size limit) => Size(
    width < limit.width ? width : limit.width,
    height < limit.height ? height : limit.height,
  );
}
