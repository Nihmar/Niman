// The note's theme is asked for in `build` (`NoteView`), and what the
// surfaces measured stands on the theme they were handed (#722): one
// application theme and text size are one theme, handed back, not a copy of
// itself per build.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';

void main() {
  testWidgets('the same application theme and size are the same theme', (
    tester,
  ) async {
    late MarkdownTheme first;
    late MarkdownTheme second;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            first = markdownThemeOf(context);
            second = markdownThemeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(identical(first, second), isTrue);
  });

  testWidgets('its own text size is a theme of its own', (tester) async {
    late MarkdownTheme plain;
    late MarkdownTheme scaled;
    late MarkdownTheme plainAgain;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            plain = markdownThemeOf(context);
            scaled = markdownThemeOf(
              context,
              scaler: const TextScaler.linear(1.5),
            );
            plainAgain = markdownThemeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(identical(plain, scaled), isFalse);
    expect(scaled.blockSpacing, greaterThan(plain.blockSpacing));
    expect(
      identical(plainAgain, plain),
      isTrue,
      reason: 'the size asked between them built over the other',
    );
  });

  testWidgets('another application theme is another theme', (tester) async {
    late MarkdownTheme light;
    late MarkdownTheme dark;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Builder(
          builder: (context) {
            light = markdownThemeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) {
            dark = markdownThemeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    // `MaterialApp` animates between themes: the last frame's is the dark
    // one, and the builder above reads it on each of them.
    await tester.pumpAndSettle();
    expect(identical(light, dark), isFalse);
  });
}
