// The source surface against the three embedders it ships on (#245, phase 3).
//
// Each test runs once per profile of `FakeEmbedder` — Linux, Windows and
// Android as their own sources say they behave — and every one of them holds
// the same invariant the device runs kept breaking: **the note and the
// platform's copy of it say the same thing**, after every step. A surface that
// is right about its own text and wrong about the platform's is a surface whose
// next keystroke lands in the wrong place.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';

import '../fakes/fake_embedder.dart';

/// Monospace at 14 px on a 21 px row: with the test font every glyph is 14 px
/// wide, so a column is a known x.
const MarkdownTheme _theme = MarkdownTheme(
  body: TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
  heading1: TextStyle(fontSize: 25),
  heading2: TextStyle(fontSize: 21),
  heading3: TextStyle(fontSize: 18),
  heading4: TextStyle(fontSize: 16),
  heading5: TextStyle(fontSize: 14),
  heading6: TextStyle(fontSize: 13),
  code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
  quote: TextStyle(fontSize: 14),
  tableCell: TextStyle(fontSize: 14),
  tableHeader: TextStyle(fontSize: 14),
  link: TextStyle(fontSize: 14),
  wikilink: TextStyle(fontSize: 14),
  tag: TextStyle(fontSize: 14),
  marker: TextStyle(fontSize: 14),
  codeHighlight: <String, TextStyle>{},
  rule: Color(0xFF888888),
  codeBackground: Color(0xFFEEEEEE),
  quoteBar: Color(0xFFCCCCCC),
  tableBorder: Color(0xFFCCCCCC),
  markerDim: Color(0xFF999999),
  blockSpacing: 10,
  listIndentPerLevel: 22,
  quoteIndentPerLevel: 12,
  codePadding: 8,
  quoteBarWidth: 3,
  ruleThickness: 1,
  tableCellPadding: EdgeInsets.all(4),
  lineHeight: 21,
);

/// The field's left inset and the page's top margin, as the view lays them out
/// with no line numbers and no note column.
const double _left = 5;
const double _top = 8;

/// A surface over a note with a profile's platform behind it.
final class _Rig {
  new(this.tester, this.profile, String text)
    : buffer = SourceBuffer.fromText(text),
      platform = FakeEmbedder(tester, profile);

  final WidgetTester tester;
  final EmbedderProfile profile;
  final SourceBuffer buffer;
  final FakeEmbedder platform;
  final List<String> saved = <String>[];

  Future<void> pump() async {
    platform.install();
    tester.view.physicalSize = const Size(600, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(
            buffer: buffer,
            theme: _theme,
            showLineNumbers: false,
            onChanged: () => saved.add(buffer.text),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Taps between column [column] and the one before it on line [line].
  Future<void> tapAt(int line, int column) async {
    await tester.tapAt(
      Offset(_left + column * 14.0 + 1, _top + line * 21.0 + 10),
    );
    await tester.pump();
  }

  /// The two copies agree, and they say [expected].
  void agree(String expected, {String? reason}) {
    expect(buffer.text, expected, reason: reason);
    expect(
      platform.text,
      buffer.text,
      reason: 'the platform holds what the note holds',
    );
  }
}

void main() {
  for (final profile in EmbedderProfile.values) {
    group(profile.name, () {
      testWidgets('a tap attaches the keyboard for the view, and raises it', (
        tester,
      ) async {
        final rig = _Rig(tester, profile, 'ciao\n');
        await rig.pump();
        await rig.tapAt(0, 2);
        expect(rig.platform.errors, isEmpty);
        expect(rig.platform.attached, isTrue);
        expect(rig.platform.shown, isTrue);
        expect(rig.platform.configuration?['viewId'], tester.view.viewId);
        rig.agree('ciao\n');
      });

      testWidgets('typing lands where the tap put the caret', (tester) async {
        // The second tap is more than a double-tap slop away from the first:
        // two taps that close together, that quickly, are a double tap.
        final rig = _Rig(tester, profile, 'uno due\n\n\n\n\n\ntre\n');
        await rig.pump();
        await rig.tapAt(0, 3);
        await rig.platform.type('X');
        rig.agree('unoX due\n\n\n\n\n\ntre\n');
        await rig.tapAt(6, 1);
        await rig.platform.type('Y');
        rig.agree(
          'unoX due\n\n\n\n\n\ntYre\n',
          reason: 'the second tap moved it again',
        );
      });

      testWidgets('Backspace deletes before the caret', (tester) async {
        final rig = _Rig(tester, profile, 'ciao mondo\n');
        await rig.pump();
        await rig.tapAt(0, 4);
        await rig.platform.backspace();
        await tester.pump();
        rig.agree('cia mondo\n');
        await rig.platform.type('!');
        rig.agree('cia! mondo\n', reason: 'and typing carries on from there');
      });

      testWidgets('Enter is one line', (tester) async {
        final rig = _Rig(tester, profile, 'unofine\n');
        await rig.pump();
        await rig.tapAt(0, 3);
        await rig.platform.enter();
        await tester.pump();
        rig.agree('uno\nfine\n');
        await rig.platform.type('Z');
        rig.agree('uno\nZfine\n', reason: 'the caret is on the new line');
      });

      testWidgets('a deletion survives the keystroke that follows it', (
        tester,
      ) async {
        // No frame between the two: the surface's own edit has to reach the
        // platform before the platform's next delta is built on its copy, or
        // that delta carries the deleted character back.
        final rig = _Rig(tester, profile, 'ciao mondo\n');
        await rig.pump();
        await rig.tapAt(0, 4);
        await rig.platform.backspace();
        await rig.platform.type('!');
        rig.agree('cia! mondo\n');
      });

      testWidgets('a keystroke right after a tap lands at the tap', (
        tester,
      ) async {
        final rig = _Rig(tester, profile, 'uno due\n\n\n\n\n\ntre\n');
        await rig.pump();
        await rig.tapAt(0, 3);
        await rig.platform.type('X');
        // The tap, and then a keystroke before any frame is drawn.
        await tester.tapAt(
          const Offset(_left + 14.0 + 1, _top + 6 * 21.0 + 10),
        );
        await rig.platform.type('Y');
        rig.agree('unoX due\n\n\n\n\n\ntYre\n');
      });

      testWidgets('a CRLF note stays in step through an Enter', (tester) async {
        // The note keeps its own line endings, so the platform's `\n` is
        // written as `\r\n` — one code unit more than the platform thinks it
        // typed. Unless it is told, every offset after it is one off.
        final rig = _Rig(tester, profile, 'unofine\r\naltro\r\n');
        await rig.pump();
        await rig.tapAt(0, 3);
        await rig.platform.enter();
        await tester.pump();
        rig.agree('uno\r\nfine\r\naltro\r\n');
        await rig.platform.type('Z');
        rig.agree('uno\r\nZfine\r\naltro\r\n');
      });

      testWidgets('a connection the platform closed is opened again', (
        tester,
      ) async {
        final rig = _Rig(tester, profile, 'ciao\n\n\n\n\n\nfine\n');
        await rig.pump();
        await rig.tapAt(0, 2);
        await rig.platform.closeConnection();
        await tester.pump();
        await rig.tapAt(6, 4);
        expect(rig.platform.attached, isTrue, reason: 'the tap reconnects');
        await rig.platform.type('!');
        rig.agree('ciao\n\n\n\n\n\nfine!\n');
      });

      testWidgets('every tap asks for the keyboard', (tester) async {
        // A keyboard the user put away (Android's back button) comes back on
        // the next tap: attaching once is not the same as asking.
        final rig = _Rig(tester, profile, 'uno due\n\n\n\n\n\ntre\n');
        await rig.pump();
        await rig.tapAt(0, 2);
        final before = rig.platform.shows;
        await rig.tapAt(6, 1);
        expect(rig.platform.shows, greaterThan(before));
      });

      testWidgets('a composition is left to the IME, and underlined', (
        tester,
      ) async {
        // An echo in the middle of a word ends the composition: while the
        // platform is the one editing, nothing is sent back.
        final rig = _Rig(tester, profile, 'ciao \n');
        await rig.pump();
        await rig.tapAt(0, 5);
        final echoes = rig.platform.editingStates;
        await rig.platform.compose('mondo');
        await tester.pump();
        rig.agree('ciao mondo\n');
        expect(rig.platform.editingStates, echoes, reason: 'no echo mid-word');
        expect(rig.platform.composing, const TextRange(start: 5, end: 10));
        final underlined = tester
            .renderObjectList<RenderParagraph>(find.byType(RichText))
            .expand((paragraph) {
              final spans = <TextSpan>[];
              paragraph.text.visitChildren((span) {
                if (span is TextSpan &&
                    span.style?.decoration == TextDecoration.underline) {
                  spans.add(span);
                }
                return true;
              });
              return spans;
            })
            .map((span) => span.text)
            .join();
        expect(underlined, 'mondo', reason: 'the word being composed');
        await rig.platform.commit();
        await rig.platform.type('!');
        rig.agree('ciao mondo!\n');
      });

      testWidgets('Enter carries a list on, and an empty item ends it', (
        tester,
      ) async {
        // The line break arrives from the platform like any other; what the
        // note gets is the list's next marker as well, and the platform is
        // told, so the next keystroke lands after it.
        final rig = _Rig(tester, profile, '- latte\n');
        await rig.pump();
        await rig.tapAt(0, 7);
        await rig.platform.enter();
        await tester.pump();
        rig.agree('- latte\n- \n');
        await rig.platform.type('pane');
        rig.agree('- latte\n- pane\n');
        await rig.platform.enter();
        await tester.pump();
        await rig.platform.enter();
        await tester.pump();
        rig.agree(
          '- latte\n- pane\n\n',
          reason: 'Enter on an empty item takes the marker away',
        );
      });

      testWidgets('an ordered list counts on, a fence does not continue', (
        tester,
      ) async {
        // The two taps are far enough apart not to be a double tap.
        final rig = _Rig(
          tester,
          profile,
          '1. uno\n\n\n\n\n```\n- dentro\n```\n',
        );
        await rig.pump();
        await rig.tapAt(0, 6);
        await rig.platform.enter();
        await tester.pump();
        rig.agree('1. uno\n2. \n\n\n\n\n```\n- dentro\n```\n');
        await rig.tapAt(7, 8);
        await rig.platform.enter();
        await tester.pump();
        rig.agree(
          '1. uno\n2. \n\n\n\n\n```\n- dentro\n\n```\n',
          reason: 'a dash inside a fence starts nothing',
        );
      });

      testWidgets('Tab indents and keeps the keyboard', (tester) async {
        // The app's default Tab moves the focus to the next widget, which
        // took the keyboard away from the note.
        final rig = _Rig(tester, profile, '- uno\n\n\n\n\n\nprosa\n');
        await rig.pump();
        await rig.tapAt(0, 5);
        await rig.platform.press(LogicalKeyboardKey.tab);
        await tester.pump();
        rig.agree(
          '  - uno\n\n\n\n\n\nprosa\n',
          reason: 'a list item moves in whole',
        );
        expect(rig.platform.attached, isTrue, reason: 'the focus stayed');
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await rig.platform.press(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pump();
        rig.agree(
          '- uno\n\n\n\n\n\nprosa\n',
          reason: 'and Shift+Tab takes it back',
        );
        await rig.tapAt(6, 2);
        await rig.platform.press(LogicalKeyboardKey.tab);
        await tester.pump();
        rig.agree(
          '- uno\n\n\n\n\n\npr  osa\n',
          reason: 'prose gets spaces at the caret',
        );
      });

      testWidgets('an edit reaches the shell', (tester) async {
        final rig = _Rig(tester, profile, 'a\n');
        await rig.pump();
        await rig.tapAt(0, 1);
        await rig.platform.type('b');
        expect(rig.saved.last, 'ab\n');
      });
    });
  }

  testWidgets('Windows refuses a client without a view, and says so', (
    tester,
  ) async {
    // The fake itself, held to the embedder's own rule: this is what made the
    // surface untypeable on Windows before it passed the view.
    final platform = FakeEmbedder(tester, EmbedderProfile.windows)..install();
    await expectLater(
      SystemChannels.textInput.invokeMethod<void>(
        'TextInput.setClient',
        <dynamic>[
          1,
          <String, dynamic>{'inputType': <String, dynamic>{}},
        ],
      ),
      throwsA(isA<PlatformException>()),
    );
    expect(platform.attached, isFalse);
  });
}
