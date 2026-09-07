// EditorHighlightSync: re_editor CodeLines buffer -> incremental
// tokenizer -> per-line styled spans (the spanBuilder implementation).
import 'package:copist/src/editor/highlight_sync.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

const TextStyle _base = TextStyle(
  fontFamily: 'monospace',
  fontSize: 13,
);

Color? _colorOf(TextSpan span, String want) => _styleOf(span, want)?.color;

TextStyle? _styleOf(TextSpan span, String want) {
  final walk = <TextSpan>[span];
  while (walk.isNotEmpty) {
    final s = walk.removeLast();
    if (s.text == want) return s.style;
    walk.addAll(s.children?.whereType<TextSpan>() ?? const []);
  }
  return null;
}

TextSpan _spanFor(EditorHighlightSync sync, int index, String text,
        {bool dark = false, Color accent = const Color(0xFF445E91)}) =>
    sync.spanFor(
      index: index,
      text: text,
      base: _base,
      dark: dark,
      accent: accent,
    );

void main() {
  test('the first buffer load gets styled tokens per line', () {
    final sync = EditorHighlightSync();
    final controller = CodeLineEditingController()
      ..text = '# Hello\n\nplain `code` and \$x^2\$ math';
    sync.onBufferChanged(controller.codeLines);
    final heading = _spanFor(sync, 0, '# Hello');
    // The `#` marker is dim (covered by a token style).
    expect(_colorOf(heading, '#'), isNotNull);
    final math = _spanFor(sync, 2, r'plain `code` and $x^2$ math');
    // The math span is purple (light palette):
    expect(_colorOf(math, r'$x^2$'), const Color(0xFFAD1457));
    // Inline code has its own color:
    expect(_colorOf(math, '`code`'), const Color(0xFF0E7C7B));
    controller.dispose();
  });

  test('dark palette for the math span', () {
    final sync = EditorHighlightSync();
    final controller = CodeLineEditingController()..text = r'$x$';
    sync.onBufferChanged(controller.codeLines);
    final span = _spanFor(sync, 0, r'$x$', dark: true);
    expect(_colorOf(span, r'$x$'), const Color(0xFFC678DD));
    controller.dispose();
  });

  test('spanFor returns the same instance until the line changes', () {
    final sync = EditorHighlightSync();
    final controller = CodeLineEditingController()..text = 'one\ntwo';
    sync.onBufferChanged(controller.codeLines);
    final first = _spanFor(sync, 1, 'two');
    final second = _spanFor(sync, 1, 'two');
    expect(identical(first, second), isTrue,
        reason: 'the paragraph cache keys on the span instance');
    // An unchanged line keeps its span across an edit elsewhere…
    final unchanged = _spanFor(sync, 0, 'one');
    controller.text = 'one\ntwo!\nthree';
    sync.onBufferChanged(controller.codeLines);
    final kept = _spanFor(sync, 0, 'one');
    expect(identical(unchanged, kept), isTrue);
    // …while the edited line's span is replaced…
    final after = _spanFor(sync, 1, 'two!');
    expect(identical(first, after), isFalse);
    // …and a selection-only change leaves everything alone.
    final before = _spanFor(sync, 2, 'three');
    controller.selection = const CodeLineSelection.collapsed(
      index: 2,
      offset: 1,
    );
    final keep = _spanFor(sync, 2, 'three');
    expect(identical(before, keep), isTrue);
    controller.dispose();
  });

  test('an edit only re-tokenizes the changed region (fence proof)', () {
    final sync = EditorHighlightSync();
    final controller = CodeLineEditingController()
      ..text = '```\ninside\n```\nplain';
    sync.onBufferChanged(controller.codeLines);
    // Insert a line inside the fence via a full-text set (the sync must
    // still anchor on the true diff).
    controller.text = '```\nnew inside\ninside\n```\nplain';
    sync.onBufferChanged(controller.codeLines);
    final inside = _spanFor(sync, 1, 'new inside');
    // Fence content lines are dimmed as code (a single whole-line child):
    expect(inside.children, isNotNull);
    final child = inside.children!.first as TextSpan;
    expect(child.text, 'new inside');
    expect(child.style?.color, const Color(0xFF5C6B73));
    controller.dispose();
  });

  test('wikilinks use the theme accent, underlined, in both palettes '
      '(T-UI-09)', () {
    const accentLight = Color(0xFF1A73E8);
    const accentDark = Color(0xFF8AB4F8);
    for (final (dark, accent) in <(bool, Color)>[
      (false, accentLight),
      (true, accentDark),
    ]) {
      final sync = EditorHighlightSync();
      final controller = CodeLineEditingController()
        ..text = '[[La stella Pyrale|Pyrale]]';
      sync.onBufferChanged(controller.codeLines);
      // The token covers the whole [[...]] (brackets included).
      final span = _spanFor(sync, 0, '[[La stella Pyrale|Pyrale]]',
          dark: dark, accent: accent);
      final token = _styleOf(span, '[[La stella Pyrale|Pyrale]]');
      expect(token?.color, accent);
      expect(token?.decoration, TextDecoration.underline);
      controller.dispose();
    }
  });

  test('frontmatter lines are styled as the block', () {
    final sync = EditorHighlightSync();
    final controller = CodeLineEditingController()
      ..text = '---\ntitle: Note\n---\nbody';
    sync.onBufferChanged(controller.codeLines);
    final span = _spanFor(sync, 1, 'title: Note');
    expect(_colorOf(span, 'title: Note'), const Color(0xFF7A7A7A));
    controller.dispose();
  });
}
